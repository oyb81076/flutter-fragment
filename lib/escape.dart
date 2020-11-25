var _escapes = {
  "&lt;": "<",
  "&gt;": '>',
  '&amp;': '&',
  '&quot;': '"',
  '&apos;': "'",
  '&eq;': "=",
  '&nbsp;': '\u00A0',
};

String fromEscape(String chars) {
  return _escapes[chars];
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

/**
 * 去掉 <text></text> 标签中的一些文字
 * 如
 * <text>
 * as b
 *    c
 * e
 *   </text>
 * 可以转化为 "as b\nc\ne"
 */
String trimText(String text) {
  if (text == '') return text;
  return text
      .replaceFirst(RegExp(r'^[ \t\n]+'), '')
      .replaceFirst(RegExp(r'[ \t\n]+$'), '')
      .replaceAll(RegExp(r'[ \t\n]+'), ' ');
}
