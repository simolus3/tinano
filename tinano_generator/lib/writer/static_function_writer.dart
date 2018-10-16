import 'package:tinano_generator/models/database.dart';
import 'package:tinano_generator/writer/writer.dart';

class StaticFunctionWriter extends Writer {
  final DefinedDatabase database;

  StaticFunctionWriter(this.database, StringBuffer target, int indent)
      : super(target, indent);

  @override
  void write() {
    // The final function might look like this:
    //
    //  Future<MyDatabase> _$openMyDatabase() async {
    //    final database = _$MyDatabaseImpl();
    //    database.onCreate = database._onDbCreated;
    //    database.migrations.add(SchemaMigrationWithVersion(database._onDbUpgraded, 1, 2));
    //
    //    await database.performOpenAndInitialize("my_database.sqlite", 2);
    //    return database;
    //  }

    final generator = database.staticBuilder;
    final methodName = generator.nameOfReferencedImplName;
    final returnTypeName = generator.method.returnType.displayName;
    final implClassName = database.nameOfImplementationClass;
    final definedPath = database.annotation.path;
    final definedSchemaVersion = database.annotation.schemaVersion;

    // First, write the function header: Future<MyDatabase> _$myFnName() async {
    writeLineWithIndent("$returnTypeName $methodName() async {");

    writeLineWithIndent("final database = $implClassName();", 1);
    // Set initialization function
    if (database.onCreateMethod != null) {
      final onCreateName = database.onCreateMethod.method.displayName;
      writeLineWithIndent("database.onCreate = database.$onCreateName;", 1);
    }

    // Set migration functions
    for (final upgradeMethod in database.migrationMethods) {
      final onUpgradeName = upgradeMethod.method.displayName;
      final from = upgradeMethod.from;
      final to = upgradeMethod.to;

      writeLineWithIndent("database.migrations.add(SchemaMigrationWithVersion(database.$onUpgradeName, $from, $to));");
    }

    // Call performAndInitialize with parameters from annotation
    writeLineWithIndent("database.performOpenAndInitialize(\"$definedPath\", $definedSchemaVersion);");

    writeLineWithIndent("return database;");

    // Finish the method by closing the curly bracket
    writeLineWithIndent("}");
  }
}
