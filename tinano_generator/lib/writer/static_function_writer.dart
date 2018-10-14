import 'package:tinano_generator/models/database.dart';
import 'package:tinano_generator/writer/writer.dart';

class StaticFunctionWriter extends Writer {
  final DefinedDatabase database;

  StaticFunctionWriter(this.database, StringBuffer target, int indent)
      : super(target, indent);

  @override
  void write() {
    final generator = database.staticBuilder;
    final methodName = generator.nameOfReferencedImplName;
    final implClassName = database.nameOfImplementationClass;
    final definedPath = database.annotation.path;
    final definedSchemaVersion = database.annotation.schemaVersion;

    // DatabaseBuilder<MyFancyDatabase> _$myReferencedMethod() {
    writeLineWithIndent(
        "${generator.method.returnType.displayName} $methodName() {");
    // return new DatabaseBuilder(new _MyFancyDatabaseImpl(), "my_db.sqlite", 3)
    writeLineWithIndent(
        "return new DatabaseBuilder(new $implClassName(), \"$definedPath\", $definedSchemaVersion);",
        1);
    writeLineWithIndent("}");
  }
}
