import 'dart:io';
import 'package:flutter_fragment/models.dart';
import 'package:flutter_fragment/parse.dart';
import 'package:flutter_fragment/serialize.dart';
import 'package:test/test.dart';
import '../resolve.dart';

main() async {
  test("fragments", () async {
    String filename = resolve('fragments.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    String build = serialize(fragments, compact: false);
    String dist = await File(resolve('fragments.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("fragment", () async {
    String filename = resolve('fragment.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    expect(fragments.child.length, equals(1));
    String build = serialize(fragments.child[0], compact: false);
    String dist = await File(resolve('fragment.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("view", () async {
    String filename = resolve('view.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    expect(fragments.child.length, equals(1));
    String build = serialize(fragments.child[0].child, compact: false);
    String dist = await File(resolve('view.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("rich", () async {
    String filename = resolve('rich.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    expect(fragments.child.length, equals(1));
    String build = serialize(fragments.child[0].child, compact: false);
    String dist = await File(resolve('rich.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("text", () async {
    String filename = resolve('text.src.xml');
    String content = await File(filename).readAsString();
    Fragments fragments = parse(content, filename: filename);
    expect(fragments.child.length, equals(1));
    String build = serialize(fragments.child[0].child, compact: false);
    String dist = await File(resolve('text.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("empty", () async {
    Fragments fragments = parse("\n\n\n");
    expect(fragments.child.length, equals(0));
    String dist = serialize(fragments, compact: false);
    expect(dist, equals('<fragments/>'));
  });
}
