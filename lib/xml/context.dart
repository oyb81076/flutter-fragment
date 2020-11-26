import 'dart:collection';
import 'chars.dart';
import 'models.dart';

class Entry {
  bool closed;
  Node node;
  Entry(this.node, {this.closed = false});
}

class Context implements Val {
  final String input;
  final String filename;

  final ListQueue<Entry> stack = ListQueue();
  Entry entry;

  bool texting = false;

  // line, col 出错的时候用来标示地址的
  int line = 1;
  int col = 1;

  // token value offset
  int offset = 0;

  // token
  String _tagName;
  String _attrName;
  String _text;
  String _attrValue;

  Context(this.input, this.filename);

  get strVal {
    return _attrValue == null ? null : unescape(_attrValue);
  }

  get doubleVal {
    if (_attrValue == null || _attrValue.isEmpty) return null;
    double val = double.tryParse(_attrValue);
    if (val == null)
      throw ParserException("无法将字符串'$_attrValue'转化为double", this);
    return val;
  }

  get datetimeVal {
    if (_attrValue == null || _attrValue.isEmpty) return null;
    DateTime val = DateTime.tryParse(_attrValue);
    if (val == null) throw ParserException('无法将"$_attrValue"转化为日期格式', this);
    return val;
  }

  get boolVal {
    if (_attrValue == null) return true;
    return _attrValue != 'false';
  }

  void attrName(int index) {
    _attrName = input.substring(offset, index);
    _attrValue = null;
  }

  void attrValue(int index) {
    _attrValue = unescape(input.substring(offset, index));
  }

  void text(int index) {
    _text = unescapeText(input.substring(offset, index));
  }

  void tagName(int index) {
    _tagName = input.substring(offset, index);
  }

  void setAttr() {
    entry.node.setAttr(_attrName, this);
  }

  void createElement() {
    var creator = tags[_tagName];
    if (creator == null) {
      throw new ParserException('未知的标签$_tagName', this);
    }
    var next = creator();
    texting = next is WithText;
    if (entry == null) {
      if (next is Templates) {
        entry = Entry(next);
      } else if (next is Template) {
        var node = Templates()..children.add(next);
        stack.addLast(Entry(node, closed: true));
        entry = Entry(next);
      } else {
        Template fragment = Template()..children.add(next);
        Templates fragments = Templates()..children.add(fragment);
        stack.addLast(Entry(fragments, closed: true));
        stack.addLast(Entry(fragment, closed: true));
        entry = Entry(next);
      }
    } else if (next is Templates) {
      throw ParserException('<fragments> 必须是跟节点', this);
    } else if (entry.node is WithChildren) {
      String parentTagName = entry.node.tagName;
      String childTagName = next.tagName;
      if (!isValidRalation(parentTagName, childTagName)) {
        throw ParserException('节点<$parentTagName>中无法插入<$childTagName>', this);
      }
      (entry.node as WithChildren).children.add(next);
      stack.addLast(entry);
      entry = Entry(next);
    } else {
      throw ParserException('<${entry.node.tagName}>无法添加子标签', this);
    }
  }

  void closeElement() {
    var node = entry.node;
    if (entry.closed) {
      throw ParserException('未知闭合标签 </${node.tagName}>', this);
    }
    if (entry.node.tagName != _tagName) {
      throw new ParserException(
          '<${entry.node.tagName}> 和 </${_tagName}> 不匹配', this);
    }
    if (node is WithText) {
      node.text = _text;
    }
    entry.closed = true;
    if (stack.isNotEmpty) {
      entry = stack.removeLast();
    }
    texting = false;
  }

  void accept(int c) {
    if (c == LINE_FEED) {
      line += 1;
      col = 1;
    } else {
      col += 1;
    }
  }
}

class ParserException implements Exception {
  String msg;
  int line;
  int col;
  String filename;
  ParserException(this.msg, Context context) {
    line = context.line;
    col = context.col;
    filename = context.filename;
  }
  @override
  String toString() => 'ParserException: $msg ($filename:${line}:${col})';
}
