import 'dart:async';

import 'package:flutter/material.dart';
// This file only contains UI code, the real magic happens in database.dart
import 'package:tinano_example/database.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Tinano Demo',
      theme: new ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new MyHomePage(title: 'Tinano Todo example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// We use the database right here because this state is going to be active
  /// all the time and we only use the database right here. This isn't a good
  /// architecture, but it will have to do for this simple example.
  /// For your apps, you can define your database in your top-level widget (the
  /// one you start with runApp(...)) and then make it an InheritedWidget so
  /// that you can get access to your database everywhere. See
  /// https://medium.com/@mehmetf_71205/inheriting-widgets-b7ac56dbbeb1 for some
  /// details.
  /// This still wouldn't be a clean architecture, but it ensures that you will
  /// only have one database open at the same time. The exact steps depend on
  /// what kind of libraries you use for architecture.
  MyDatabase _database;
  StreamController<List<TodoEntry>> todoEntries =
      new StreamController.broadcast();

  TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Just execute some async function, we ignore the return values here. This
    // is not nice, but for our example it will do.
    () async {
      _database = await MyDatabase.open();
      await _updateTodosFromDb();
    }();
  }

  Future<void> _updateTodosFromDb() async {
    if (_database != null) {
      todoEntries.add(await _database.getTodoEntries());
    }
  }

  void _addTodoFromTextField() {
    final userTodoText = _editController.text.trim();

    if (userTodoText.isNotEmpty) {
      _editController.clear();
      _database
          .createTodoEntryAndReturnId(userTodoText)
          .whenComplete(_updateTodosFromDb);
    }
  }

  void _deleteTodoEntry(TodoEntry delete) {
    _database.deleteTodoEntry(delete.id).whenComplete(_updateTodosFromDb);
  }

  @override
  void dispose() {
    super.dispose();

    todoEntries.close();
  }

  @override
  Widget build(BuildContext context) {
    final title = Center(
        child: Text(
      "Your open todos",
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headline,
    ));

    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title), actions: [
        IconButton(
            icon: Icon(Icons.info),
            onPressed: () => showLicensePage(context: context))
      ]),
      body: StreamBuilder(
        stream: todoEntries.stream,
        builder: (ctx, AsyncSnapshot<List<TodoEntry>> snapshot) {
          if (snapshot.hasData) {
            final entries = snapshot.data
                .map((entry) => TodoListWidget(entry, _deleteTodoEntry));
            // Display all todo entries and the header in a list
            return ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              children: <Widget>[title].followedBy(entries).toList(),
            );
          } else {
            // If the database hasn't been opened yet, show a circular loading
            // spinner in the middle of the body.
            return Container(
                constraints: BoxConstraints.expand(),
                alignment: Alignment.center,
                child: CircularProgressIndicator());
          }
        },
      ),
      // At the bottom, display a bar where the user can add another todo entry
      bottomSheet: Material(
          color: Colors.white70,
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: TextField(
                      controller: _editController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          InputDecoration(labelText: "What needs to be done?")),
                ),
                FloatingActionButton(
                    onPressed: _addTodoFromTextField, child: Icon(Icons.add))
              ]))),
    );
  }
}

typedef Callback<T> = void Function(T arg);

class TodoListWidget extends StatelessWidget {
  final TodoEntry _entry;
  final Callback<TodoEntry> _onDeleted;

  TodoListWidget(this._entry, this._onDeleted)
      : super(key: ObjectKey(_entry.id));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Text(_entry.content)),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _onDeleted(_entry),
        )
      ]),
    );
  }
}
