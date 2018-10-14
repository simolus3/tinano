import 'package:tinano/tinano.dart';
import 'dart:async';

part 'database.g.dart';

@TinanoDb(name: "my_database.sqlite", schemaVersion: 1)
abstract class MyDatabase {

  static DatabaseBuilder<MyDatabase> createBuilder() => _$createMyDatabase();

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
}

Future<MyDatabase> openMyDatabase() async {
  return await (MyDatabase
    .createBuilder()
    .doOnCreate((db, version) async {
      await db.execute("""CREATE TABLE `todos` ( 
          `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          `content` TEXT NOT NULL 
        )""");
    })
    .build());
}

@row
class TodoEntry {

  final int id;
  final String content;

  TodoEntry(this.id, this.content);

}