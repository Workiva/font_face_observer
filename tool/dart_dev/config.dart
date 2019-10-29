import 'package:dart_dev/dart_dev.dart';

final config = {
  ...coreConfig,
  'format': FormatTool()..formatter = Formatter.dartStyle,
};

