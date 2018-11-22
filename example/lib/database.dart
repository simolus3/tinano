import 'package:sqflite/sqflite.dart';
import 'package:tinano/tinano.dart';
import 'dart:async';

part 'database.g.dart';

@DatabaseInfo(name: "my_database.sqlite", schemaVersion: 1)
abstract class MyDatabase extends TinanoDatabase {

  static Future<MyDatabase> open() => _$openMyDatabase();

  @onCreate
  Future<void> _onDbCreated(Database database) async {
    await database.execute("""CREATE TABLE `todos` ( 
          `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          `content` TEXT NOT NULL 
        )""");
  }

  @OnUpgrade(from: 1, to: 2)
  Future<void> _onDbUpgraded(Database database) async {
    await database.execute("");
  }

  @Query("SELECT id, content FROM todos")
  Future<List<TodoEntry>> getTodoEntries();

  @Insert("INSERT INTO todos (content) VALUES (:content)")
  Future<int> createTodoEntryAndReturnId(String content);

  @Query("SELECT COUNT(id) FROM todos")
  Future<int> getAmountOfTodos();

  @Update("UPDATE todos SET content = :content WHERE id = :id")
  Future updateTodoText(int id, String content);

  @Delete("DELETE FROM todos WHERE id = :id")
  Future<bool> deleteTodoEntry(int id);

  @withTransaction
  Future<void> myTransaction(String test) async {
    await updateTodoText(1, test);
    await getAmountOfTodos();
  }
}

@row
class TodoEntry {
  final int id;
  final String content;

  @FromTable("test")
  final Test test;

  @FromTable("direct")
  final Test2 test2;

  TodoEntry(this.id, this.content, this.test, this.test2);
}

@row
class Test {

  final String name;
  @FromTable("test2")
  final Test2 nested;

  Test(this.name, this.nested);
}

@row
class Test2 {
  final String name;

  Test2(this.name);
}
