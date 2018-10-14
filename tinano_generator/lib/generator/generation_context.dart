import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:tinano_generator/models/custom_types.dart';
import 'package:tinano_generator/parser/row_parser.dart';
import 'package:tinano_generator/utils.dart';

class GenerationContext {

  final Map<DartType, DefinedCustomType> knownCustomTypes = {};

  DefinedCustomType customTypeForDartType(DartType type) {
    return knownCustomTypes.putIfAbsent(type, () {
      final element = type.element as ClassElement;

      if (!RowTypeParser.shouldParse(element)) {
        error("This non-native type is returned by one of your queries, but it "
            "doesn't have the @row annotation!", element);
      }

      return RowTypeParser(element).parse();
    });
  }

}