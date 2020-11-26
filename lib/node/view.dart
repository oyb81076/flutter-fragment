import 'base.dart';

class View extends Element implements WithChildren {
  final String tagName = 'view';
  final List<Element> children = [];
  double width;
  double height;

  @override
  setAttr(String attrName, Val val) {
    switch (attrName) {
      case 'height':
        height = val.doubleVal;
        break;
      case 'width':
        width = val.doubleVal;
        break;
      case 'href':
        href = val.strVal;
        break;
      default:
        super.setAttr(attrName, val);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'width': width, 'height': height, 'href': href};
  }
}
