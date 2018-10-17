import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/writer/writer.dart';

class TransactionWriter extends Writer {

  final DefinedTransaction _transaction;

  TransactionWriter(this._transaction, StringBuffer target, int indent) : super(target, indent);

  @override
  void write() {
    // End result may look like this:
    // We include the comments in the generated code so that if the user wants
    // to debug it, they have a better chance of understanding what's going on.

    /*
    @override
    Future<void> myTransaction(String someParameter) {
      // If we're already in a transaction, call super function that performs the
      // actual logic (as defined by the user) directly.
      if (isInTransaction) {
        return super.myTransaction(someParameter);
      } else {
        // Not in a transaction yet. We start a transaction, in which we create a
        // new object on which we call the function that should run in a
        // transaction. As that object will recognize it's in a transaction, it
        // will perform the logic directly.
        return doInTransaction((_$transaction) {
          final transactionDb = copyWithExecutor(_$transaction);

          return transactionDb.myTransaction(someParameter);
        });
      }
    }
     */

    final method = _transaction.method;
    final returnType = method.returnType.displayName;
    final name = method.name;
    final parameters = method.parameters;
    final parameterDeclaration = parameters
        .map((param) => param.toString()).join(", ");
    final parameterUsage = parameters.map((param) => param.name).join(", ");

    writeLineWithIndent("@override");
    writeLineWithIndent("$returnType $name($parameterDeclaration) {");
    writeLineWithIndent("// If we're already in a transaction, call super function that performs the", 1);
    writeLineWithIndent("// actual logic (as defined by the user) directly.", 1);
    writeLineWithIndent("if (isInTransaction) {", 1);
    writeLineWithIndent("return super.$name($parameterUsage);", 2);
    writeLineWithIndent("} else {", 1);
    writeLineWithIndent("// Not in a transaction yet. We start a transaction, in which we create a", 2);
    writeLineWithIndent("// new object on which we call the function that should run in a", 2);
    writeLineWithIndent("// transaction. As that object will recognize it's in a transaction, it", 2);
    writeLineWithIndent("// will perform the logic directly.", 2);
    writeLineWithIndent("return doInTransaction((_\$transaction) {", 2);
    writeLineWithIndent("final transactionDb = copyWithExecutor(_\$transaction);", 3);
    writeLn();
    writeLineWithIndent("return transactionDb.$name($parameterUsage);", 3);
    writeLineWithIndent("});", 2);
    writeLineWithIndent("}", 1);
    writeLineWithIndent("}");
  }

}