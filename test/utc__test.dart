import 'package:flutter_fragment/utc.dart';
import 'package:test/test.dart';

void main() {
  test('format', () {
    DateTime date = DateTime.parse('2020-11-24T12:58:07.000Z');
    String formatted = toUTC(date);
    expect(formatted, equals("Tue, 24 Nov 2020 12:58:07 GMT"));
  });
  test('parse', () {
    DateTime formatted = fromUTC("Tue, 24 Nov 2020 12:58:17 GMT");
    expect(formatted, equals(DateTime.parse("2020-11-24T12:58:17.000Z")));
  });
}
