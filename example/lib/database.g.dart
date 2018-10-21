// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// TinanoGenerator
// **************************************************************************

Future<MyDatabase> _$openMyDatabase() async {
  final database = _$MyDatabaseImpl();
  database.onCreate = database._onDbCreated;
  database.migrations
      .add(SchemaMigrationWithVersion(database._onDbUpgraded, 1, 2));
  database.performOpenAndInitialize("my_database.sqlite", 1);
  return database;
}

class _$MyDatabaseImpl extends MyDatabase {
  @override
  MyDatabase copyWithExecutor(DatabaseExecutor db) {
    return _$MyDatabaseImpl()..database = db;
  }

  Future<List<TodoEntry>> getTodoEntries() async {
    String sql = "SELECT id, content FROM todos";

    final bindArgs = [];

    final rows = await database.rawQuery(sql, bindArgs);

    final parsedResults = new List<TodoEntry>();
    rows.forEach((row) {
      TodoEntry parsedRow =
          new TodoEntry(row["id"] as int, row["content"] as String, null);
      parsedResults.add(parsedRow);
    });
    return parsedResults;
  }

  Future<int> createTodoEntryAndReturnId(String content) async {
    String sql = "INSERT INTO todos (content) VALUES (?)";

    final bindParams_0 = content;

    final bindArgs = [bindParams_0];

    int lastInsertedRecordId = await database.rawInsert(sql, bindArgs);

    return lastInsertedRecordId;
  }

  Future<int> getAmountOfTodos() async {
    String sql = "SELECT COUNT(id) FROM todos";

    final bindArgs = [];

    final rows = await database.rawQuery(sql, bindArgs);

    final row = rows.first;
    int parsedRow = row.values.first as int;
    return parsedRow;
  }

  Future updateTodoText(int id, String content) async {
    String sql = "UPDATE todos SET content = ? WHERE id = ?";

    final bindParams_0 = id;
    final bindParams_1 = content;

    final bindArgs = [bindParams_1, bindParams_0];

    int affectedRows = await database.rawUpdate(sql, bindArgs);

    return affectedRows;
  }

  Future<bool> deleteTodoEntry(int id) async {
    String sql = "DELETE FROM todos WHERE id = ?";

    final bindParams_0 = id;

    final bindArgs = [bindParams_0];

    int affectedRows = await database.rawUpdate(sql, bindArgs);

    return affectedRows > 0;
  }

  @override
  Future<void> myTransaction(String test) {
    // If we're already in a transaction, call super function that performs the
    // actual logic (as defined by the user) directly.
    if (isInTransaction) {
      return super.myTransaction(test);
    } else {
      // Not in a transaction yet. We start a transaction, in which we create a
      // new object on which we call the function that should run in a
      // transaction. As that object will recognize it's in a transaction, it
      // will perform the logic directly.
      return doInTransaction((_$transaction) {
        final transactionDb = copyWithExecutor(_$transaction);

        return transactionDb.myTransaction(test);
      });
    }
  }
}
