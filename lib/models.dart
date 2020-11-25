import 'token.dart';

Node newNode(String tagName) {
  switch (tagName) {
    case 'image': return Image();
    case 'view': return View();
    case 'text': return Text();
    case 'template': return Template();
    case 'templates': return Templates();
    case 'span': return Span();
    case 'rich': return Rich();
    default: return null;
  }
}

abstract class Node {
  String get tagName;
  setAttr(Token token);
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
  setAttr(Token token) {
    if (token.attrName == 'href') {
      href = token.attrValue;
    } else {
      throw new ParserException('<view> 不存在属性${token.attrName}', token);
    }
  }
}

class Templates implements Node, WithChild {
  final String tagName = 'templates';
  final List<Template> child = [];
  DateTime lastModified;
  String etag;

  @override
  setAttr(Token token) {
    if (token.attrName == 'lastModified') {
      lastModified = DateTime.parse(token.attrValue);
    } else {
      throw ParserException('<fragments> 不存在属性${token.attrName}', token);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'lastModified': lastModified, 'etag': etag};
  }
}

class Template implements Node, WithChild {
  final String tagName = 'template';
  String id;
  final List<Element> child = [];

  @override
  setAttr(Token token) {
    if (token.attrName == 'id') {
      id = token.attrValue;
    } else {
      throw new ParserException('<fragment>不存在属性${token.attrName}', token);
    }
  }

  @override
  Map<String, dynamic> getAttrs() {
    return {'id': id};
  }
}

class View extends Element implements WithChild {
  final String tagName = 'view';
  final List<Element> child = [];
  double width;
  double height;

  @override
  setAttr(Token token) {
    switch (token.attrName) {
      case 'height':
        height = token.doubleOfAttrValue();
        break;
      case 'width':
        width = token.doubleOfAttrValue();
        break;
      case 'href':
        href = token.attrValue;
        break;
      default:
        super.setAttr(token);
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
  void setAttr(Token token) {
    switch (token.attrName) {
      case 'height':
        height = token.doubleOfAttrValue();
        break;
      case 'width':
        width = token.doubleOfAttrValue();
        break;
      case 'src':
        src = token.attrValue;
        break;
      case 'href':
        href = token.attrValue;
        break;
      default:
        throw new ParserException('<image> 不存在属性${token.attrName}', token);
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

class Rich extends Element implements WithChild {
  final String tagName = 'rich';
  List<Span> child = [];
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
