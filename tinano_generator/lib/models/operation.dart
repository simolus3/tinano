import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:tinano_generator/parser/sql_variable_analyzer.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;

enum StatementType {
	select,
  /// also includes delete
	update,
	insert
}

class DefinedOperation {

	final StatementType type;
	final SqlWithVariables sql;
	final MethodElement method;

	DartType get returnType => method.returnType;
	DartType get returnTypeNoFuture => returnType.flattenFutures(method.context.typeSystem);

	DartType get returnTypeNoFutureOrList {
		var type = returnTypeNoFuture;

		if (types.isList(type)) {
			type = types.flattenedList(type);
		}

		return type;
	}

	Map<String, DartType> get parameters {
	  final paramWithTypes = Map<String, DartType>();

	  for (final param in method.parameters) {
      paramWithTypes[param.name] = param.type;
    }

    return paramWithTypes;
  }

  DefinedOperation(this.type, this.sql, this.method);

}