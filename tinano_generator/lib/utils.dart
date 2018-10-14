import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

bool isDatabaseAnnotation(ElementAnnotation annotation) {
  return annotation.constantValue.type.displayName == "TinanoDb";
}

bool isActionAnnotation(ElementAnnotation annotation) {
  return ["Update", "Query", "Insert", "Delete"]
      .contains(annotation.constantValue.type.displayName);
}

@alwaysThrows
void error(String message, Element element) {
  throw InvalidGenerationSourceError(message, element: element);
}

String escapeForDoubleQuoteConstant(String val) {
  return val.replaceAll("\"", "\\\"");
}
