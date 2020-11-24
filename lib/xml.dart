import 'dart:collection';

abstract class Node {
  String get tagName;
  _setAttr(String attrName, String attrValue, Context ctx);
  Map<String, dynamic> _getAttrs();
}

abstract class WithChild implements Node {
  List get child;
}

abstract class Element extends Node {
  String href;

  @override
  _setAttr(String attrName, String attrValue, Context ctx) {
    if (attrName == 'href') {
      href = attrValue;
    } else {
      throw new ParserException('<view> 不存在属性$attrName', ctx);
    }
  }
}

class Fragments implements Node, WithChild {
  final String tagName = 'fragments';
  final List<Fragment> child = [];
  String lastModified;

  @override
  _setAttr(String attrName, String attrValue, Context ctx) {
    if (attrName == 'lastModified') {
      lastModified = attrValue;
    } else {
      throw ParserException('<fragments> 不存在属性$attrName', ctx);
    }
  }

  @override
  Map<String, dynamic> _getAttrs() {
    return Map.from({'lastModified': lastModified});
  }
}

class Fragment implements Node, WithChild {
  final String tagName = 'fragment';
  String id;
  final List<Element> child = [];

  @override
  _setAttr(String attrName, String attrValue, Context ctx) {
    if (attrName == 'id') {
      id = attrValue;
    } else {
      throw new ParserException('<fragment>不存在属性$attrName', ctx);
    }
  }

  @override
  Map<String, dynamic> _getAttrs() {
    return Map.from({'id': id});
  }
}

class View extends Element implements WithChild {
  final String tagName = 'view';
  final List<Element> child = [];
  double width;
  double height;

  @override
  _setAttr(String attrName, String attrValue, Context ctx) {
    switch (attrName) {
      case 'height':
        height = doubleOf(attrValue, ctx);
        break;
      case 'width':
        width = doubleOf(attrValue, ctx);
        break;
      case 'href':
        href = attrValue;
        break;
      default:
        super._setAttr(attrName, attrValue, ctx);
    }
  }

  @override
  Map<String, dynamic> _getAttrs() {
    return Map.from({'width': width, 'height': height, 'href': href});
  }
}

class Image extends Element {
  final String tagName = 'image';
  double width;
  double height;
  String src;

  @override
  void _setAttr(String attrName, String attrValue, Context ctx) {
    switch (attrName) {
      case 'height':
        height = doubleOf(attrValue, ctx);
        break;
      case 'width':
        width = doubleOf(attrValue, ctx);
        break;
      case 'src':
        src = attrValue;
        break;
      case 'href':
        href = attrValue;
        break;
      default:
        throw new ParserException('<image> 不存在属性$attrName', ctx);
    }
  }

  @override
  Map<String, dynamic> _getAttrs() {
    return Map.from(
        {'width': width, 'height': height, 'src': src, 'href': href});
  }
}

class Text extends Element {
  final String tagName = 'text';
  String text;
  @override
  Map<String, dynamic> _getAttrs() {
    return Map.from({'href': href});
  }
}

Fragments parse(String content, {String filename = ""}) {
  Context context = Context(content, filename);
  for (int i = 0; i < content.length; i++) {
    _State s = context.process(content[i]);
    if (s == null) throw ParserException('错误的返回状态', context);
    context.state = s;
  }
  return context.end();
}

String serialize(dynamic root, {bool compcat = false}) {
  String out = '';
  String indent = '';
  ListQueue list = ListQueue.from(root is List ? root.reversed : [root]);
  while (list.isNotEmpty) {
    var node = list.removeLast();
    if (node is String) {
      if (!compcat) indent = indent.substring(2);
      out += '$indent</$node>';
    } else if (node is Node) {
      out += '$indent<${node.tagName}';
      var attrs = node._getAttrs();
      attrs.entries
          .where((element) => element.value != null)
          .forEach((element) {
        out += ' ${element.key}="${escapeAttrValue(element.value)}"';
      });
      if (node is Text) {
        String text = node.text.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
        if (compcat || !text.contains('\n')) {
          out += '>$text</text>';
        } else {
          out += '>\n';
          out += text
              .split('\n')
              .map((e) => e == '\n' ? '\n' : '  $indent$e')
              .join('\n');
          out += '\n';
          out += '$indent</text>';
        }
      } else if (node is Image) {
        out += '/>';
      } else if (node is WithChild) {
        if (node.child.isEmpty) {
          out += '/>';
        } else {
          out += '>';
          list.add(node.tagName);
          list.addAll(node.child.reversed);
          if (!compcat) {
            indent += '  ';
          }
        }
      } else {
        throw new Exception('unsupport node $node');
      }
    }
    if (!compcat && list.isNotEmpty) out += '\n';
  }
  return out;
}

String escapeAttrValue(dynamic value) {
  if (value is String) {
    return value.replaceAll('"', '&quot;');
  } else if (value is double) {
    return srzDouble(value);
  } else if (value is int || value is bool) {
    return value.toString();
  } else {
    throw new Exception('unspupprt value of $value');
  }
}

var _escapes = Map.from({
  "&lt;": "<",
  "&gt;": '>',
  '&amp;': '&',
  '&quot;': '"',
  '&apos;': "'",
  '&eq;': "=",
});
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
  Fragment fragment;
  Fragments fragments;
  Entry(
      {this.view,
      this.image,
      this.text,
      this.fragment,
      this.fragments,
      this.closed = false}) {
    if (view != null)
      node = view;
    else if (image != null)
      node = image;
    else if (text != null)
      node = text;
    else if (fragment != null)
      node = fragment;
    else if (fragments != null) node = fragments;
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
      c = _escapes[escape];
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

  _State _atNoneLt(String c) {
    if (c == '/') {
      tagName = '';
      return _State.none_closing;
    } else {
      tagName = c;
      return _State.open_tag_name;
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
        return entry.text == null ? _State.none : _State.text;
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
        return entry.text == null ? _State.none : _State.text;
      default:
        attrName = c;
        return _State.attr_name;
    }
  }

  _State _atOpeningClosing(String c) {
    if (c != '>') throw new ParserException('字符必须是 >', this);
    _closeElement();
    return entry.text == null ? _State.none : _State.text;
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
        return entry.text != null ? _State.text : _State.none;
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
    switch (textLt) {
      case '</':
      case '</t':
      case '</te':
      case '</tex':
      case '</text':
        return _State.text_lt;
      case '</text>':
        textLt = null;
        _closeElement();
        return _State.none;
      default:
        textValue += textLt;
        return _State.text;
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
    entry.node._setAttr(attrName, attrValue, this);
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
        textValue = '';
        return _createEntry(Entry(text: Text()));
      case 'fragment':
        return _createEntry(Entry(fragment: Fragment()));
      case 'fragments':
        return _createEntry(Entry(fragments: Fragments()));
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
      (entry.node as WithChild).child.add(next.node);
      stack.addLast(entry);
      entry = next;
    } else {
      throw ParserException('<${entry.node.tagName}>无法添加子标签', this);
    }
  }

  void _closeElement() {
    if (entry.closed) {
      throw ParserException('未知闭合标签 </$tagName>', this);
    }
    if (entry.text != null) {
      entry.text.text = trimText(textValue);
      textValue = null;
    }
    entry.closed = true;
    if (stack.isNotEmpty) {
      entry = stack.removeLast();
    }
  }
}

String trimText(String text) {
  if (text == '') return '';
  if (text[0] != '\n') return text;
  int i = 0;
  String indent = '';
  while (i < text.length && text[i] == '\n') i++;
  while (i < text.length && (text[i] == ' ' || text[i] == '\t')) {
    indent += text[i];
    i++;
  }
  if (indent == '') return text;
  if (text == '\n$indent') return '';
  return text
      .substring(1, text.lastIndexOf('\n'))
      .split('\n')
      .map((e) => e.isEmpty
          ? e
          : e.startsWith(indent)
              ? e.substring(indent.length)
              : throw Exception('缩进不对齐"$e", "$indent"'))
      .join('\n');
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

String srzDouble(double d) {
  int i = d.toInt();
  if (i == d) return i.toString();
  return d.toString();
}
