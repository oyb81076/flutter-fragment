import 'base.dart';

class Span extends Element implements WithText {
  final String tagName = 'span';
  String text;
  @override
  Map<String, dynamic> getAttrs() {
    return {'href': href};
  }
}
