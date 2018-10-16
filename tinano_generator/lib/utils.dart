import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

@alwaysThrows
void error(String message, Element element) {
  throw InvalidGenerationSourceError(message, element: element);
}

String escapeForDoubleQuoteConstant(String val) {
  return val.replaceAll("\"", "\\\"");
}
