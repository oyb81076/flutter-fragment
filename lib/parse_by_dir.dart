import 'dart:io';
import 'xml.dart';

Future<Fragments> parseByDirectory(String dir) async {
  var files = await Directory(dir).list(recursive: true, followLinks: false);
  Fragments fragments = Fragments();
  DateTime lastModified = null;
  Map<String, String> ids = Map();
  await files.asyncMap((el) async {
    if (await FileSystemEntity.isFile(el.path)) {
      File file = File(el.path);
      var lm = await file.lastModified();
      String content = await file.readAsString();
      var fs = parse(content, filename: el.path);
      if (fs.child.isEmpty) return;
      if (fs.child.length == 1) {
        if (fs.child[0].id == null) {
          fs.child[0].id = el.path
              .substring(dir.length + 1)
              .replaceFirst(RegExp(r'\..*$'), '');
        }
      } else {
        if (fs.child.every((element) => element.id == null)) {
          throw new Exception('多个片段写入一个文件的时候<fragment>必须指名id at ${el.path}');
        }
      }
      fs.child.forEach((fragment) {
        if (ids.containsKey(fragment.id)) {
          throw new Exception(
              '文件 ${file.path} 和 ${ids[fragment.id]} 片段ID重复: ${fragment.id}');
        }
        ids[fragment.id] = file.path;
      });
      fragments.child.addAll(fs.child);
      if (lastModified == null) {
        lastModified = lm;
      } else if (lastModified.isBefore(lastModified)) {
        lastModified = lm;
      }
    }
  }).toList();
  if (lastModified != null) {
    fragments.lastModified = lastModified.toIso8601String();
  }
  return fragments;
}
