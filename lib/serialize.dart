import 'dart:collection';
import 'models.dart';
import 'escape.dart';

String serialize(dynamic root, {bool compact = false}) {
  String out = '';
  String indent = '';
  ListQueue list = ListQueue.from(root is List ? root.reversed : [root]);
  while (list.isNotEmpty) {
    var node = list.removeLast();
    if (node is String) {
      if (!compact) indent = indent.substring(2);
      out += '$indent</$node>';
    } else if (node is Node) {
      out += '$indent<${node.tagName}';
      var attrs = node.getAttrs();
      attrs.entries
          .where((element) => element.value != null)
          .forEach((element) {
        String value = escapeAttrValue(element.value);
        out += ' ${element.key}="${value}"';
      });
      if (node is WithText) {
        String text = escapeText(node.text);
        out += '>$text</${node.tagName}>';
      } else if (node is WithChild) {
        if (node.child.isEmpty) {
          out += '/>';
        } else {
          out += '>';
          list.add(node.tagName);
          list.addAll(node.child.reversed);
          if (!compact) {
            indent += '  ';
          }
        }
      } else {
        out += '/>';
      }
    }
    if (!compact && list.isNotEmpty) out += '\n';
  }
  return out;
}
