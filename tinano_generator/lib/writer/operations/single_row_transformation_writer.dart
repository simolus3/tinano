import 'package:analyzer/dart/element/type.dart';
import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/custom_types.dart';
import 'package:tinano_generator/writer/writer.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;
import 'package:tinano_generator/utils.dart';

/// Given that there is a local variable named row containing a single row from
/// sqlite, writes a declaration to a variable named "parsedRow" that contains
/// the parsed data.
class SingleRowTransformationWriter extends Writer {
  final DartType targetType;
  final GenerationContext context;

  final String tablePrefix;
  final String localVariableSuffix;

  SingleRowTransformationWriter(
      this.targetType, this.context, StringBuffer target, int indent,
      [this.tablePrefix = "", this.localVariableSuffix = ""])
      : super(target, indent);

  String _castStmt(String expression, DartType targetType) {
    if (targetType.displayName == "int") {
      return "$expression as int";
    }
    if (targetType.displayName == "num") {
      return "$expression as num";
    }
    if (targetType.displayName == "String") {
      return "$expression as String";
    }
    if (targetType.displayName == "Uint8List") {
      return "$expression as Uint8List";
    }

    throw "Tinano does not now how to handlle this type: $targetType";
  }

  @override
  void write() {
    final localVarName = "parsedRow$localVariableSuffix";

    if (types.typeNativelySupported(targetType)) {
      String stmt = _castStmt("row.values.first", targetType);
      writeLineWithIndent("${targetType.displayName} $localVarName = $stmt;");
      return;
    }

    final customType = context.customTypeForDartType(targetType);
    final Map<CustomTypeField, String> customFieldsToLocalVars = {};

    // First, create local variables for all included rows which need to be
    // created. We map the field to the local variable created so that we can
    // resolve them later on.
    var i = 0;
    for (final field in customType.fields.whereType<CustomTypeField>()) {
      final includedVar = "$localVariableSuffix\_$i";
      new SingleRowTransformationWriter(field.dartType, context, target, indent,
          field.tablePrefix, includedVar).write();

      customFieldsToLocalVars[field] = "parsedRow$includedVar";
      i++;
    }

    String constructorParams = customType.fields.map((field) {
      if (field is SimpleFieldDefinition) {
        String columnName = field.sqlColumnName;
        if (tablePrefix != null && tablePrefix.isNotEmpty) {
          columnName = "$tablePrefix.$columnName";
        }

        String escapedColumn =
            escapeForDoubleQuoteConstant(columnName);

        return _castStmt("row[\"$escapedColumn\"]", field.type);
      } else if (field is CustomTypeField) {
        // The variable has already been created.
        return customFieldsToLocalVars[field];
      }
    }).join(", ");

    String targetName = targetType.displayName;
    writeLineWithIndent(
        "$targetName $localVarName = new $targetName($constructorParams);");
  }
}
