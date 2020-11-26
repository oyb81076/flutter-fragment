abstract class Val {
  double get doubleVal;
  String get strVal;
  DateTime get datetimeVal;
  bool get boolVal;
  void unexpectAttrName();
}

abstract class Node {
  String get tagName;
  setAttr(String attrName, Val val);
  Map<String, dynamic> getAttrs();
}

abstract class WithChildren implements Node {
  List get children;
}

abstract class WithText implements Node {
  String text;
}

abstract class Element extends Node {
  String href;

  @override
  setAttr(String attrName, Val val) {
    if (attrName == 'href') {
      href = val.strVal;
    } else {
      val.unexpectAttrName();
    }
  }
}
