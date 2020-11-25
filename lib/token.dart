import 'dart:collection';

import 'escape.dart';
import 'models.dart';

class Entry {
  bool closed;
  Node node;
  Entry(this.node, {this.closed = false});
}

class Token {
  String input;
  String filename;
  String attrName;
  String attrValue;
  String attrQuot;
  String escape;
  String textValue;
  String tagName;
  ListQueue<Entry> stack = ListQueue();
  Entry entry;
  int line = 1;
  int col = 1;
  bool texting = false;
  Token(this.input, this.filename);

  void pos(String c) {
    if (c == '\n') {
      line += 1;
      col = 1;
    } else {
      col += 1;
    }
  }

  String escapeOf(String c) {
    if (c == '&') {
      if (escape == null) {
        escape = '&';
        return null;
      }
      var t = escape;
      escape = '&';
      return t;
    } else if (escape != null) {
      escape += c;
      if (c != ';') return null;
      c = fromEscape(escape);
      if (c == null) {
        throw new ParserException('未知的转移字符', this);
      }
      escape = null;
      return c;
    } else {
      return c;
    }
  }

  double doubleOfAttrValue() {
    if (attrValue == null) return null;
    double d = double.tryParse(attrValue);
    if (d == null) throw ParserException("无法将字符串'$attrValue'转化为double", this);
    return d;
  }

  void createAttr() {
    entry.node.setAttr(this);
    attrName = null;
    attrValue = null;
  }

  void createElement() {
    var next = newNode(tagName);
    if (next == null) {
      throw new ParserException('未知的标签$tagName', this);
    }
    if (entry == null) {
      if (next is Templates) {
        entry = Entry(next);
      } else if (next is Template) {
        entry = Entry(Templates(), closed: true);
        (entry.node as Templates).child.add(next);
        stack.addLast(entry);
        entry = Entry(next);
      } else {
        Templates fragments = Templates();
        Template fragment = Template();
        fragments.child.add(fragment);
        fragment.child.add(next);
        stack.addLast(Entry(fragments, closed: true));
        stack.addLast(entry = Entry(fragment, closed: true));
        entry = Entry(next);
      }
    } else if (next is Templates) {
      throw ParserException('<fragments> 必须是跟节点', this);
    } else if (entry.node is WithChild) {
      if (next.tagName == 'span') {
        if (entry.node.tagName != 'rich') {
          throw ParserException(
              '无法将<span>设置为<${entry.node.tagName}>的子节点', this);
        }
      } else if (entry.node.tagName == 'rich') {
        throw ParserException('无法将节点<${next.tagName}>设置为<rich>的子节点', this);
      }
      (entry.node as WithChild).child.add(next);
      stack.addLast(entry);
      entry = Entry(next);
    } else {
      throw ParserException('<${entry.node.tagName}>无法添加子标签', this);
    }
    texting = next is WithText;
    if (texting) {
      textValue = '';
    }
  }

  void closeElement() {
    if (entry.closed) {
      throw ParserException('未知闭合标签 </${tagName}>', this);
    }
    var node = entry.node;
    if (node is WithText) {
      node.text = trimText(textValue);
      textValue = null;
    }
    entry.closed = true;
    if (stack.isNotEmpty) {
      entry = stack.removeLast();
    }
    texting = false;
  }
}

class ParserException implements Exception {
  String msg;
  int line;
  int col;
  String filename;
  ParserException(this.msg, Token token) {
    line = token.line;
    col = token.col;
    filename = token.filename;
  }
  @override
  String toString() => 'ParserException: $msg ($filename:${line}:${col})';
}
