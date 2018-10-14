import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:tinano_generator/models/database.dart';
import '../utils.dart' as utils;

class BuildMethodParser {

	final ClassElement dbClass;

	BuildMethodParser(this.dbClass);

	StaticBuilderMethod parse() {
		// static DatabaseBuilder<MyDatabase> createBuilder() => $myBuilderName();
		final method = dbClass.getMethod("createBuilder");
		if (method == null) {
			utils.error(
					"The database class must have a static method called createBuilder. "
							"Consult the README from tinano for details",
					dbClass
			);
		}
		if (!method.isStatic) {
			utils.error("This method must be static", method);
		}

		if (method.parameters.isNotEmpty) {
			utils.error("This method must not have any parameters!", method);
		}

		// For class S, it must return a DatabaseBuilder<S>
		final expectedName = "DatabaseBuilder<${dbClass.displayName}>";
		if (method.returnType.displayName != expectedName) {
			utils.error("This method must return a DatabaseBuilder<${dbClass.displayName}>", method);
		}

		final body = method.computeNode().body;

		if (!(body is ExpressionFunctionBody)) {
			utils.error("This method must be an expression function (return with =>)", method);
		}

		final returnExpression = (body as ExpressionFunctionBody).expression;
		if (!(returnExpression is MethodInvocation)) {
			utils.error("This method must call a defined function databaseBuilder() => \$generatedFn()", method);
		}

		String generatorName = (returnExpression as MethodInvocation).methodName.name;

		if (!generatorName.startsWith("_\$")) {
			utils.error("The used function ($generatorName) must start with _\$", method);
		}

		return StaticBuilderMethod(method, generatorName);
	}

}