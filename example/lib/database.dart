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

  @Query("SELECT COUNT(id) F ROM todos")
  Future<int> getAmountOfTodos();

  @Update("UPDATE todos SET content = :content WHERE id = :id")
  Future updateTodoText(int id, String content);

  @Delete("DELETE FROM todos WHERE id = :id")
  Future<bool> deleteTodoEntry(int id);
}

@row
class TodoEntry {
  final int id;
  final String content;

  TodoEntry(this.id, this.content);
}
