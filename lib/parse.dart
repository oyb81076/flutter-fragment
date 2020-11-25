import 'models.dart';
import 'token.dart';

Templates parse(String content, {String filename = ""}) {
  Token token = Token(content, filename);
  int flag = _FLAG_NONE;
  for (int i = 0; i < content.length; i++) {
    String c = content[i];
    token.pos(c);
    flag = _ACTIONS[flag](c, token);
  }
  return _eof(flag, token);
}

const _FLAG_NONE = 0; // 关闭状态或者其他
const _FLAG_NONE_LT = 1; // <view> <
const _FLAG_NONE_CLOSING = 2; // 当前状态为 </div>
const _FLAG_OPEN_TAG_NAME = 3;
const _FLAG_OPENING = 4; // 标签半开放状态
const _FLAG_OPENING_CLOSING = 5; // <div /
const _FLAG_ATTR_NAME = 6;
const _FLAG_ATTR_VALUE = 7;
const _FLAG_TEXT = 8;
const _FLAG_TEXT_LT = 9; // <text> <
const _FLAG_TEXT_CLOSING = 10; // <text> <

const _FLAG_NONE_COMMENT_1 = 11; // <!
const _FLAG_NONE_COMMENT_2 = 12; // <!-
const _FLAG_NONE_COMMENT_3 = 13; // <!--
const _FLAG_NONE_COMMENT_4 = 14; // -
const _FLAG_NONE_COMMENT_5 = 15; // --

const _FLAG_TEXT_COMMENT_1 = 16; // <!
const _FLAG_TEXT_COMMENT_2 = 17; // <!-
const _FLAG_TEXT_COMMENT_3 = 18; // <!--
const _FLAG_TEXT_COMMENT_4 = 19; // -
const _FLAG_TEXT_COMMENT_5 = 20; // --

const _ACTIONS = [
  _on_none,
  _on_none_lt,
  _on_none_closing,
  _on_open_tag_name,
  _on_opening,
  _on_opening_closing,
  _on_attr_name,
  _on_attr_value,
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

int _on_none(String c, Token token) {
  switch (c) {
    case '<':
      return _FLAG_NONE_LT;
    case ' ':
    case '\t':
    case '\n':
      return _FLAG_NONE;
    default:
      throw new ParserException('非文本标签内部无法插入文本"$c"', token);
  }
}

int _on_none_lt(String c, Token token) {
  switch (c) {
    case '/':
      token.tagName = '';
      return _FLAG_NONE_CLOSING;
    case '!':
      return _FLAG_NONE_COMMENT_1;
    case ' ':
    case '\t':
    case '\n':
      throw ParserException('未知字符<$c', token);
    default:
      token.tagName = c;
      return _FLAG_OPEN_TAG_NAME;
  }
}

int _on_none_closing(String c, Token token) {
  if (c != '>') {
    token.tagName += c;
    return _FLAG_NONE_CLOSING;
  }
  String t = token.tagName.trimRight();
  if (token.entry.node.tagName != t) {
    throw new ParserException(
        '<${token.entry.node.tagName}> 和 </${t}> 不匹配', token);
  }
  token.closeElement();
  return _FLAG_NONE;
}

int _on_open_tag_name(String c, Token token) {
  switch (c) {
    case '\t':
    case '\n':
    case ' ':
      token.createElement();
      return _FLAG_OPENING;
    case '>':
      token.createElement();
      return token.texting ? _FLAG_TEXT : _FLAG_NONE;
    case '/':
      token.createElement();
      return _FLAG_OPENING_CLOSING;
    case '&':
    case '<':
      throw new ParserException('错误的标签字符$c', token);
    default:
      token.tagName += c;
      return _FLAG_OPEN_TAG_NAME;
  }
}

int _on_opening(String c, Token token) {
  switch (c) {
    case '/':
      return _FLAG_OPENING_CLOSING;
    case ' ':
    case '\t':
    case '\n':
      return _FLAG_OPENING;
    case '>':
      return token.texting ? _FLAG_TEXT : _FLAG_NONE;
    default:
      token.attrName = c;
      return _FLAG_ATTR_NAME;
  }
}

int _on_opening_closing(String c, Token token) {
  if (c != '>') throw new ParserException('字符必须是 >', token);
  token.closeElement();
  return _FLAG_NONE;
}

int _on_attr_name(String c, Token token) {
  switch (c) {
    case '\t':
    case '\n':
    case ' ':
      token.createAttr();
      return _FLAG_OPENING;
    case '>':
      token.createAttr();
      return _FLAG_NONE;
    case '=':
      token.attrValue = '';
      return _FLAG_ATTR_VALUE;
    default:
      token.attrName += c;
      return _FLAG_ATTR_NAME;
  }
}

int _on_attr_value(String c, Token token) {
  if (token.attrQuot != null) {
    if (token.attrQuot == c) {
      token.attrQuot = null;
      token.createAttr();
      return _FLAG_OPENING;
    }
  } else if (token.attrValue != '') {
    if (c == ' ' || c == '\t' || c == '\n') {
      token.attrQuot = null;
      token.createAttr();
      return _FLAG_OPENING;
    } else if (c == '>') {
      token.attrQuot = null;
      token.createAttr();
      return token.texting ? _FLAG_TEXT : _FLAG_NONE;
    }
  }
  if (token.attrValue == '' && (c == '"' || c == "'")) {
    token.attrQuot = c;
  } else {
    c = token.escapeOf(c);
    if (c != null) token.attrValue += c;
  }
  return _FLAG_ATTR_VALUE;
}

int _on_text(String c, Token token) {
  switch (c) {
    case '<':
      return _FLAG_TEXT_LT;
    case '!':
      return _FLAG_TEXT_COMMENT_1;
    default:
      var t = token.escapeOf(c);
      if (t != null) {
        token.textValue += t;
      }
      return _FLAG_TEXT;
  }
}

int _on_text_lt(String c, Token token) {
  switch (c) {
    case '/':
      token.tagName = '';
      return _FLAG_TEXT_CLOSING;
    case '!':
      return _FLAG_TEXT_COMMENT_1;
    default:
      token.textValue += '<$c';
      return _FLAG_TEXT;
  }
}

int _on_text_closing(String c, Token token) {
  switch (c) {
    case '>':
      if (token.tagName.trimRight() == token.entry.node.tagName) {
        token.closeElement();
        return _FLAG_NONE;
      }
      token.textValue += '</${token.tagName}>';
      return _FLAG_TEXT;
    case '<':
      token.tagName = null;
      token.textValue += '</${token.tagName}';
      return _FLAG_TEXT_LT;
    default:
      token.tagName += c;
      return _FLAG_TEXT_CLOSING;
  }
}

// at <!
int _on_none_commnet_1(String c, Token token) {
  if (c == '-') return _FLAG_NONE_COMMENT_2;
  throw new ParserException("错误的字符$c", token);
}

// at <!-
int _on_none_commnet_2(String c, Token token) {
  if (c == '-') return _FLAG_NONE_COMMENT_3;
  throw new ParserException("错误的字符$c", token);
}

// at <!--
int _on_none_commnet_3(String c, Token token) {
  if (c == '-') return _FLAG_NONE_COMMENT_4;
  return _FLAG_NONE_COMMENT_3;
}

// at <!--   -
int _on_none_commnet_4(String c, Token token) {
  if (c == '-') return _FLAG_NONE_COMMENT_5;
  return _FLAG_NONE_COMMENT_4;
}

// at <!--   --
int _on_none_commnet_5(String c, Token token) {
  if (c == '>') return _FLAG_NONE;
  throw new ParserException('must be > to close comment, bug got $c', token);
}

int _on_text_commnet_1(String c, Token token) {
  if (c == '-') return _FLAG_TEXT_COMMENT_2;
  token.textValue += '<!$c';
  return _FLAG_TEXT;
}

int _on_text_commnet_2(String c, Token token) {
  if (c == '-') return _FLAG_TEXT_COMMENT_3;
  token.textValue += '<!-$c';
  return _FLAG_TEXT;
}

int _on_text_commnet_3(String c, Token token) {
  if (c == '-') return _FLAG_TEXT_COMMENT_4;
  return _FLAG_TEXT_COMMENT_3;
}

int _on_text_commnet_4(String c, Token token) {
  if (c == '-') return _FLAG_TEXT_COMMENT_5;
  return _FLAG_TEXT_COMMENT_3;
}

int _on_text_commnet_5(String c, Token token) {
  if (c == '-') return _FLAG_TEXT_COMMENT_4;
  if (c == '>') return _FLAG_TEXT;
  throw new ParserException('must be > to close comment, bug got $c', token);
}

Templates _eof(int state, Token token) {
  if (token.escape != null) {
    throw new ParserException('escape尚未结束', token);
  }
  if (state != _FLAG_NONE) {
    throw new ParserException('错误的状态$state', token);
  }
  var entry = token.entry;
  if (entry == null) return Templates();
  if (!entry.closed)
    throw new ParserException('为闭合的标签<${entry.node.tagName}>', token);
  while (token.stack.isNotEmpty) {
    entry = token.stack.removeLast();
    if (!entry.closed)
      throw new ParserException('为闭合的标签<${entry.node.tagName}>', token);
  }
  return entry.node;
}
