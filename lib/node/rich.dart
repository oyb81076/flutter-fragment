import 'base.dart';
import 'span.dart';

class Rich extends Element implements WithChildren {
  final String tagName = 'rich';
  List<Span> children = [];
  @override
  Map<String, dynamic> getAttrs() {
    return {'href': href};
  }
}