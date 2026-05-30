import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_models.dart';

class PlayerRepository {
  final _db = AppDatabase.instance;

  Future<List<PlayerModel>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('t_player', orderBy: 'created_at DESC');
    return rows.map(PlayerModel.fromMap).toList();
  }

  Future<PlayerModel?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('t_player', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return PlayerModel.fromMap(rows.first);
  }

  Future<void> insert(PlayerModel player) async {
    final db = await _db.database;
    await db.insert('t_player', player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(PlayerModel player) async {
    final db = await _db.database;
    await db.update('t_player', player.toMap(),
        where: 'id = ?', whereArgs: [player.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('t_player', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> importAll(List<PlayerModel> players) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final p in players) {
      batch.insert('t_player', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
