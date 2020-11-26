export 'node/base.dart';
export 'node/image.dart';
export 'node/rich.dart';
export 'node/span.dart';
export 'node/template.dart';
export 'node/templates.dart';
export 'node/image.dart';
export 'node/text.dart';
export 'node/view.dart';

import 'node/base.dart';
import 'node/image.dart';
import 'node/rich.dart';
import 'node/span.dart';
import 'node/template.dart';
import 'node/templates.dart';
import 'node/text.dart';
import 'node/view.dart';

bool isValidRalation(String parentTagName, String childTagName) {
  if (childTagName == 'span') {
    return parentTagName == 'rich';
  } else if (parentTagName == 'rich') {
    return childTagName == 'span';
  } else {
    return true;
  }
}

final Map<String, Node Function()> tags = {
  'image': () => Image(),
  'view': () => View(),
  'text': () => Text(),
  'template': () => Template(),
  'templates': () => Templates(),
  'span': () => Span(),
  'rich': () => Rich(),
};

