import 'dart:collection';
import 'escape.dart';
import 'models.dart';

Fragments parse(String content, {String filename = ""}) {
  Context context = Context(content, filename);
  for (int i = 0; i < content.length; i++) {
    _State s = context.process(content[i]);
    if (s == null) throw ParserException('错误的返回状态', context);
    context.state = s;
  }
  return context.end();
}

enum _State {
  none, // 关闭状态或者其他
  none_lt, // <view> <
  none_closing, // 当前状态为 </div>
  open_tag_name,
  opening, // 标签半开放状态
  opening_closing, // <div /
  attr_name,
  attr_value,
  text,
  text_lt, // <text> <
}

class Entry {
  bool closed;
  Node node;
  View view;
  Image image;
  Text text;
  Rich rich;
  Span span;
  Fragment fragment;
  Fragments fragments;
  bool innerText = false;
  Entry(
      {this.view,
      this.image,
      this.text,
      this.rich,
      this.span,
      this.fragment,
      this.fragments,
      this.closed = false}) {
    if (view != null) {
      node = view;
    } else if (image != null) {
      node = image;
    } else if (text != null) {
      node = text;
    } else if (rich != null) {
      node = rich;
    } else if (span != null) {
      node = span;
    } else if (fragment != null) {
      node = fragment;
    } else if (fragments != null) {
      node = fragments;
    }
    innerText = node is WithText;
  }
}

class Context {
  String input;
  String filename;
  _State state = _State.none;
  String attrName;
  String attrValue;
  String attrQuot;
  String escape;
  String textValue;
  String tagName;
  String textLt;
  ListQueue<Entry> stack = ListQueue();
  Entry entry;
  int line = 1;
  int col = 1;
  Context(this.input, this.filename);

  _State process(String c) {
    if (c == '\n') {
      line += 1;
      col = 1;
    } else {
      col += 1;
    }
    switch (state) {
      case _State.none:
        return _atNone(c);
      case _State.none_lt:
        return _atNoneLt(c);
      case _State.none_closing:
        return _atNoneClosing(c);
      case _State.open_tag_name:
        return _atOpenTagName(c);
      case _State.opening:
        return _atOpening(c);
      case _State.opening_closing:
        return _atOpeningClosing(c);
      case _State.attr_name:
        return _atAttrName(c);
      case _State.attr_value:
        return _atAttrValue(c);
      case _State.text:
        return _atText(c);
      case _State.text_lt:
        return _atTextLt(c);
      default:
        throw new ParserException('未知状态$state', this);
    }
  }

  Fragments end() {
    if (escape != null) {
      throw new ParserException('escape尚未结束', this);
    }
    if (state != _State.none) {
      throw new ParserException('错误的状态$state', this);
    }
    if (entry == null) return Fragments();
    if (!entry.closed)
      throw new ParserException('为闭合的标签<${entry.node.tagName}>', this);
    while (stack.isNotEmpty) {
      entry = stack.removeLast();
      if (!entry.closed)
        throw new ParserException('为闭合的标签<${entry.node.tagName}>', this);
    }
    return entry.fragments;
  }

  String _escape(String c) {
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
      c = escapeOf(escape);
      if (c == null) {
        throw new ParserException('未知的转移字符', this);
      }
      escape = null;
      return c;
    } else {
      return c;
    }
  }

  _State _atNone(String c) {
    switch (c) {
      case '<':
        return _State.none_lt;
      case ' ':
      case '\t':
      case '\n':
        return _State.none;
      default:
        throw new ParserException('只有<text> 标签内部可以插入文本"$c"', this);
    }
  }

  _State _atOpenTagName(String c) {
    switch (c) {
      case '\t':
      case '\n':
      case ' ':
        _createElement();
        return _State.opening;
      case '>':
        _createElement();
        return entry.innerText ? _State.text : _State.none;
      case '/':
        _createElement();
        return _State.opening_closing;
      case '&':
      case '<':
        throw new ParserException('错误的标签字符$c', this);
      default:
        tagName += c;
        return state;
    }
  }

  _State _atOpening(String c) {
    switch (c) {
      case '/':
        return _State.opening_closing;
      case ' ':
      case '\t':
      case '\n':
        return _State.opening;
      case '>':
        return entry.innerText ? _State.text : _State.none;
      default:
        attrName = c;
        return _State.attr_name;
    }
  }

  _State _atOpeningClosing(String c) {
    // <image />
    if (c != '>') throw new ParserException('字符必须是 >', this);
    _closeElement();
    return _State.none;
  }

  _State _atAttrName(String c) {
    switch (c) {
      case '\t':
      case '\n':
      case ' ':
        _attr();
        return _State.opening;
      case '>':
        _attr();
        return _State.none;
      case '=':
        attrValue = '';
        return _State.attr_value;
      default:
        attrName += c;
        return _State.attr_name;
    }
  }

  _State _atAttrValue(String c) {
    if (attrQuot != null) {
      if (attrQuot == c) {
        attrQuot = null;
        _attr();
        return _State.opening;
      }
    } else if (attrValue != '') {
      if (c == ' ' || c == '\t' || c == '\n') {
        attrQuot = null;
        _attr();
        return _State.opening;
      } else if (c == '>') {
        attrQuot = null;
        _attr();
        return entry.innerText ? _State.text : _State.none;
      }
    }
    if (attrValue == '' && (c == '"' || c == "'")) {
      attrQuot = c;
    } else {
      c = _escape(c);
      if (c != null) attrValue += c;
    }
    return _State.attr_value;
  }

  _State _atText(String c) {
    if (c == '<') {
      textLt = c;
      return _State.text_lt;
    }
    c = _escape(c);
    if (c != null) textValue += c;
    return _State.text;
  }

  _State _atTextLt(String c) {
    textLt += c;
    String close = '</${entry.node.tagName}>';
    if (textLt == close) {
      textLt = null;
      _closeElement();
      return _State.none;
    } else if (close.startsWith(textLt)) {
      return _State.text_lt;
    }
    textValue += textLt;
    return _State.text;
  }

  _State _atNoneLt(String c) {
    if (c == '/') {
      tagName = '';
      return _State.none_closing;
    } else {
      tagName = c;
      return _State.open_tag_name;
    }
  }

  _State _atNoneClosing(String c) {
    if (c != '>') {
      tagName += c;
      return _State.none_closing;
    }
    if (entry.node.tagName != tagName) {
      throw new ParserException('<view> 和 </$tagName> 不匹配', this);
    }
    _closeElement();
    return _State.none;
  }

  void _attr() {
    entry.node.setAttr(attrName, attrValue, this);
    attrName = null;
    attrValue = null;
  }

  void _createElement() {
    switch (tagName) {
      case 'image':
        return _createEntry(Entry(image: Image()));
      case 'view':
        return _createEntry(Entry(view: View()));
      case 'text':
        return _createEntry(Entry(text: Text()));
      case 'fragment':
        return _createEntry(Entry(fragment: Fragment()));
      case 'fragments':
        return _createEntry(Entry(fragments: Fragments()));
      case 'span':
        return _createEntry(Entry(span: Span()));
      case 'rich':
        return _createEntry(Entry(rich: Rich()));
      default:
        throw new ParserException('未知的标签' + tagName, this);
    }
  }

  void _createEntry(Entry next) {
    if (entry == null) {
      if (next.fragments != null) {
        entry = next;
      } else if (next.fragment != null) {
        entry = Entry(fragments: Fragments(), closed: true);
        entry.fragments.child.add(next.fragment);
        stack.addLast(entry);
        entry = next;
      } else {
        Fragments fragments = Fragments();
        Fragment fragment = Fragment();
        fragments.child.add(fragment);
        fragment.child.add(next.node);
        stack.addLast(Entry(fragments: fragments, closed: true));
        stack.addLast(entry = Entry(fragment: fragment, closed: true));
        entry = next;
      }
    } else if (next.fragments != null) {
      throw ParserException('<fragments> 必须是跟节点', this);
    } else if (entry.node is WithChild) {
      if (next.node.tagName == 'span') {
        if (entry.node.tagName != 'rich') {
          throw ParserException(
              '无法将<span>设置为<${entry.node.tagName}>的子节点', this);
        }
      } else if (entry.node.tagName == 'rich') {
        throw ParserException('无法将节点<${next.node.tagName}>设置为<rich>的子节点', this);
      }
      (entry.node as WithChild).child.add(next.node);
      stack.addLast(entry);
      entry = next;
    } else {
      throw ParserException('<${entry.node.tagName}>无法添加子标签', this);
    }
    if (next.innerText) {
      textValue = '';
    }
  }

  void _closeElement() {
    if (entry.closed) {
      throw ParserException('未知闭合标签 </$tagName>', this);
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
  }
}

class ParserException implements Exception {
  String msg;
  int line;
  int col;
  String filename;
  ParserException(this.msg, Context ctx) {
    line = ctx.line;
    col = ctx.col;
    filename = ctx.filename;
  }
  @override
  String toString() => 'ParserException: $msg ($filename:${line}:${col})';
}

double doubleOf(String value, Context ctx) {
  double d = double.tryParse(value);
  if (d == null) throw ParserException("无法将字符串'$value'转化为double", ctx);
  return d;
}