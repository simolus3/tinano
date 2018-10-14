import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class DefinedCustomType {
  final ClassElement definition;
  final LinkedHashMap<String, DartType> types;

  DefinedCustomType(this.definition, this.types);
}
