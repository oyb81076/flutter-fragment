import 'base.dart';

class Template implements Node, WithChildren {
  final String tagName = 'template';
  String id;
  final List<Element> children = [];

  @override
  setAttr(String attrName, Val val) {
    if (attrName == 'id') {
      id = val.strVal;
    } else {
      val.unexpectAttrName();
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'id': id};
  }
}
