import 'package:analyzer/dart/element/element.dart';
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
    final fields = List<FieldDefinition>();

    constructor.parameters.forEach((param) {
      FieldElement field = _findFieldForConstructorParam(param);

      if (!types.typeNativelySupported(param.type)) {
        error(
            "That type is not supported. Please check the documentation of"
            "tinano for the list of supported types.",
            element);
      }

      final fromColumnAnnotation = field.metadata
          .where(types.isFromColumnAnnotation);

      String customColumnName = null;
      if (fromColumnAnnotation.isNotEmpty) {
        customColumnName = fromColumnAnnotation.first.constantValue.getField("column").toStringValue();
      }

      fields.add(SimpleFieldDefinition(param.name, customColumnName, param.type));
    });

    return DefinedCustomType(element, fields);
  }

  FieldElement _findFieldForConstructorParam(ParameterElement param) {
    return element.fields.singleWhere((field) => field.name == param.name);
  }
}
