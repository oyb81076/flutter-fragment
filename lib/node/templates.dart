import 'base.dart';
import 'template.dart';

class Templates implements Node, WithChildren {
  final String tagName = 'templates';
  final List<Template> children = [];
  DateTime lastModified;
  String etag;

  @override
  setAttr(String attrName, Val val) {
    if (attrName == 'lastModified') {
      lastModified = val.datetimeVal;
    } else if (attrName == 'etag') {
      etag = val.strVal;
    } else {
      val.unexpectAttrName();
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'lastModified': lastModified, 'etag': etag};
  }
}
