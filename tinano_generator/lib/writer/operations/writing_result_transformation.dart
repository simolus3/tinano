import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/utils.dart';
import 'package:tinano_generator/writer/writer.dart';

enum _TransformationBehavior {
  returnValueDirectly,
  checkIfValueGreaterThanZero,
  alwaysTrue
}

class WritingResultTransformation extends Writer {
  final DefinedOperation operation;

  WritingResultTransformation(this.operation, StringBuffer target, int indent)
      : super(target, indent);

  _TransformationBehavior get _behavior {
    final returnType = operation.returnTypeNoFuture;

    final canReturnDirectly = returnType.isDynamic ||
        returnType.element.library.isDartCore &&
            (returnType.displayName == "int" ||
                returnType.displayName == "num");

    if (canReturnDirectly) return _TransformationBehavior.returnValueDirectly;

    if (operation.type == StatementType.insert &&
        returnType.displayName == "bool") {
      // todo: How do we check if an insert was successful? Compare last insert
      // id before + after insert would not work in all cases?
      return _TransformationBehavior.alwaysTrue;
    }

    if (operation.type == StatementType.update &&
        returnType.displayName == "bool") {
      return _TransformationBehavior.checkIfValueGreaterThanZero;
    }

    error(
        "This library doesn't know how to return that type here. Please "
        "check the documentation of tinano for details.",
        operation.method);
  }

  @override
  void write() {
    final returnType = operation.returnTypeNoFuture;

    if (returnType.isDartCoreNull || returnType.isVoid) {
      // Method declaration forces us not to return anything -> done
      return;
    }

    String resultVarName = (operation.type == StatementType.insert)
        ? "lastInsertedRecordId"
        : "affectedRows";

    switch (_behavior) {
      case _TransformationBehavior.alwaysTrue:
        writeLineWithIndent("return true;");
        break;
      case _TransformationBehavior.checkIfValueGreaterThanZero:
        writeLineWithIndent("return $resultVarName > 0;");
        break;
      case _TransformationBehavior.returnValueDirectly:
        writeLineWithIndent("return $resultVarName;");
        break;
    }
  }
}
