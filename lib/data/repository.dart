import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'models.dart';

abstract class StateRepository {
  Future<AppData?> load();
  Future<void> save(AppData data);
}

class SqliteRepository implements StateRepository {
  Database? _database;
  Future<Database> get db async => _database ??= await openDatabase(
    path.join(await getDatabasesPath(), 'fluffs_sternenwelt_v4.db'),
    version: 1,
    onConfigure: (d) async {
      await d.rawQuery('PRAGMA journal_mode=WAL');
    },
    onCreate: (d, v) => d.execute(
      'CREATE TABLE state (id INTEGER PRIMARY KEY, data TEXT NOT NULL)',
    ),
  );
  @override
  Future<AppData?> load() async {
    final rows = await (await db).query('state', where: 'id=1');
    return rows.isEmpty
        ? null
        : AppData.fromJson(jsonDecode(rows.first['data'] as String));
  }

  @override
  Future<void> save(AppData data) async {
    final encoded = jsonEncode(data.toJson());
    await (await db).transaction(
      (d) => d.insert('state', {
        'id': 1,
        'data': encoded,
      }, conflictAlgorithm: ConflictAlgorithm.replace),
    );
  }
}

class MemoryRepository implements StateRepository {
  AppData? stored;
  bool fail = false;
  @override
  Future<AppData?> load() async => stored?.copy();
  @override
  Future<void> save(AppData data) async {
    if (fail) throw StateError('Speicherfehler');
    stored = data.copy();
  }
}
