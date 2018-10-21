import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';

class DefinedCustomType {
  final ClassElement definition;

  final List<FieldDefinition> fields;

  DefinedCustomType(this.definition, this.fields);
}

@immutable
abstract class FieldDefinition {

  final String dartFieldName;

  FieldDefinition(this.dartFieldName);
}

/// A field definition that references a single column that maps to a simple
/// dart type (num, String, Uint8List).
class SimpleFieldDefinition extends FieldDefinition {

  /// If the user instructed that this field shall be parsed from a sql column
  /// with a name that is different to [dartFieldName], stores that name.
  /// Otherwise null.
  final String customColumnName;

  final DartType type;

  String get sqlColumnName => customColumnName ?? dartFieldName;

  SimpleFieldDefinition(String dartFieldName, this.customColumnName, this.type) :
        super(dartFieldName);
}

/// A field that references another custom type.
class CustomTypeField extends FieldDefinition {

  final String tablePrefix;

  final DefinedCustomType type;

  DartType get dartType => type.definition.type;

  CustomTypeField(String dartFieldName, this.tablePrefix, this.type) : super(dartFieldName);

}