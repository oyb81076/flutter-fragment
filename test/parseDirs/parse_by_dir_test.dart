import 'package:test/test.dart';
import 'dart:io';
import '../../lib/parse_by_dir.dart';
import '../../lib/xml.dart';
import '../resolve.dart';

main() {
  test("all", () async {
    String dir = resolve('source');
    Fragments fragments = await parseByDirectory(dir);
    String dist = serialize(fragments);
    String matcher =
        await File(resolve('build.xml'))
            .readAsString();
    expect(dist, equals(matcher));
  });
}
