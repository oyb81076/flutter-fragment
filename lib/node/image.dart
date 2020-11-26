import 'base.dart';

class Image extends Element {
  final String tagName = 'image';
  double width;
  double height;
  String src;

  @override
  void setAttr(String attrName, Val val) {
    switch (attrName) {
      case 'height':
        height = val.doubleVal;
        break;
      case 'width':
        width = val.doubleVal;
        break;
      case 'src':
        src = val.strVal;
        break;
      case 'href':
        href = val.strVal;
        break;
      default:
        val.unexpectAttrName();
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'width': width, 'height': height, 'src': src, 'href': href};
  }
}
