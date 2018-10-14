import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/writer/operations/reading_result_transformation.dart';
import 'package:tinano_generator/writer/operations/statement_execution_writer.dart';
import 'package:tinano_generator/writer/operations/variable_binding_writer.dart';
import 'package:tinano_generator/writer/operations/writing_result_transformation.dart';
import 'package:tinano_generator/writer/writer.dart';

class OperationWriter extends Writer {
  final DefinedOperation operation;
  final GenerationContext context;

  OperationWriter(this.operation, this.context, StringBuffer target, int indent)
      : super(target, indent);

  @override
  void write() {
    // First, create the correct method signature
    String returnType = operation.returnType.displayName;
    String methodName = operation.method.name;
    String parameters = "(" +
        operation.method.parameters.map((f) => f.toString()).join(", ") +
        ")";

    // Future<Int> updateTheDatabaseWhatever(String myParam, String another) {
    writeLineWithIndent("$returnType $methodName$parameters async {");

    VariableBindingWriter(operation, target, indent + 1).write();
    writeLn();
    StatementExecutionWriter(operation, target, indent + 1).write();
    writeLn();

    if (operation.type == StatementType.select) {
      ReadingResultTransformation(operation, context, target, indent + 1)
          .write();
    } else {
      WritingResultTransformation(operation, target, indent + 1).write();
    }

    writeLineWithIndent("}");
  }
}
