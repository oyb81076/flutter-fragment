import 'dart:collection';

class Fragment {
  String id;
  List<Node> child;
}

class Node {
  String href;
}

class View extends Node {
  double width;
  double height;
  List<Node> child;
}

class Image extends Node {
  double width;
  double height;
  String src;
}

class Text extends Node {
  String text;
}

List<Fragment> parse(String content) {
  Context context = Context(content);
  for (int i = 0; i < content.length; i++) {
    _State s = context.process(content[i]);
    if (s == null) throw ParserException('错误的返回状态', context);
    context.state = s;
  }
  return context.end();
}

String serialize(List<Fragment> fragments, {bool compcat = false}) {
  String out = '';
  String indent = '';
  ListQueue list = ListQueue.from(fragments);
  while (list.isNotEmpty) {
    var node = list.removeLast();
    if (node is String) {
      if (!compcat) indent = indent.substring(2);
      out += '$indent</$node>';
      if (!compcat) out += '\n';
    } else if (node is Text) {
      out += '$indent<text';
      if (node.href != null) out += ' href="${escapeAttrValue(node.href)}"';
      if (node.text == '') {
        out += '/>';
        if (!compcat) out += '\n';
      } else if (compcat) {
        out += '>${node.text}</text>';
      } else if (!node.text.contains('\n')) {
        out += '>${node.text}</text>\n';
      } else {
        out += '>\n';
        out += node.text
            .split('\n')
            .map((e) => e == '\n' ? '\n' : '  $indent$e')
            .join('\n');
        out += '\n';
        out += '$indent</text>\n';
      }
    } else if (node is View) {
      out += '$indent<view';
      if (node.width != null) out += ' width=${srzDouble(node.width)}';
      if (node.height != null) out += ' width=${srzDouble(node.height)}';
      if (node.href != null) out += ' width=${escapeAttrValue(node.href)}';
      if (node.child == null) {
        out += '/>';
        if (!compcat) out += '\n';
      } else {
        out += '>';
        if (!compcat) {
          out += '\n';
          indent += '  ';
        }
        list.add('view');
        list.addAll(node.child.reversed);
      }
    } else if (node is Fragment) {
      out += '$indent<fragment';
      if (node.id != null) out += ' id="${escapeAttrValue(node.id)}"';
      if (node.child == null) {
        out += '/>';
        if (!compcat) out += '\n';
      } else {
        out += '>';
        if (!compcat) {
          out += '\n';
          indent += '  ';
        }
        list.add('fragment');
        list.addAll(node.child.reversed);
      }
    } else if (node is Image) {
      out += '$indent<image';
      if (node.width != null) out += ' width=${srzDouble(node.width)}';
      if (node.height != null) out += ' height=${srzDouble(node.height)}';
      if (node.href != null) out += ' href="${escapeAttrValue(node.href)}"';
      if (node.src != null) out += ' src="${escapeAttrValue(node.src)}"';
      out += '/>';
      if (!compcat) out += '\n';
    }
  }
  return out;
}

String escapeAttrValue(String value) {
  return value.replaceAll('"', '&quot;');
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
// <!-a-

class Context {
  String input;
  _State state = _State.none;
  String attrName;
  String attrValue;
  String attrQuot;
  String escape;
  String textValue;
  String tagName;
  String textLt;
  ListQueue stack = ListQueue();
  View view;
  Image image;
  Text text;
  Fragment fragment;
  List<Fragment> results = List();
  int line = 0;
  int col = 0;
  Context(this.input);

  _State process(String c) {
    if (c == '\n') {
      line += 1;
      col = 0;
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

  List<Fragment> end() {
    if (escape != null) {
      throw new ParserException('escape尚未结束', this);
    } else if (stack.isNotEmpty) {
      throw new ParserException('有标签尚未闭合', this);
    } else if (state != _State.none) {
      throw new ParserException('错误的状态$state', this);
    }
    return results;
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
    c = _escape(c);
    if (c == null) return _State.none;
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
        return text == null ? _State.none : _State.text;
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
        return text == null ? _State.none : _State.text;
      default:
        attrName = c;
        return _State.attr_name;
    }
  }

  _State _atOpeningClosing(String c) {
    if (c != '>') throw new ParserException('字符必须是 >', this);
    _closeElement();
    return text == null ? _State.none : _State.text;
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
    if (view != null) {
      if (tagName != 'view')
        throw new ParserException('<view> 和 </$tagName> 不匹配', this);
    } else if (text != null) {
      if (tagName != 'text')
        throw new ParserException('<text> 和 </$tagName> 不匹配', this);
    } else if (image != null) {
      if (tagName != 'image')
        throw new ParserException('<image> 和 </$tagName> 不匹配', this);
    } else if (fragment != null) {
      if (tagName != 'fragment')
        throw new ParserException('<fragment> 和 </$tagName> 不匹配', this);
    } else {
      throw ParserException('未知的闭合标签', this);
    }
    _closeElement();
    return _State.none;
  }

  void _attr() {
    if (view != null) {
      switch (attrName) {
        case 'height':
          view.height = parseDouble(attrValue, this);
          break;
        case 'width':
          view.width = parseDouble(attrValue, this);
          break;
        case 'href':
          view.href = attrValue;
          break;
        default:
          throw new ParserException('<view> 不存在属性$attrName', this);
      }
    } else if (text != null) {
      switch (attrName) {
        case 'href':
          text.href = attrValue;
          break;
        default:
          throw new ParserException('<text> 不存在属性$attrName', this);
      }
    } else if (image != null) {
      switch (attrName) {
        case 'height':
          image.height = parseDouble(attrValue, this);
          break;
        case 'width':
          image.width = parseDouble(attrValue, this);
          break;
        case 'src':
          image.src = attrValue;
          break;
        case 'href':
          image.href = attrValue;
          break;
        default:
          throw new ParserException('<image> 不存在属性$attrName', this);
      }
    } else if (fragment != null) {
      if (attrName == 'id') {
        fragment.id = attrValue;
      } else {
        throw new ParserException('<fragment>不存在属性$attrName', this);
      }
    }
    attrName = null;
    attrValue = null;
  }

  void _createElement() {
    List child = null;
    if (view != null) {
      if (stack.isEmpty) throw ParserException('根节点必须是<fragment>', this);
      child = view.child == null ? (view.child = List()) : view.child;
      stack.addLast(view);
    } else if (text != null) {
      if (stack.isEmpty) throw ParserException('根节点必须是<fragment>', this);
      stack.addLast(text);
      text = null;
    } else if (image != null) {
      if (stack.isEmpty) throw ParserException('根节点必须是<fragment>', this);
      stack.addLast(image);
      image = null;
    } else if (fragment != null) {
      stack.addLast(fragment);
      child =
          fragment.child == null ? (fragment.child = List()) : fragment.child;
      fragment = null;
    }
    switch (tagName) {
      case 'image':
        child.add(image = Image());
        break;
      case 'view':
        child.add(view = View());
        break;
      case 'fragment':
        fragment = Fragment();
        if (stack.isNotEmpty) throw ParserException('<fragment>必须是跟节点', this);
        break;
      case 'text':
        child.add(text = Text());
        textValue = '';
        break;
      default:
        throw new ParserException('未知的标签' + tagName, this);
    }
  }

  void _closeElement() {
    if (stack.isEmpty) {
      results.add(fragment);
      fragment = null;
    } else {
      if (text != null) {
        text.text = trim(textValue);
        textValue = null;
      }
      var node = stack.removeLast();
      text = null;
      view = null;
      image = null;
      fragment = null;
      if (node is View) {
        view = node;
      } else if (node is Text) {
        text = node;
      } else if (node is Image) {
        image = node;
      } else if (node is Fragment) {
        fragment = node;
      }
    }
  }
}

String trim(String text) {
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
  ParserException(this.msg, Context ctx) {
    line = ctx.line;
    col = ctx.col;
  }
  @override
  String toString() => 'ParserException: $msg (${line}:${col})';
}

double parseDouble(String value, Context ctx) {
  double d = double.tryParse(value);
  if (d == null) throw ParserException("无法将字符串'$value'转化为double", ctx);
  return d;
}

String srzDouble(double d) {
  int i = d.toInt();
  if (i == d) return i.toString();
  return d.toString();
}
