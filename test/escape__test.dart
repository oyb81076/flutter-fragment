import 'package:flutter_fragment/escape.dart';
import 'package:test/test.dart';

void main() {
  test("trimText", () async {
    expect(trimText("\na\n\n\nb\nc\n  "), equals('a b c'));
  });
}
