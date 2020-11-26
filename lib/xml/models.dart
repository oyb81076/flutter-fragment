import 'context.dart';

abstract class Val {
  double get doubleVal;
  String get strVal;
  DateTime get datetimeVal;
}

// 验证父子标签是否合法
bool isValidRalation(String parentTagName, String childTagName) {
  if (childTagName == 'span') {
    return parentTagName == 'rich';
  } else if (parentTagName == 'rich') {
    return childTagName == 'span';
  } else {
    return true;
  }
}

final Map<String, Node Function()> tags = {
  'image': () => Image(),
  'view': () => View(),
  'text': () => Text(),
  'template': () => Template(),
  'templates': () => Templates(),
  'span': () => Span(),
  'rich': () => Rich(),
};

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
      throw new ParserException('<view> 不存在属性${attrName}', val);
    }
  }
}

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
      throw ParserException('<fragments> 不存在属性${attrName}', val);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'lastModified': lastModified, 'etag': etag};
  }
}

class Template implements Node, WithChildren {
  final String tagName = 'template';
  String id;
  final List<Element> children = [];

  @override
  setAttr(String attrName, Val val) {
    if (attrName == 'id') {
      id = val.strVal;
    } else {
      throw new ParserException('<fragment>不存在属性${attrName}', val);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'id': id};
  }
}

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
        throw new ParserException('<image> 不存在属性${attrName}', val);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'width': width, 'height': height, 'src': src, 'href': href};
  }
}

class Text extends Element implements WithText {
  final String tagName = 'text';
  String text;
  @override
  Map<String, dynamic> getAttrs() {
    return {'href': href};
  }
}

class Rich extends Element implements WithChildren {
  final String tagName = 'rich';
  List<Span> children = [];
  @override
  Map<String, dynamic> getAttrs() {
    return {'href': href};
  }
}

class Span extends Element implements WithText {
  final String tagName = 'span';
  String text;
  @override
  Map<String, dynamic> getAttrs() {
    return {'href': href};
  }
}
