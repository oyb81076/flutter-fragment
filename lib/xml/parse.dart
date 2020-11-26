import '../utils/chars.dart';
import 'context.dart';
import '../node.dart';

Templates parse(String content, {String filename = "", bool strictMode = false}) {
  Context context = Context(content, filename, strictMode);
  int flag = _FLAG_NONE;
  for (int i = 0; i < content.length; i++) {
    int c = content.codeUnitAt(i);
    context.accept(c);
    flag = _ACTIONS[flag](c, i, context);
    // print('$i ${content[i]} ==> $flag');
  }
  return _eof(flag, context);
}

const _FLAG_NONE = 0; // 关闭状态或者其他
const _FLAG_NONE_LT = 1; // <view> <
const _FLAG_NONE_CLOSING = 2; // 当前状态为 </div>
const _FLAG_OPEN_TAG_NAME = 3;
const _FLAG_OPENING = 4; // 标签半开放状态
const _FLAG_OPENING_CLOSING = 5; // <div /
const _FLAG_ATTR_NAME = 6;
const _FLAG_ATTR_VALUE = 7;
const _FLAG_ATTR_VALUE_NONE = 8;
const _FLAG_ATTR_VALUE_QUOT = 9;
const _FLAG_ATTR_VALUE_APOS = 10;

const _FLAG_TEXT = 11;
const _FLAG_TEXT_LT = 12;
const _FLAG_TEXT_CLOSING = 13;

const _FLAG_NONE_COMMENT_1 = 14; // <!
const _FLAG_NONE_COMMENT_2 = 15; // <!-
const _FLAG_NONE_COMMENT_3 = 16; // <!--
const _FLAG_NONE_COMMENT_4 = 17; // -
const _FLAG_NONE_COMMENT_5 = 18; // --

const _FLAG_TEXT_COMMENT_1 = 19; // <!
const _FLAG_TEXT_COMMENT_2 = 20; // <!-
const _FLAG_TEXT_COMMENT_3 = 21; // <!--
const _FLAG_TEXT_COMMENT_4 = 22; // -
const _FLAG_TEXT_COMMENT_5 = 23; // --

const List<int Function(int, int, Context)> _ACTIONS = [
  _on_none,
  _on_none_lt,
  _on_none_closing,
  _on_open_tag_name,
  _on_opening,
  _on_opening_closing,
  _on_attr_name,
  _on_attr_value,
  _on_attr_value_none,
  _on_attr_value_quot,
  _on_attr_value_apos,
  _on_text,
  _on_text_lt,
  _on_text_closing,
  _on_none_commnet_1,
  _on_none_commnet_2,
  _on_none_commnet_3,
  _on_none_commnet_4,
  _on_none_commnet_5,
  _on_text_commnet_1,
  _on_text_commnet_2,
  _on_text_commnet_3,
  _on_text_commnet_4,
  _on_text_commnet_5,
];

int _on_none(int c, int index, Context context) {
  if (c == LESS_THAN_SIGN) return _FLAG_NONE_LT;
  if (isSpace(c)) return _FLAG_NONE;
  throw new ParserException('非文本标签内部无法插入文本', context);
}

int _on_none_lt(int c, int index, Context context) {
  if (c == SOLIDUS) {
    context.offset = index + 1;
    return _FLAG_NONE_CLOSING;
  } else if (isAlpha(c)) {
    context.offset = index;
    return _FLAG_OPEN_TAG_NAME;
  } else if (c == EXCLAMATION_MARK) {
    return _FLAG_NONE_COMMENT_1;
  } else {
    throw ParserException('未知字符<$c', context);
  }
}

int _on_open_tag_name(int c, int index, Context context) {
  if (isAlpha(c)) {
    return _FLAG_OPEN_TAG_NAME;
  } else if (isSpace(c)) {
    context.tagName(index);
    context.createElement();
    return _FLAG_OPENING;
  } else if (c == GREATER_THAN_SIGN) {
    context.tagName(index);
    context.createElement();
    if (!context.texting) return _FLAG_NONE;
    context.offset = index + 1;
    return _FLAG_TEXT;
  } else if (c == SOLIDUS) {
    context.tagName(index);
    context.createElement();
    return _FLAG_OPENING_CLOSING;
  } else {
    throw new ParserException('错误的标签字符', context);
  }
}

int _on_opening(int c, int index, Context context) {
  if (isAttrName(c)) {
    context.offset = index;
    return _FLAG_ATTR_NAME;
  } else if (c == GREATER_THAN_SIGN) {
    if (!context.texting) return _FLAG_NONE;
    context.offset = index + 1;
    return _FLAG_TEXT;
  } else if (c == SOLIDUS) {
    return _FLAG_OPENING_CLOSING;
  } else if (isSpace(c)) {
    return _FLAG_OPENING;
  } else {
    throw new ParserException('错误的属性名字符', context);
  }
}

int _on_opening_closing(int c, int index, Context context) {
  if (c != GREATER_THAN_SIGN) throw new ParserException('自闭合标签错误, 当前字符必须为>', context);
  context.closeElement();
  return _FLAG_NONE;
}

int _on_attr_name(int c, int index, Context context) {
  if (isSpace(c)) {
    context.attrName(index);
    context.setAttr();
    return _FLAG_OPENING;
  } else if (c == GREATER_THAN_SIGN) {
    context.attrName(index);
    context.setAttr();
    return _FLAG_NONE;
  } else if (c == EQUALS_SIGN) {
    context.attrName(index);
    return _FLAG_ATTR_VALUE;
  } else if (isAttrName(c)) {
    return _FLAG_ATTR_NAME;
  } else {
    throw ParserException('不合法的属性名称', context);
  }
}

int _on_attr_value(int c, int index, Context context) {
  if (c == QUOTATION_MARK) {
    context.offset = index + 1;
    return _FLAG_ATTR_VALUE_QUOT;
  } else if (c == APOSTROPHE) {
    context.offset = index + 1;
    return _FLAG_ATTR_VALUE_APOS;
  } else if (isSpace(c)) {
    context.setAttr();
    return _FLAG_OPENING;
  } else {
    context.offset = index;
    return _FLAG_ATTR_VALUE_NONE;
  }
}

int _on_attr_value_none(int c, int index, Context context) {
  if (isSpace(c)) {
    context.attrValue(index);
    context.setAttr();
    return _FLAG_OPENING;
  } else if (c == GREATER_THAN_SIGN) {
    context.attrValue(index);
    context.setAttr();
    if (!context.texting) return _FLAG_NONE;
    context.offset = index + 1;
    return _FLAG_TEXT;
  } else {
    return _FLAG_ATTR_VALUE_NONE;
  }
}

int _on_attr_value_quot(int c, int index, Context context) {
  if (c != QUOTATION_MARK) {
    return _FLAG_ATTR_VALUE_QUOT;
  } else {
    context.attrValue(index);
    context.setAttr();
    return _FLAG_OPENING;
  }
}

int _on_attr_value_apos(int c, int index, Context context) {
  if (c != APOSTROPHE) {
    return _FLAG_ATTR_VALUE_APOS;
  } else {
    context.attrValue(index);
    context.setAttr();
    return _FLAG_OPENING;
  }
}

int _on_text(int c, int index, Context context) {
  if (c == LESS_THAN_SIGN) return _FLAG_TEXT_LT;
  return _FLAG_TEXT;
}

int _on_text_lt(int c, int index, Context context) {
  if (c == SOLIDUS) {
    context.text(index - 1);
    context.offset = index + 1;
    return _FLAG_TEXT_CLOSING;
  } else if (c == EXCLAMATION_MARK) {
    return _FLAG_TEXT_COMMENT_1;
  } else if (isSpace(c)) {
    return _FLAG_TEXT;
  } else {
    throw ParserException('文本标签内部禁止使用其他标签', context);
  }
}

int _on_none_closing(int c, int index, Context context) {
  if (isAlpha(c)) {
    return _FLAG_NONE_CLOSING;
  } else if (c == GREATER_THAN_SIGN) {
    context.tagName(index);
    context.closeElement();
    return _FLAG_NONE;
  } else {
    throw new ParserException('关闭标签必须是由字母组成', context);
  }
}

int _on_text_closing(int c, int index, Context context) {
  if (isAlpha(c)) {
    return _FLAG_TEXT_CLOSING;
  } else if (c == GREATER_THAN_SIGN) {
    context.closeElement();
    return _FLAG_NONE;
  }
  throw ParserException('闭合标签字符错误', context);
}

// at <!
int _on_none_commnet_1(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_NONE_COMMENT_2;
  throw new ParserException("错误的字符", context);
}

// at <!-
int _on_none_commnet_2(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_NONE_COMMENT_3;
  throw new ParserException("错误的字符$c", context);
}

// at <!--
int _on_none_commnet_3(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_NONE_COMMENT_4;
  return _FLAG_NONE_COMMENT_3;
}

// at <!--   -
int _on_none_commnet_4(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_NONE_COMMENT_5;
  return _FLAG_NONE_COMMENT_4;
}

// at <!--   --
int _on_none_commnet_5(int c, int index, Context context) {
  if (c == GREATER_THAN_SIGN) return _FLAG_NONE;
  throw new ParserException('must be > to close comment, bug got $c', context);
}

int _on_text_commnet_1(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_TEXT_COMMENT_2;
  return _FLAG_TEXT;
}

int _on_text_commnet_2(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_TEXT_COMMENT_3;
  return _FLAG_TEXT;
}

int _on_text_commnet_3(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_TEXT_COMMENT_4;
  return _FLAG_TEXT_COMMENT_3;
}

int _on_text_commnet_4(int c, int index, Context context) {
  if (c == HYPHEN_MINUS) return _FLAG_TEXT_COMMENT_5;
  return _FLAG_TEXT_COMMENT_3;
}

int _on_text_commnet_5(int c, int index, Context context) {
  if (c == GREATER_THAN_SIGN) return _FLAG_TEXT;
  throw new ParserException('must be > to close comment, bug got $c', context);
}

Templates _eof(int state, Context context) {
  if (state != _FLAG_NONE) {
    throw new ParserException('错误的状态$state', context);
  }
  var entry = context.entry;
  if (entry == null) return Templates();
  if (!entry.closed)
    throw new ParserException('为闭合的标签<${entry.node.tagName}>', context);
  while (context.stack.isNotEmpty) {
    entry = context.stack.removeLast();
    if (!entry.closed)
      throw new ParserException('为闭合的标签<${entry.node.tagName}>', context);
  }
  return entry.node;
}
