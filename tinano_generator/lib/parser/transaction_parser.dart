import 'package:analyzer/dart/element/element.dart';
import 'package:tinano_generator/models/database.dart';
import 'package:tinano_generator/models/operation.dart';
import 'package:tinano_generator/utils.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;

class TransactionParser {

  final MethodElement _method;
  final DefinedDatabase database;

  static bool shouldParseFor(MethodElement method) {
    final annotations =
      method.metadata.where(types.isTransactionAnnotation).toList();

    return annotations.isNotEmpty;
  }

  TransactionParser(this.database, this._method);

  void parse() {
    _method.parameters.forEach(_checkInvalidParameter);

    if (_method.typeParameters.isNotEmpty) {
      error("@WithTransaction methods may not be generic", _method);
    }

    database.transactionMethods.add(DefinedTransaction(_method));
  }

  _checkInvalidParameter(ParameterElement param) {
    if (param.name.startsWith("_\$")) {
      error("The name of the parameter may not start with _\$", param);
    }

    if (param.isOptional) {
      error("Optional parameters are not supported yet", param);
    }
  }

}
