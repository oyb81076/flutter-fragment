// https://html.spec.whatwg.org/multipage/named-characters.html#named-character-references

var _escapes = {
  "&lt;": "<",
  "&gt;": '>',
  '&amp;': '&',
  '&quot;': '"',
  '&apos;': "'",
  '&eq;': "=",
  '&nbsp;': '\u00A0',
};

int TABULATION = 0x09; // \t
int LINE_FEED = 0x0a; // \n
int CARRIAGE_RETURN = 13; // \r
int SPACE = 0x20; // ' '
int EXCLAMATION_MARK = 0x21; // !
int QUOTATION_MARK = 0x22; // "
int APOSTROPHE = 0x27; // '
int HYPHEN_MINUS = 0x2d; // -
int DOT = 0x2e;
int SOLIDUS = 0x2f; // /
int LESS_THAN_SIGN = 0x3c; // <
int EQUALS_SIGN = 0x3d; // =
int GREATER_THAN_SIGN = 0x3e; // >
int UNDERLINE = 0x5f; // _
int NBSP = 0xa0; // \ua00a0
int LATIN_CAPITAL_A = 0x41;
int LATIN_CAPITAL_Z = 0x5a;
int LATIN_SMALL_A = 0x61;
int LATIN_SMALL_Z = 0x7a;

String fromEscape(String chars) {
  return _escapes[chars];
}

bool isSpace(int c) {
  return c == SPACE ||
      c == TABULATION ||
      c == LINE_FEED ||
      c == NBSP ||
      c == CARRIAGE_RETURN;
}

bool isAlpha(int c) {
  return c >= LATIN_SMALL_A && c <= LATIN_SMALL_Z;
}

bool isAttrName(int c) {
  return c >= LATIN_SMALL_A && c <= LATIN_SMALL_Z ||
      c >= LATIN_CAPITAL_A && c <= LATIN_CAPITAL_Z ||
      c == DOT ||
      c == UNDERLINE ||
      c == HYPHEN_MINUS;
}

String unescape(String chars) {
  return chars.replaceAllMapped(RegExp(r'&[a-z]+;'), (Match match) {
    String matched = match.group(0);
    String escaped = _escapes[matched];
    return escaped ?? matched;
  });
}

/**
 * 去掉注解
 * 单行文本保留前后空格, 并将连续多个空格符合并为1个
 * 多行文本删除前后空格, 并将连续多个空格符合并为1个
 */
String unescapeText(String chars) {
  if (chars.isEmpty) return chars;
  chars = chars.replaceAll(RegExp(r'<!--.*-->'), '');
  if (chars.contains('\n')) chars = chars.trim();
  chars = chars.replaceAll(RegExp(r'\s+'), ' ');
  return unescape(chars);
}

String escapeText(String chars) {
  return chars
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('\u00a0', '&nbsp;');
}

String escapeAttrValue(dynamic value) {
  if (value is String) {
    return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('"', '&quot;');
  } else if (value is double) {
    return _double2String(value);
  } else if (value is int || value is bool) {
    return value.toString();
  } else if (value is DateTime) {
    return value.toIso8601String();
  } else {
    throw new Exception('unspupprt value of $value');
  }
}

String _double2String(double d) {
  int i = d.toInt();
  if (i == d) return i.toString();
  return d.toString();
}
