import 'base.dart';

class Text extends Element implements WithText {
  final String tagName = 'text';
  String text;
  @override
  Map<String, dynamic> getAttrs() {
    return {'href': href};
  }
}
