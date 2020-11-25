import 'dart:io';
import 'package:flutter_fragment/models.dart';
import 'package:flutter_fragment/parse.dart';
import 'package:flutter_fragment/serialize.dart';
import 'package:test/test.dart';
import '../resolve.dart';

main() async {
  test("templates", () async {
    String filename = resolve('templates.src.xml');
    String content = await File(filename).readAsString();
    Templates templates = parse(content, filename: filename);
    String build = serialize(templates, compact: false);
    String dist = await File(resolve('templates.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("template", () async {
    String filename = resolve('template.src.xml');
    String content = await File(filename).readAsString();
    Templates templates = parse(content, filename: filename);
    expect(templates.child.length, equals(1));
    String build = serialize(templates.child[0], compact: false);
    String dist = await File(resolve('template.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("view", () async {
    String filename = resolve('view.src.xml');
    String content = await File(filename).readAsString();
    Templates templates = parse(content, filename: filename);
    expect(templates.child.length, equals(1));
    String build = serialize(templates.child[0].child, compact: false);
    String dist = await File(resolve('view.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("rich", () async {
    String filename = resolve('rich.src.xml');
    String content = await File(filename).readAsString();
    Templates templates = parse(content, filename: filename);
    expect(templates.child.length, equals(1));
    String build = serialize(templates.child[0].child, compact: false);
    String dist = await File(resolve('rich.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("text", () async {
    String filename = resolve('text.src.xml');
    String content = await File(filename).readAsString();
    Templates templates = parse(content, filename: filename);
    expect(templates.child.length, equals(1));
    String build = serialize(templates.child[0].child, compact: false);
    String dist = await File(resolve('text.dist.xml')).readAsString();
    expect(build, equals(dist));
  });

  test("empty", () async {
    Templates templates = parse("\n\n\n");
    expect(templates.child.length, equals(0));
    String dist = serialize(templates, compact: false);
    expect(dist, equals('<templates/>'));
  });
}
