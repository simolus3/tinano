import 'package:analyzer/dart/element/type.dart';
import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/writer/writer.dart';
import 'package:tinano_generator/utils.dart' as utils;

class VariableBindingWriter extends Writer {

  final DefinedOperation operation;

  VariableBindingWriter(this.operation, StringBuffer buffer, int indent) : super(buffer, indent);

  String _localVariableNameAt(int i) => "bindParams_$i";

  String _codeToConvertParameterToString(String paramName, DartType type) {
    // no need to convert it to string, as it turns out. sqflite will figure
    // that out for us.
    return "$paramName";
  }

  @override
  void write() {
    // Store the sql in a local variable
    String rawSql = utils.escapeForDoubleQuoteConstant(operation.sql.updatedSql);
    writeLineWithIndent("String sql =  \"$rawSql\";");
    writeLn();

    // Next, convert all the parameters to a string and store that in local vars
    var currentLocalVariable = 0;
    // reference which variable found in the sql corresponds to which local
    // variable we're about to generate.
    final Map<String, int> sqlVarNameToLocalIndex = {};

    operation.parameters.forEach((name, type) {
      final localVarName = _localVariableNameAt(currentLocalVariable);
      final expression = _codeToConvertParameterToString(name, type);
      writeLineWithIndent("final $localVarName = $expression;");

      sqlVarNameToLocalIndex[name] = currentLocalVariable;
      currentLocalVariable++;
    });

    // Now that we have all the local variables in their place, create the array
    // which we're going to pass to sqflite
    writeLn();

    String bindArrayContents = operation.sql.variablesWithPosition
      .map((variableName) {
        final localIndex = sqlVarNameToLocalIndex[variableName];
        return _localVariableNameAt(localIndex);
      })
      .join(", ");

    writeLineWithIndent("final bindArgs = [$bindArrayContents];");
  }
}