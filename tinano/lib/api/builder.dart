import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

typedef SchemaMigration(Database);

class GeneratedDatabaseImpl {

	Database database;

}

class _SchemaMigrationWithVersions {

	int from;
	int to;
	SchemaMigration fn;

	_SchemaMigrationWithVersions(this.from, this.to, this.fn);

}

class DatabaseBuilder<T> {

	final T _scaffold;
	final String _name;
	final int _schemaVersion;

	final List<_SchemaMigrationWithVersions> _migrations = [];
	OnDatabaseCreateFn _onCreate;

	DatabaseBuilder(this._scaffold, this._name, this._schemaVersion);

	DatabaseBuilder doOnCreate(OnDatabaseCreateFn fn) {
		_onCreate = fn;
		return this;
	}

	DatabaseBuilder addMigration(int from, int to, SchemaMigration migration) {
		if (to > _schemaVersion) {
			throw ArgumentError("Tried to provide a migration that goes above the "
					"version specified in the @TinanoDb annotation");
		}

		if (from == to) {
			throw ArgumentError("Tried to provide a migration with same from and "
				"to version");
		}

		_migrations.add(_SchemaMigrationWithVersions(from, to, migration));
		return this;
	}

	Future<T> build() async {
		final path = await getDatabasesPath();
		final dbPath = join(path, _name);

		final database = await openDatabase(
			dbPath,
			version: _schemaVersion,
			onCreate: _onCreate,
			onUpgrade: (db, old, updated) {
				var currentVersion = old;

				do {
					currentVersion = _performSchemaUpgrade(currentVersion, db);
				} while (currentVersion != _schemaVersion);
			}
		);

		if (_scaffold is GeneratedDatabaseImpl) {
			(_scaffold as GeneratedDatabaseImpl).database = database;
		}

		return _scaffold;
	}

	/// Performs a schema upgrade from the current version to the highest version
	/// for which we have direct update available.
	int _performSchemaUpgrade(int current, Database db) {
		final usableMigrations = _migrations
			..sort((a, b) => a.to.compareTo(b.to))
			..where((x) => x.from == current);

		if (usableMigrations.isEmpty) {
			throw StateError("No migration to upgrade from $current");
		}

		final migration = usableMigrations.last;
		migration.fn(db);

		return migration.to;
	}
}