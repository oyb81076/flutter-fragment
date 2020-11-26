var _escapes = {
  "&lt;": "<",
  "&gt;": '>',
  '&amp;': '&',
  '&quot;': '"',
  '&apos;': "'",
  '&eq;': "=",
  '&nbsp;': '\u00A0',
};

int TAB = 9; // \t
int LB = 10; // \n
int RETURN = 13; // \r
int SPACE = 32; // ' '
int NOT = 33; // !
int QUOT = 34; // "
int APOS = 39; // '
int MINUS = 45; // -
int DOT = 46;
int SLASH = 47; // /
int LT = 60; // <
int EQ = 61; // =
int GT = 62; // >
int UNDERLINE = 95; // _
int NBSP = 160; // \ua00a0

String fromEscape(String chars) {
  return _escapes[chars];
}

bool isSpace(int c) {
  return c == SPACE || c == TAB || c == LB || c == NBSP || c == RETURN;
}

bool isAlpha(int c) {
  return c > 96 && c < 123;
}

bool isAttrName(int c) {
  return  c > 96 && c < 123 || c > 64 && c < 91 || c == DOT || c == UNDERLINE || c == MINUS;
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
      .replaceAll('>', '&gt;')
      .replaceAll('<', '&lt;')
      .replaceAll('\u00a0', '&nbsp;');
}

String escapeAttrValue(dynamic value) {
  if (value is String) {
    return value.replaceAll('"', '&quot;');
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
