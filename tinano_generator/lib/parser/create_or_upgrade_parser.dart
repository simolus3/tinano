import 'package:analyzer/dart/element/element.dart';
import 'package:tinano_generator/models/database.dart';
import 'package:tinano_generator/utils.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;

/// Parser that parses @onCreate or @OnUpgrade(from: x, to: y) methods.
class CreateOrUpgradeParser {
  final DefinedDatabase db;
  final MethodElement method;

  CreateOrUpgradeParser(this.db, this.method);

  static bool shouldParse(MethodElement method) {
    return method.metadata
        .where((a) =>
            types.isOnCreateAnnotation(a) || types.isOnUpgradeAnnotation(a))
        .isNotEmpty;
  }

  void parse() {
    final metadata = method.metadata
        .singleWhere((a) =>
          types.isOnCreateAnnotation(a) || types.isOnUpgradeAnnotation(a));

    _verifyMethodHasCorrectParameters();
    _verifyCorrectReturnType();

    if (method.isStatic || method.isAbstract) {
      error("This method may neither be static or abstract", method);
    }

    if (types.isOnCreateAnnotation(metadata)) {
      if (db.onCreateMethod != null) {
        error("You have more than one method annotated with @onCreate! in this class", db.clazz);
      }

      db.onCreateMethod = OnCreateMethod(method, metadata);
    } else if (types.isOnUpgradeAnnotation(metadata)) {
      final from = metadata.constantValue.getField("from").toIntValue();
      final to = metadata.constantValue.getField("to").toIntValue();

      if (to <= from) {
        error("The to version must be bigger than the from version!", method);
      }

      db.migrationMethods.add(OnUpgradeMethod(method, metadata, from, to));
    }
  }

  void _verifyCorrectReturnType() {
    if (method.returnType.displayName != "Future<void>") {
      error("This method must return a Future<void>", method);
    }
  }

  void _verifyMethodHasCorrectParameters() {
    if (method.parameters.length != 1) {
      error("This method may only have one parameter, which must be a database", method);
    }

    if (method.typeParameters.isNotEmpty) {
      error("This method may not be generic", method);
    }
  }
}
