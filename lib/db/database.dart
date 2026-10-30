import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/activity.dart';

/// SQLite storage for logged activities.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;

    // Desktop platforms have no native sqflite plugin. Initialize the FFI
    // factory immediately before the first database operation.
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    return _db = await openDatabase(
      join(await getDatabasesPath(), 'stride.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            minutes INTEGER NOT NULL,
            calories INTEGER NOT NULL,
            steps INTEGER NOT NULL DEFAULT 0
          )'''),
    );
  }

  Future<void> insert(Activity a) async =>
      (await _database).insert('activities', a.toMap()..remove('id'));

  Future<void> delete(int id) async =>
      (await _database).delete('activities', where: 'id = ?', whereArgs: [id]);

  Future<List<Activity>> all() async {
    final rows = await (await _database)
        .query('activities', orderBy: 'date DESC, id DESC');
    return rows.map(Activity.fromMap).toList();
  }
}
