import 'package:path/path.dart' as p;
import 'dart:io';

String resolve(String path) {
  String filename;
  if (Platform.script.scheme == 'file') {
    filename = Platform.script.toFilePath();
  } else {
    filename =
        RegExp(r'file:///(.*\.dart)').stringMatch(Platform.script.toString()).substring(7);
  }
  return p.join(p.dirname(filename), path);
}