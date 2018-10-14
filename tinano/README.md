# tinano
Tinano is a local persistence library for flutter apps based on
[sqflite](https://pub.dartlang.org/packages/sqflite). While sqflite is an
awesome library to persist data, having to write all the parsing code yourself
is tedious and can become error-prone quickly. With Tinano, you specify the
queries and the data structures they return, and it will automatically take care
of all that manual and boring stuff, giving you a clean and type-safe way to
manage your app's data.

Table of Contents
=================
* [tinano](#tinano)
* [Getting Started](#getting-started)
  * [Setting up your project](#setting-up-your-project)
  * [Creating a database](#creating-a-database)
  * [Opening the database](#opening-the-database)
* [Database queries](#database-queries)
  * [Variables](#variables)
* [Schema updates](#schema-updates)
* [Supported types](#supported-types)
  * [For modifying statements (update / delete)](#for-modifying-statements-update--delete)
  * [For insert statements](#for-insert-statements)
  * [For select statements](#for-select-statements)
* [Accessing the raw database](#accessing-the-raw-database)
* [TO-DO list](#to-do-list)
* [Questions and feedback](#questions-and-feedback)


# Getting Started
### Setting up your project
First, let's prepare your `pubspec.yaml` to add this library and the tooling 
needed to automatically generate code based on your database definition:
```yaml
dependencies:
  tinano:
  # ...
dev_dependencies:
  tinano_generator:
  build_runner:
  # test, ...
```
The `tinano` library will provide some annotations for you to write your 
database classes, whereas the `tinano_generator` plugs into the `build_runner`
to generate the implementation. As we'll only do code-generation during 
development (and not at runtime), these two can be a dev-dependency.

### Creating a database
With Tinano, creating a database is simple:
```dart
import 'package:tinano/tinano.dart';
import 'dart:async';

part 'database.g.dart'; // this is important!

@TinanoDb(name: "my_database.sqlite", schemaVersion: 1)
abstract class MyDatabase {

  static DatabaseBuilder<MyDatabase> createBuilder() => _$createMyDatabase();

}
```
It is important that your database class is abstract and has a static 
method called `createBuilder` that uses the `=>` notation. The
`_$createMyDatabase()` method will be generated automatically later on. Of 
course, you're free to choose whatever name you want, but the method to create
the database has to start with `_$`.
Right now, this code will give us a bunch of errors because the implementation
has not been generated yet. A swift `flutter packages pub run build_runner build`
in the terminal will fix that. If you want to automatically rebuild your
database implementation every time you change the specification (might be useful
during development), you can use `flutter packages pub run build_runner watch`.

### Opening the database
To get an instance of your `MyDatabase`, you can just use the builder function
like this:
```dart
Future<MyDatabase> openMyDatabase() async {
  return await (MyDatabase
    .createBuilder()
    .doOnCreate((db, version) async {
      // This await is important, otherwise the database might be opened before
      // you're done with initializing it!
      await db.execute("""CREATE TABLE `users` ( `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL )""");
    })
    .build());
}
```
The `doOnCreate` block will be executed for the first time your database is 
opened. The `db` parameter will give you access to the raw sqflite database, the
`version` parameter is the schema version specified in your `@TinanoDb` annotation.
You can use the `addMigration` methods to do schema migrations - more info on
that below.

### Database queries
Of course, just opening the database is pretty boring. In order to actually 
execute some queries to the database, just create methods annotated with either
`@Query`, `@Update`, `@Delete` or `@Insert`. Here is an example that fits to
the `doOnCreate` method defined above:
```dart
@TinanoDb(name: "my_database.sqlite", schemaVersion: 1)
abstract class MyDatabase {
  static DatabaseBuilder<MyDatabase> createBuilder() => _$createMyDatabase();

  @Query("SELECT * FROM users")
  Future<List<UserRow>> getAllUsers();

  // If we know we'll only get one user, we can skip the List<>. Note that this
  // really expects there to be one row -> if there are 0, it will throw an
  // exception.
  @Query("SELECT * FROM users WHERE id = :id")
  Future<UserRow> getUserById(int id);

  // For queries with only one column that is either a String, a num or a
  // Uint8List, we don't have to define a new class.
  @Query("SELECT COUNT(id) FROM users")
  Future<int> getAmountOfUsers();

  // Inserts defined to return an int will return the insert id. Could also 
  // return nothing (Future<Null> or Future<void>) if we wanted.
  @Insert("INSERT INTO users (name) VALUES (:name)")
  Future<int> createUserWithName(String name);

  // Inserts return values based on their return type:
  // For Future<Null> or Future<void>, it won't return any value
  // For Future<int>, returns the amount of changed rows
  // For Future<bool>, checks if the amount of changed rows is greater than zero
  @Update("UPDATE users SET name = :updatedName WHERE id = :id")
  Future<bool> changeName(int id, String updatedName);

  // The behavior of deletes is identical to those of updates.
  @Delete("DELETE FROM users WHERE id = :id")
  Future<bool> deleteUser(int id);
}

// We have to annotate composited classes as @row. They should be immutable.
@row
class UserRow {

  final int id;
  final String name;

  UserRow(this.id, this.name);

}
```

#### Variables
As you can see, you can easily map the parameters of your method to sql 
variables by using the `:myVariable` notation directly in your sql. If you want
to use a `:` character in your SQL, that's fine, just escape them with a
backslash `\`. Note that you will have to use two of them (`"\\:"`) in your dart strings.

The variables will not be inserted into the query directly (which could easily
result in an sql injection vulnerability), but instead use prepared statements
to first send the sql without data, and then the variables. This means that you
won't be able to use variables for everything, see
[this](https://www.quora.com/What-are-the-limitations-of-PDO-prepared-statements-Can-I-define-the-table-and-row-as-arguments) for some examples where you can't.

### Schema updates
After bumping your version in `@TinanoDb`, you will have to perform some 
migrations manually. You can do this directly with your `DatabaseBuilder` by
using `addMigration`:
```dart
MyDatabase
  .createBuilder()
  .doOnCreate((db, version) {...})
  .addMigration(1, 2, (db) async {
	  await db.execute("ALTER TABLE ....")
  });
```
For bigger migrations (e.g. from 1 to 5), just specify all the migrations for
each step. Tinano will then apply them sequentially to ensure that the database
is ready before it's opened.

### Supported types
As the database access is asynchronous, all methods must return a `Future`.

#### For modifying statements (update / delete)
A `Future<int>` will resolve to the amount of updated rows, whereas a
`Future<bool>` as return type will resolve to `true` if there were any changes
and to `false` if not.
#### For insert statements
A `Future<int>` will resolve to the last inserted id. A `Future<bool>` will
always resolve to `true`, so using it is not recommended here.
#### For select statements
You'll have to use a `List<T>` if you want to receive all results, or just `T`
right away if you're fine with just receiving the first one. Notice that, in either
case, the entire response will be loaded into memory at some point, so please
set `LIMIT`s in your sql.  
Now, if your result is just going to have one column, you can use that type
directly:
```dart
@Query("SELECT COUNT(*) FROM users")
Future<int> getAmountOfUsers();
```
This will work for `int`, `num`, `Uint8List` and `String`. Please see the
[documentation from sqflite](https://github.com/tekartik/sqflite#supported-sqlite-types)
to check which dart types are compatible with which sqlite types.  
If your queries will return more than one column, you'll have to define it
in a new immutable class that must only have the unnamed constructor to set the fields:
```dart
@row
class UserResult {
  final int id;
  final String name;

  UserResult(this.id, this.name);
}

// this should be a method in your @TinanoDb class....
@Query("SELECT id, name FROM users")
Future<List<UserResult>> getBirthmonthDistribution();
```
Each `@row` class may only consist of the primitive fields `int`, `num`,
`Uint8List` and `String`.

# Accessing the raw database
If you want to use `Tinano`, but also have some use cases where you have to use
the `Database` from `sqflite` directly to send queries, you can just define a
field `Database database;` in your `@TinanoDb` class. It will be generated and
available after your database has been opened.

# TO-DO list
- It would be cool if we could get rid of `doOnCreate` and instead define these
  methods right in our database class with some more annotations. This can also
  apply to migration functions.
- Batches and transactions for improved performance and reliability.
- Auto-updating queries that return a `Stream` emitting new values as the
  underlying data changes. Could be similar to the [Room library](https://developer.android.com/topic/libraries/architecture/room)
  on Android.
- Supporting a `DateTime` right from the library, auto-generating code to store
  it as a timestamp in the database.
- Support `@row` classes that have other `@row` types as fields.
- Support for custom classes as variable parameters, specifying something like
  `WHERE id = :user.id` in your sql and then having a `User user` as a parameter.
- Being able to use different variable / column names for sql and dart types.
  Adding some annotations like `@FromColumn("my_column")`.

# Questions and feedback
This library is still in quite an early stage and will likely see some changes
on the way, so please feel free to open an issue if you have any feedback or
ideas for improvement.
Also, even though there are some awesome dart tools doing most of the work,
automatic code generation based on your database classes is pretty hard and 
there are a lot of edge-cases. So please, if you run into any weird issues or
unhelpful error messages during the build step, please do let me know so that I
can take a look at them. Thanks!
Of course, I greatly appreciate any PRs made to this library, but if you wankt to
implement some new features, please let me know first by creating an issue first.
That way, we can talk about how to approach that.
