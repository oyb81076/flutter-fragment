import 'package:flutter_fragment/parse_dir.dart';
import 'package:test/test.dart';
import 'package:flutter_fragment/models.dart';
import 'package:flutter_fragment/serialize.dart';
import 'dart:io';
import '../resolve.dart';

main() {
  test("all", () async {
    String dir = resolve('source');
    Templates fragments = await parseDir(dir);
    String dist = serialize(fragments);
    String matcher = await File(resolve('build.xml')).readAsString();
    expect(dist, equals(matcher));
  });
}
