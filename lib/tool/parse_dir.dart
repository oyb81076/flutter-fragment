import 'dart:io';
import '../node.dart';
import '../xml/parse.dart';

Future<Templates> parseDir(String dir) async {
  var files = await Directory(dir).list(recursive: true, followLinks: false);
  Templates fragments = Templates();
  DateTime lastModified = null;
  Map<String, String> ids = Map();
  await files.where((event) => event.path.endsWith('.xml')).asyncMap((el) async {
    if (await FileSystemEntity.isFile(el.path)) {
      File file = File(el.path);
      var lm = await file.lastModified();
      String content = await file.readAsString();
      var fs = parse(content, filename: el.path, strictMode: true);
      if (fs.children.isEmpty) return;
      if (fs.children.length == 1) {
        if (fs.children[0].id == null) {
          fs.children[0].id = el.path
              .substring(dir.length + 1)
              .replaceFirst(RegExp(r'\..*$'), '');
        }
      } else {
        if (fs.children.every((element) => element.id == null)) {
          throw new Exception('多个片段写入一个文件的时候<fragment>必须指名id at ${el.path}');
        }
      }
      fs.children.forEach((fragment) {
        if (ids.containsKey(fragment.id)) {
          throw new Exception(
              '文件 ${file.path} 和 ${ids[fragment.id]} 片段ID重复: ${fragment.id}');
        }
        ids[fragment.id] = file.path;
      });
      fragments.children.addAll(fs.children);
      if (lastModified == null) {
        lastModified = lm;
      } else if (lastModified.isBefore(lastModified)) {
        lastModified = lm;
      }
    }
  }).last;
  if (lastModified != null) {
    fragments.lastModified = lastModified;
  }
  return fragments;
}