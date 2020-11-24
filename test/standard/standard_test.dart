import 'dart:io';
import 'package:flutter_fragment/xml.dart';
import 'package:test/test.dart';
import '../resolve.dart';

main() async {
  test("fragments", () async {
    String filename = resolve('fragments.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    String build = serialize(fragments, compcat: false);
    String dist = await File(resolve('fragments.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("fragment", () async {
    String filename = resolve('fragment.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    expect(fragments.child.length, equals(1));
    String build = serialize(fragments.child[0], compcat: false);
    String dist = await File(resolve('fragment.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("view.xml", () async {
    String filename = resolve('view.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    expect(fragments.child.length, equals(1));
    String build = serialize(fragments.child[0].child, compcat: false);
    String dist = await File(resolve('view.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("empty.xml", () async {
    Fragments fragments = parse("""


    """);
    expect(fragments.child.length, equals(0));
    String dist = serialize(fragments, compcat: false);
    expect(dist, equals('<fragments/>'));
  });
}
