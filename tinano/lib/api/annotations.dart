import 'package:meta/meta.dart';

class TinanoDb {

	// note: When performing refactorings of this class, also adapt usages in
	// generator (defined_database.dart).

	/// The filename of this database.
	final String name;
	final int schemaVersion;

	const TinanoDb({@required this.name, this.schemaVersion = 1});

}

class Row {

  const Row._();

}

const row = Row._();

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
