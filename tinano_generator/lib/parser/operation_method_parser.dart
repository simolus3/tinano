import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/parser/sql_variable_analyzer.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;
import 'package:tinano_generator/utils.dart';

class OperationMethodParser {
  final MethodElement method;
  final GenerationContext context;

  OperationMethodParser(this.method, this.context);

  static bool shouldParseFor(MethodElement method) {
    final annotations =
        method.metadata.where(types.isActionAnnotation).toList();

    return annotations.isNotEmpty;
  }

  DefinedOperation parse() {
    final annotation = method.metadata.single.computeConstantValue();

    final annotationName = annotation.type.displayName;
    StatementType type;
    switch (annotationName) {
      case "Update":
      case "Delete":
        type = StatementType.update;
        break;
      case "Insert":
        type = StatementType.insert;
        break;
      case "Query":
        type = StatementType.select;
    }

    String sql = annotation.getField("(super)").getField("sql").toStringValue();

    if (!method.returnType.isDartAsyncFuture) {
      error("Database methods must return an async future", method);
    }
    if (method.isStatic) {
      error("Database methods may not be static", method);
    }
    if (method.typeParameters.isNotEmpty) {
      error("Database methods may not be generic", method);
    }
    if (!(method.computeNode().body is EmptyFunctionBody)) {
      error("Database methods may not have an implementation", method);
    }
    if (method.parameters.any((param) => param.isOptional)) {
      error("Parameters of database methods may not be optional or positional",
          method);
    }

    final sqlWithVars = SqlVariableAnalyzer(sql).sqlWithVars;

    final operation = DefinedOperation(type, sqlWithVars, method);

    final equality = SetEquality();
    final varsInSql = sqlWithVars.foundVariables;
    final parameters = operation.parameters.keys.toSet();

    if (!equality.equals(varsInSql, parameters)) {
      error(
          "The variables in your SQL do not match the parameters defined "
          "in your method. All method parameters need to show up in SQL, and "
          "vice-versa.\n"
          "These variables were found in your SQL: $varsInSql\n"
          "And these varaibles were in your method: $parameters",
          method);
    }

    final returnType = operation.returnTypeNoFutureOrList;
    if (type == StatementType.select &&
        !types.typeNativelySupported(returnType)) {
      // Parse & validate the return type if this didn't happen yet.
      context.customTypeForDartType(returnType);
    }

    return operation;
  }
}
