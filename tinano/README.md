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
* [Table of contents](#table-of-contents)
* [Getting Started](#getting-started)
  * [Setting up your project](#setting-up-your-project)
  * [Creating a database](#creating-a-database)
  * [Opening the database](#opening-the-database)
* [Database queries](#database-queries)
  * [Variables](#variables)
  * [Transactions](#transactions)
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
import 'package:sqflite/sqflite.dart';
import 'dart:async';

part 'database.g.dart'; // this is important!

@DatabaseInfo(name: "my_database.sqlite", schemaVersion: 1)
abstract class MyDatabase extends TinanoDatabase {

  static Future<MyDatabase> open() => _$openMyDatabase();
  
  @onCreate
  Future<void> _onDatabaseCreated(Database db) async {
    // Here, we can initialize our table structure. 
    await db.execute("""CREATE TABLE `users` ( `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `user_name` TEXT NOT NULL )""");
  }

}
```
Let's quickly go through that file and see what's going on: First, we import
the `tinano` and the `sqflite` libraries as we'll use them to access the
database. We also define the `part 'database.g.dart';` (name depends on the 
name you choose for your dart file, just replace `dart` with `g.dart`).
That statement allows the generator from tinano to create a new source file
that is treated like it belongs to the source file you've written, but
without having to mess around with your code.
We define a database class by inheriting from `TinanoDatabase`. Don't worry,
we can pass the responsibility to implement the methods to tinano and
define it as `abstract`. The Database class must have the `@DatabaseInfo`
annotation so that tinano knows where your database file should be and which
schema version you want to use.

In order to open the database, we define a static `open` method which returns
a `Future<MyDatabase>`. It is important that the method is written down
exactly like that, it won't be recognized by the tinano generator otherwise.
Of course, you can still name your database whatever you want, but a class
called `S` has to have a function `open` that returns a `Future<S>`.
Also, you'll have to use the `=> _$myOpenFunction();` syntax, although you're
free to chose the name here (anything starting with `_$` will do).

The `@onCreate` function, must take a `Database` as a parameter and return a
`Future<void>`. It will be invoked by tinano for the first time your database
is created in the file system. You can use it to initialize your table structure
or populate some data. we'll use a very similar syntax to perform schema updates
later on - see [schema updates](#schema-updates) for details.

Right now, this source code will give us a bunch of errors. That is because the
implementation has not been generated yet. As we use the `build_runner` package,
doing that just requires a swift `flutter packages pub run build_runner build`
on the command line. If you want to continuously update the generated code when
the source code changes, `flutter packages pub run build_runner watch` is your
friend.

### Opening the database
Now that we have everything defined, opening the database is simple:
```dart
MyDatabase database = await MyDatabase.open();
```
You might wonder where to put this code. I can't give a solution that fit's
every use case here, but here is a suggestion that I hope is easy to adapt
to most use-cases:
1.  Make the topmost widget in your tree (the one you create in `runApp(...)`) stateful.
2. Now, you can use a `FutureBuilder` in `build(BuildContext context)` to build
   the correct widget tree based on whether the database is available or not, with
   the future being `MyDatabase.open()`.
   You might want to show a splash screen if the database is not available yet
   and show the regular app if it is.
3. Use an  [`InheritedWidget`](https://docs.flutter.io/flutter/widgets/InheritedWidget-class.html)
   to pass the database you created down the widget tree, so that it only needs to
   be created once.

I know that this isn't exactly simple, but it allows you to just use one database
for the lifecycle of your app. If you have questions on this or suggestions on how
to improve this, please feel free to [create an issue](https://github.com/simolus3/tinano/issues/new).

### Database queries
Of course, just opening the database is pretty boring. In order to actually 
execute some queries to the database, just create methods annotated with either
`@Query`, `@Update`, `@Delete` or `@Insert`. Here is an example that fits to
the `@onCreate` method defined above:
```dart
@DatabaseInfo(name: "my_database.sqlite", schemaVersion: 1)
abstract class MyDatabase extends TinanoDatabase {
  static Future<MyDatabase> open() => _$createMyDatabase();

  @onCreate
  Future<void> onDatabaseCreated(Database db) async { /* ... */ }

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

// We have to annotate composite classes as @row. They should be immutable.
@row
class UserRow {

  final int id; // will read the id column from sql, names must match!
  @FromColumn("user_name")
  final String name; // will read the user_name column from sql

  UserRow(this.id, this.name);

}
```
As you've seen, using the `@FromColumn` annotation allows you to specify from which
sql column the field will be read from. If the column and the field names match, the
`@FromColumn` declaration can be omitted.

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

Your variables will be converted to strings before being handled by sqlite, which
means that, in theory, you can use every type for your variables. However, only
`String`, `int`, `num` and `bool` have been tested and are known to work well.

#### Transactions
You can get a special instance of your database by defining a method with
`@withTransaction`: Whenever that method is called, the body that you defined
will run within a transaction that commits after the `Future` returned by the
method was resolved.
```dart
@withTransaction
Future<bool> createAndChangeName(String originalName, String updatedName) async {
  var id = await createUserWithName(originalName);
  await changeName(id, updatedName);
}
```  on Android.
- Support for custom classes as variable parameters, specifying something like

Notice that, to make this work, tinano will create a __new instance__ of
your database class, call the transactional method on it, and then go back
to the original instance. This means that, if you have any custom fields defined
in your database class, these will not be available in a transaction method.
It is generally recommended to keep every logic that is not strictly needed
for database access out of the database class. Check out the generated code
for your transaction method if you need details.

### Schema updates
After bumping your version in `@DatabaseInfo`, you will have to perform some 
migrations manually. You can do this directly in your database classes by 
annotating a method with `@OnUpgrade`.
```dart
@OnUpgrade(from: 1, to: 2)
Future<void> _handleUpgradeFrom1To2(Database database) async {
  await database.execute("ALTER TABLE users ...");
}
```
For each schema update `n` to `n + 1`, it is recommended to add an `@OnUpgrade`
method handling that update specifically. If the user skips some updates of your
app and has to go from, for example, schema 1 to 5 directly, the tinano library
will call the updates for `1 -> 2`, `2 -> 3`, `3 -> 4`, `4 -> 5` sequentially, so
there is no need to cover every possible combination of `from`s and `to`s with
their own upgrade method.
Note that schema downgrades are not supported.

### Supported types
As the database access is asynchronous, all methods must return a `Future`.
What types are supported exactly depends on your queries:

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
This will work for `int`, `num`, `Uint8List`, `String` and `bool`. Please see the
[documentation from sqflite](https://github.com/tekartik/sqflite#supported-sqlite-types)
to check which dart types are compatible with which sqlite types.
Note that `bool`s are not supported by sqflite directly, they are a convenience 
feature provided by tinano. They must be stored as an integer in sqflite. Then,
every nonzero value will be treated as `true`, and 0 will be treated as `false`.  
If your queries will return more than one column, you'll have to define it
in a new immutable class that must only have the unnamed constructor to set the fields:
```dart
@row
class UserResult {
  final int id;
  final String name;

  UserResult(this.id, this.name);
}

// this should be a method in your TinanoDatabase class....
@Query("SELECT id, name FROM users")
Future<List<UserResult>> getUsers();
```
Each `@row` class may only consist of the primitive fields `int`, `num`,
`Uint8List` and `String`. Each field in the row class will be read from the
sql result based on it's name.

# Accessing the raw database
If you want to use `Tinano`, but also have some use cases where you have to use
the `Database` from `sqflite` directly to send queries, you can just use the
field `database` defined in `TinanoDatabase`. This field will be initialized
after the database is opened, so you can't use it in your `@onCreate` or
`@OnUpgrade` methods (but you shouldn't need to, as you get the database as a
parameter).

# TO-DO list
Roughly sorted by descending priority. If you have any suggestions, please go ahead and
[open an issue](https://github.com/simolus3/tinano/issues/new).

- Support a non-default constructor for `@row` classes. 
- Support a `DateTime` right from the library, auto-generating code to store
  it as a timestamp in the database.
- Auto-updating queries that return a `Stream` emitting new values as the
  underlying data changes. Could be similar to the [Room library](https://developer.android.com/topic/libraries/architecture/room)
  on Android.
- Support for custom classes as variable parameters, specifying something like
  `WHERE id = :user.id` in your sql and then having a `User user` as a parameter.
- Batches

# Questions and feedback
This library is still in quite an early stage and will likely see some changes
on the way, so please feel free to open an issue if you have any feedback or
ideas for improvement. If there is anything in this README that doesn't make
sense to you, please do let me know with an issue so that I can clarify and
improve the documentation.

Also, even though there are some awesome dart tools doing most of the work,
automatic code generation based on your database classes is pretty hard and 
there are a lot of edge-cases. So please, if you run into any weird issues or
unhelpful error messages during the build step, please do let me know so that I
can take a look at what's wrong. Thanks!

Of course, I greatly appreciate any PRs made to this library, but if you want to
implement some major new features, please let me know by creating an issue first.
That way, we can talk about how to approach that. Thanks!
