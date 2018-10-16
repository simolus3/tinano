import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/database.dart';
import 'package:tinano_generator/writer/operations/operations_writer.dart';
import 'package:tinano_generator/writer/static_function_writer.dart';
import 'package:tinano_generator/writer/writer.dart';

class DatabaseWriter extends Writer {
  final DefinedDatabase database;
  final GenerationContext context;

  DatabaseWriter(this.database, this.context, StringBuffer target)
      : super(target, 0);

  @override
  void write() {
    // First, write the static generator function
    StaticFunctionWriter(database, target, indent).write();

    /*
			class _$MyDatabaseImpl extends MyDatabase {
				// all the generated methods will turn up here
			}
		 */

    final originalClassName = database.clazz.displayName;
    final implClassName = database.nameOfImplementationClass;

    writeLineWithIndent(
        "class $implClassName extends $originalClassName {");

    for (final operation in database.operations) {
      OperationWriter(operation, context, target, indent + 1).write();
    }

    writeLineWithIndent("}");
  }
}
