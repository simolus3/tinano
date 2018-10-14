import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/writer/writer.dart';

class StatementExecutionWriter extends Writer {
  final DefinedOperation operation;

  StatementExecutionWriter(this.operation, StringBuffer target, int indent)
      : super(target, indent);

  @override
  void write() {
    switch (operation.type) {
      case StatementType.insert:
        writeLineWithIndent(
            "int lastInsertedRecordId = await database.rawInsert(sql, bindArgs);");
        break;
      case StatementType.select:
        writeLineWithIndent(
            "final rows = await database.rawQuery(sql, bindArgs);");
        break;
      case StatementType.update:
        writeLineWithIndent(
            "int affectedRows = await database.rawUpdate(sql, bindArgs);");
        break;
    }
  }
}
