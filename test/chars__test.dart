import 'package:flutter_fragment/xml/chars.dart';
import 'package:test/test.dart';

void main() {
  test("unescapeText", () async {
    expect(unescapeText("\na\n\n\nb\nc\n  "), equals('a b c'));
    expect(unescapeText("""
    a <!-- some comment -->
    b   <!-- com -->
    <!-- com -->
    &lt;&nbsp;&nbsp;&gt;
    c
    """), equals('a b <\u00a0\u00a0> c'));
  });
}
