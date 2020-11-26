import 'dart:collection';
import 'models.dart';
import 'chars.dart';

String serialize(dynamic root, {bool compact = false}) {
  StringBuffer out = StringBuffer();
  int indent = 0;
  ListQueue list = ListQueue.from(root is List ? root.reversed : [root]);
  while (list.isNotEmpty) {
    var node = list.removeLast();
    if (node is String) {
      indent--;
      if (!compact) tab(out, indent);
      out..write('</')..write(node)..write('>');
    } else if (node is Node) {
      if (!compact) tab(out, indent);
      out..write('<')..write(node.tagName);
      var attrs = node.getAttrs();
      attrs.entries
          .where((element) => element.value != null)
          .forEach((element) {
        String value = escapeAttrValue(element.value);
        out
          ..write(' ')
          ..write(element.key)
          ..write('=')
          ..write('"')
          ..write(value)
          ..write('"');
      });
      if (node is WithText) {
        String text = escapeText(node.text);
        out
          ..write('>')
          ..write(text)
          ..write('</')
          ..write(node.tagName)
          ..write('>');
      } else if (node is WithChildren) {
        if (node.children.isEmpty) {
          out.write('/>');
        } else {
          out.write('>');
          list.add(node.tagName);
          list.addAll(node.children.reversed);
          indent++;
        }
      } else {
        out.write('/>');
      }
    }
    if (!compact && list.isNotEmpty) out.write('\n');
  }
  return out.toString();
}

void tab(StringBuffer sb, int indent) {
  while (indent-- > 0) sb.write('  ');
}
