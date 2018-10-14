import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:tinano_generator/models/custom_types.dart';
import 'package:tinano_generator/utils.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;

class RowTypeParser {

  final ClassElement element;

  RowTypeParser(this.element);

  static bool shouldParse(ClassElement element) {
    return element.metadata.any(types.isRowAnnotation);
  }

  DefinedCustomType parse() {
    final constructor = element.constructors.single;
    final definedTypes = LinkedHashMap<String, DartType>();

    constructor.parameters.forEach((param) {
      if (!types.typeNativelySupported(param.type)) {
        error("That type is not supported. Please check the documentation of"
            "tinano for the list of supported types.", element);
      }

      definedTypes[param.name] = param.type;
    });

    return DefinedCustomType(element, definedTypes);
  }

}