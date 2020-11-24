import 'package:flutter_fragment/parse.dart';
import 'parse.dart';

abstract class Node {
  String get tagName;
  setAttr(String attrName, String attrValue, Context ctx);
  Map<String, dynamic> getAttrs();
}

abstract class WithChild implements Node {
  List get child;
}

abstract class WithText implements Node {
  String text;
}

abstract class Element extends Node {
  String href;

  @override
  setAttr(String attrName, String attrValue, Context ctx) {
    if (attrName == 'href') {
      href = attrValue;
    } else {
      throw new ParserException('<view> 不存在属性$attrName', ctx);
    }
  }
}

class Fragments implements Node, WithChild {
  final String tagName = 'fragments';
  final List<Fragment> child = [];
  DateTime lastModified;
  String etag;

  @override
  setAttr(String attrName, String attrValue, Context ctx) {
    if (attrName == 'lastModified') {
      lastModified = DateTime.parse(attrValue);
    } else {
      throw ParserException('<fragments> 不存在属性$attrName', ctx);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return Map.from({'lastModified': lastModified, 'etag': etag});
  }
}

class Fragment implements Node, WithChild {
  final String tagName = 'fragment';
  String id;
  final List<Element> child = [];

  @override
  setAttr(String attrName, String attrValue, Context ctx) {
    if (attrName == 'id') {
      id = attrValue;
    } else {
      throw new ParserException('<fragment>不存在属性$attrName', ctx);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return Map.from({'id': id});
  }
}

class View extends Element implements WithChild {
  final String tagName = 'view';
  final List<Element> child = [];
  double width;
  double height;

  @override
  setAttr(String attrName, String attrValue, Context ctx) {
    switch (attrName) {
      case 'height':
        height = doubleOf(attrValue, ctx);
        break;
      case 'width':
        width = doubleOf(attrValue, ctx);
        break;
      case 'href':
        href = attrValue;
        break;
      default:
        super.setAttr(attrName, attrValue, ctx);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return Map.from({'width': width, 'height': height, 'href': href});
  }
}

class Image extends Element {
  final String tagName = 'image';
  double width;
  double height;
  String src;

  @override
  void setAttr(String attrName, String attrValue, Context ctx) {
    switch (attrName) {
      case 'height':
        height = doubleOf(attrValue, ctx);
        break;
      case 'width':
        width = doubleOf(attrValue, ctx);
        break;
      case 'src':
        src = attrValue;
        break;
      case 'href':
        href = attrValue;
        break;
      default:
        throw new ParserException('<image> 不存在属性$attrName', ctx);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return Map.from(
        {'width': width, 'height': height, 'src': src, 'href': href});
  }
}

class Text extends Element implements WithText {
  final String tagName = 'text';
  String text;
  @override
  Map<String, dynamic> getAttrs() {
    return Map.from({'href': href});
  }
}

class Rich extends Element implements WithChild {
  final String tagName = 'rich';
  List<Span> child = [];
  @override
  Map<String, dynamic> getAttrs() {
    return Map.from({'href': href});
  }
}

class Span extends Element implements WithText {
  final String tagName = 'span';
  String text;
  @override
  Map<String, dynamic> getAttrs() {
    return Map.from({'href': href});
  }
}
