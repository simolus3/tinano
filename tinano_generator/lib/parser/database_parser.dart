import 'package:analyzer/dart/element/element.dart';
import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/models/database.dart';
import 'package:tinano_generator/parser/build_method_parser.dart';
import 'package:tinano_generator/parser/create_or_upgrade_parser.dart';
import 'package:tinano_generator/parser/operation_method_parser.dart';
import 'package:tinano_generator/parser/transaction_parser.dart';
import 'package:tinano_generator/utils/type_utils.dart' as types;
import '../utils.dart' as utils;

class DatabaseParser {
  ClassElement element;
  ElementAnnotation annotation;

  DefinedDatabase database;

  final GenerationContext _context;

  DatabaseParser._(this.element, this.annotation, this._context);

  static DatabaseParser forClass(
      ClassElement element, GenerationContext context) {
    final annotations = element.metadata;

    final dbAnnotations = annotations.where(types.isDatabaseAnnotation);

    if (dbAnnotations.isEmpty) {
      // Class is not annotated with @TinanoDb, ignore
      return null;
    }

    return DatabaseParser._(element, dbAnnotations.single, context);
  }

  void parse() {
    if (!element.isAbstract) {
      utils.error("Database classes must be abstract", element);
    }

    if (element.typeParameters.isNotEmpty) {
      utils.error("Database classes may not be generic", element);
    }

    if (element.supertype.displayName != "TinanoDatabase") {
      utils.error("Database classes must inherit from TinanoDatabase", element);
    }

    final annotationValue = annotation.computeConstantValue();
    String path = annotationValue.getField("name").toStringValue();
    int schema = annotationValue.getField("schemaVersion").toIntValue();

    database = DefinedDatabase();
    database.clazz = element;
    database.annotation = DatabaseAnnotation(path, schema, annotation);

    database.staticBuilder = BuildMethodParser(element).parse();

    for (final method in element.methods) {
      if (OperationMethodParser.shouldParseFor(method)) {
        database.operations
            .add(OperationMethodParser(method, _context).parse());
      }

      if (CreateOrUpgradeParser.shouldParse(method)) {
        CreateOrUpgradeParser(database, method).parse();
      }

      if (TransactionParser.shouldParseFor(method)) {
        TransactionParser(database, method).parse();
      }
    }
  }
}
