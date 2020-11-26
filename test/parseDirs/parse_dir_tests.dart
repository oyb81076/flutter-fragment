import 'package:test/test.dart';
import 'dart:io';

import 'package:flutter_fragment/xml/parse_dir.dart';
import 'package:flutter_fragment/xml/models.dart';
import 'package:flutter_fragment/xml/serialize.dart';
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
