import 'package:analyzer/dart/element/element.dart';
import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/custom_types.dart';
import 'package:tinano_generator/utils.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;

class RowTypeParser {
  final ClassElement element;
  final GenerationContext context;

  RowTypeParser(this.element, this.context);

  static bool shouldParse(ClassElement element) {
    return element.metadata.any(types.isRowAnnotation);
  }

  DefinedCustomType parse() {
    final constructor = element.constructors.single;
    final fields = List<FieldDefinition>();

    constructor.parameters.forEach((param) {
      final field = _findFieldForConstructorParam(param);
      final customColumnName = _getCustomColumnNameOrNull(field);

      if (!types.typeNativelySupported(param.type)) {
        final tableName = _getTableNameOrNull(field);

        if (tableName != null) {
          final typeCanBeIncluded = shouldParse(field.type.element);

          if (typeCanBeIncluded) {
            if (customColumnName != null) {
              error("Cannot use @FromColumn and @FromTable on the same field!",
              field);
            }

            // TODO Check and disallow circular references
            // (will throw a StackOverflowError at build time for now)
            final type = context.customTypeForDartType(field.type);
            fields.add(CustomTypeField(param.name, tableName, type));
            return;
          } else {
            error("You tried to include another @row type here. However, the "
                "type referenced here is not annotated with @row. Please "
                "either fix the type to be an @row or check the README from "
                "tinano if you have questions on how to use this annotation.",
                field);
          }
        } else {
          error(
              "That type is not supported. Please check the documentation of"
              "tinano for the list of supported types.",
              field);
        }
      }

      fields.add(SimpleFieldDefinition(param.name, customColumnName, param.type));
    });

    return DefinedCustomType(element, fields);
  }

  FieldElement _findFieldForConstructorParam(ParameterElement param) {
    return element.fields.singleWhere((field) => field.name == param.name);
  }

  String _getCustomColumnNameOrNull(FieldElement field) {
    final fromColumnAnnotation = field.metadata
        .where(types.isFromColumnAnnotation);

    String customColumnName = null;
    if (fromColumnAnnotation.isNotEmpty) {
      customColumnName = fromColumnAnnotation.first.constantValue.getField("column").toStringValue();
    }

    return customColumnName;
  }

  String _getTableNameOrNull(FieldElement field) {
    final fromTableAnnotation = field.metadata
        .where((types.isFromTableAnnotation));

    String customTableName = null;
    if (fromTableAnnotation.isNotEmpty) {
      customTableName = fromTableAnnotation.first.constantValue.getField("table").toStringValue();
    }

    return customTableName;
  }
}
