import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

bool isDartCore(DartType type) => type.element.library.isDartCore;

bool isList(DartType type) {
	return type.name == "List" && isDartCore(type);
}

DartType flattenedList(DartType list) {
	return (list as ParameterizedType).typeArguments.first;
}

bool typeNativelySupported(DartType type) {
  return (type.element.library.isDartCore &&
      ["bool", "num", "int", "String"].contains(type.displayName)) ||
    type.displayName == "Uint8List";
}

// TODO We should check the library here? What if there was another library
// using these class names?
bool isDatabaseAnnotation(ElementAnnotation annotation) {
	return annotation.constantValue.type.displayName == "TinanoDb";
}

bool isRowAnnotation(ElementAnnotation annotation) {
	return annotation.computeConstantValue().type.displayName == "Row";
}

bool isActionAnnotation(ElementAnnotation annotation) {
	return ["Update", "Query", "Insert", "Delete"].contains(annotation.constantValue.type.displayName);
}