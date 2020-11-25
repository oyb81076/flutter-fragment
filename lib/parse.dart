import 'models.dart';
import 'parse_context.dart';



Templates parse(String content, {String filename = ""}) {
  Context ctx = Context(content, filename);
  int s = _FLAG_NONE;
  for (int i = 0; i < content.length; i++) {
    String c = content[i];
    ctx.pos(c);
    s = _ACTIONS[s](c, ctx);
  }
  return _eof(s, ctx);
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
];

int _on_none(String c, Context ctx) {
  switch (c) {
    case '<':
      return _FLAG_NONE_LT;
    case ' ':
    case '\t':
    case '\n':
      return _FLAG_NONE;
    default:
      throw new ParserException('只有<text> 标签内部可以插入文本"$c"', ctx);
  }
}

int _on_none_lt(String c, Context ctx) {
  if (c == '/') {
    ctx.tagName = '';
    return _FLAG_NONE_CLOSING;
  } else {
    ctx.tagName = c;
    return _FLAG_OPEN_TAG_NAME;
  }
}

int _on_none_closing(String c, Context ctx) {
  if (c != '>') {
    ctx.tagName += c;
    return _FLAG_NONE_CLOSING;
  }
  if (ctx.entry.node.tagName != ctx.tagName) {
    throw new ParserException('<view> 和 </${ctx.tagName}> 不匹配', ctx);
  }
  ctx.closeElement();
  return _FLAG_NONE;
}

int _on_open_tag_name(String c, Context ctx) {
  switch (c) {
    case '\t':
    case '\n':
    case ' ':
      ctx.createElement();
      return _FLAG_OPENING;
    case '>':
      ctx.createElement();
      return ctx.entry.innerText ? _FLAG_TEXT : _FLAG_NONE;
    case '/':
      ctx.createElement();
      return _FLAG_OPENING_CLOSING;
    case '&':
    case '<':
      throw new ParserException('错误的标签字符$c', ctx);
    default:
      ctx.tagName += c;
      return _FLAG_OPEN_TAG_NAME;
  }
}

int _on_opening(String c, Context ctx) {
  switch (c) {
    case '/':
      return _FLAG_OPENING_CLOSING;
    case ' ':
    case '\t':
    case '\n':
      return _FLAG_OPENING;
    case '>':
      return ctx.entry.innerText ? _FLAG_TEXT : _FLAG_NONE;
    default:
      ctx.attrName = c;
      return _FLAG_ATTR_NAME;
  }
}

int _on_opening_closing(String c, Context ctx) {
  if (c != '>') throw new ParserException('字符必须是 >', ctx);
  ctx.closeElement();
  return _FLAG_NONE;
}

int _on_attr_name(String c, Context ctx) {
  switch (c) {
    case '\t':
    case '\n':
    case ' ':
      ctx.createAttr();
      return _FLAG_OPENING;
    case '>':
      ctx.createAttr();
      return _FLAG_NONE;
    case '=':
      ctx.attrValue = '';
      return _FLAG_ATTR_VALUE;
    default:
      ctx.attrName += c;
      return _FLAG_ATTR_NAME;
  }
}

int _on_attr_value(String c, Context ctx) {
  if (ctx.attrQuot != null) {
    if (ctx.attrQuot == c) {
      ctx.attrQuot = null;
      ctx.createAttr();
      return _FLAG_OPENING;
    }
  } else if (ctx.attrValue != '') {
    if (c == ' ' || c == '\t' || c == '\n') {
      ctx.attrQuot = null;
      ctx.createAttr();
      return _FLAG_OPENING;
    } else if (c == '>') {
      ctx.attrQuot = null;
      ctx.createAttr();
      return ctx.entry.innerText ? _FLAG_TEXT : _FLAG_NONE;
    }
  }
  if (ctx.attrValue == '' && (c == '"' || c == "'")) {
    ctx.attrQuot = c;
  } else {
    c = ctx.escapeOf(c);
    if (c != null) ctx.attrValue += c;
  }
  return _FLAG_ATTR_VALUE;
}

int _on_text(String c, Context ctx) {
  if (c == '<') {
    ctx.textLt = c;
    return _FLAG_TEXT_LT;
  }
  c = ctx.escapeOf(c);
  if (c != null) {
    ctx.textValue += c;
  }
  return _FLAG_TEXT;
}

int _on_text_lt(String c, Context ctx) {
  ctx.textLt += c;
  String close = '</${ctx.entry.node.tagName}>';
  if (ctx.textLt == close) {
    ctx.textLt = null;
    ctx.closeElement();
    return _FLAG_NONE;
  } else if (close.startsWith(ctx.textLt)) {
    return _FLAG_TEXT_LT;
  }
  ctx.textValue += ctx.textLt;
  return _FLAG_TEXT;
}

Templates _eof(int state, Context ctx) {
  if (ctx.escape != null) {
    throw new ParserException('escape尚未结束', ctx);
  }
  if (state != _FLAG_NONE) {
    throw new ParserException('错误的状态$state', ctx);
  }
  var entry = ctx.entry;
  if (entry == null) return Templates();
  if (!entry.closed)
    throw new ParserException('为闭合的标签<${entry.node.tagName}>', ctx);
  while (ctx.stack.isNotEmpty) {
    entry = ctx.stack.removeLast();
    if (!entry.closed)
      throw new ParserException('为闭合的标签<${entry.node.tagName}>', ctx);
  }
  return entry.node;
}
