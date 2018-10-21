import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

/// Annotation for your database classes to provide the name of the database in
/// the file system and the current schema version.
class DatabaseInfo {
  // note: When performing refactorings of this class, also adapt usages in
  // generator (defined_database.dart).

  /// The filename of this database.
  final String name;
  final int schemaVersion;

  const DatabaseInfo({@required this.name, this.schemaVersion = 1});
}

class OnCreate {
  const OnCreate._();
}

/// Annotation for a method in your database class that will be invoked when
/// the database is created for the first time. The method must return a
/// `Future<void>` that completes after the initialization has been completed.
/// It must have one parameter of the type [Database]. An example might look
/// like this:
/// ```
/// @onCreate
/// Future<void> _onDbCreated(Database db) {
///   await db.execute("""CREATE TABLE `todos` (
///          `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
///          `content` TEXT NOT NULL
///        )""");
/// }
/// ```
const onCreate = OnCreate._();

/// Annotation for a method in your database class that will be invoked when the
/// database performs a version upgrade (that is, in your [DatabaseInfo], you
/// increased the [DatabaseInfo.schemaVersion] and re-run your app). Tinano will
/// figure out which schema upgrade methods to call in which order. The method
/// must return a `Future<void>` and it must have one parameter of the type
/// [Database]. An example might look like this:
/// ```
/// @OnUpgrade(from: 1, to: 2)
/// Future<void> _dbUpgraded1_2(Database db) {
///   await db.execute("ALTER TABLE ...");
/// }
/// ```
class OnUpgrade {

  /// The schema version from which we can perform the upgrade
  final int from;
  /// The schema version after this upgrade (migration) has been applied.
  final int to;

  const OnUpgrade({@required this.from, @required this.to});

}

class Row {
  const Row._();
}

/// Use the row annotation to mark non-primitive data structures that can be
/// returned by one of your queries. Check the readme of tinano for details on
/// how to use this class exactly.
const row = Row._();

/// By default, the name of a field on your @row classes is also the column name
/// tinano expects to find when parsing a response from your queries.
/// However, sometimes this means that you'd have to put "... AS simpleName" in
/// your sql queries to match that constraint. With this annotation that can be
/// used on a field in your @row classes, you can instruct the tinano generator
/// to instead use the specified column. This can be helpful when you're parsing
/// some queries that called sql functions:
/// ```
/// // works with "SELECT name, COUNT(id) FROM users GROUP BY name"
/// @row
/// class DistributionOfNames {
///   final String name;
///   @FromColumn("COUNT(id)")
///   final int amount;
///
///   DistributionOfNames(this.name, this.amount);
/// }
/// ```
class FromColumn {
  final String column;

  const FromColumn(this.column);
}

class FromTable {

  final String table;

  const FromTable(this.table);

}

class WithTransaction {
  const WithTransaction._();
}

/// Annotation to use on a method in a tinano database class to ensure that all
/// database methods called in the body of the annotated method should operate
/// on a transaction.
/// An example might look like this:
/// ```
/// // ...
/// abstract class MyDatabase extends TinanoDatabase {
///
///   @Update("...")
///   Future myFirstUpdate();
///   @Delete("...")
///   Future myFirstDelete();
///
///   @withTransaction
///   Future updateAndDeleteAtomically() async {
///     // These will now operate on a transaction!
///     await myFirstUpdate();
///     await myFirstDelete();
///   }
/// }
/// ```
/// Please be aware of the following limitations in this API:
/// 1. The code inside the method annotated with `@withTransaction` will be
///    called on a different object of your database class. tinano will create
///    an new instance of it that does not use the regular database but instead
///    the transaction.
///    This also means that you should not put custom logic into your database
///    classes (e.g. defining custom fields etc.) as your database object might
///    be re-created.
/// 2. There will be a deadlock when using transactions and the regular database
///    interchangeably. This should not be possible with the regular tinano APIs,
///    but it can happen when you're using the database from sqflite directly.
const withTransaction = WithTransaction._();

abstract class DatabaseAction {
  final String sql;

  const DatabaseAction(this.sql);
}

class Update extends DatabaseAction {
  const Update(String sql) : super(sql);
}

class Delete extends DatabaseAction {
  const Delete(String sql) : super(sql);
}

class Insert extends DatabaseAction {
  const Insert(String sql) : super(sql);
}

class Query extends DatabaseAction {
  const Query(String sql) : super(sql);
}
