import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/writer/operations/single_row_transformation_writer.dart';
import 'package:tinano_generator/writer/writer.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;

class ReadingResultTransformation extends Writer {

  DefinedOperation operation;
  GenerationContext context;

  ReadingResultTransformation(this.operation, this.context, StringBuffer buffer, int indent) : super(buffer, indent);

  @override
  void write() {
    if (types.isList(operation.returnTypeNoFuture)) {
      final targetType = operation.returnTypeNoFutureOrList;

      // = new List<MyCustomReturnType>();
      writeLineWithIndent("final parsedResults = new "
          " ${operation.returnTypeNoFuture.displayName}();");

      writeLineWithIndent("rows.forEach((row) {");

      new SingleRowTransformationWriter(targetType, context, target, indent + 1).write();
      writeLineWithIndent("parsedResults.add(parsedRow);");

      writeLineWithIndent("});");
      writeLineWithIndent("return parsedResults;");
    } else {
      writeLineWithIndent("final row = rows.first;");
      new SingleRowTransformationWriter(operation.returnTypeNoFuture, context, target, indent).write();
      writeLineWithIndent("return parsedRow;");
    }
  }

}