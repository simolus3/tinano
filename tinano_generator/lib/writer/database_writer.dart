import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/database.dart';
import 'package:tinano_generator/writer/operations/operations_writer.dart';
import 'package:tinano_generator/writer/operations/transaction_writer.dart';
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

        @override
        MyDatabase copyWithExecutor(DatabaseExecutor db) {
          return _$MyDatabaseImpl()..database = db;
        }
			}
		 */

    final originalClassName = database.clazz.displayName;
    final implClassName = database.nameOfImplementationClass;

    writeLineWithIndent(
        "class $implClassName extends $originalClassName {");

    // Implementation for copyWithExecutor(DatabaseExecutor)
    writeLineWithIndent("@override", 1);
    writeLineWithIndent("$originalClassName copyWithExecutor(DatabaseExecutor db) {", 1);
    writeLineWithIndent("return $implClassName()..database = db;", 2);
    writeLineWithIndent("}", 1);

    for (final operation in database.operations) {
      OperationWriter(operation, context, target, indent + 1).write();
    }

    for (final transaction in database.transactionMethods) {
      TransactionWriter(transaction, target,  indent + 1).write();
    }

    writeLineWithIndent("}");
  }
}
