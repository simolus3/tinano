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

  SingleRowTransformationWriter(
      this.targetType, this.context, StringBuffer target, int indent)
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

    return "oh no, something went wrong";
  }

  @override
  void write() {
    if (types.typeNativelySupported(targetType)) {
      String stmt = _castStmt("row.values.first", targetType);
      writeLineWithIndent("${targetType.displayName} parsedRow = $stmt;");
      return;
    }

    final customType = context.customTypeForDartType(targetType);
    String constructorParams = customType.fields
      .map((field) {
        if (field is SimpleFieldDefinition) {
          String escapedColumn = escapeForDoubleQuoteConstant(field.sqlColumnName);

          return _castStmt("row[\"$escapedColumn\"]", field.type);
        }

        // TODO Handle rows referencing other rows.
      })
      .join(", ");

    String targetName = targetType.displayName;
    writeLineWithIndent(
        "$targetName parsedRow = new $targetName($constructorParams);");
  }
}
