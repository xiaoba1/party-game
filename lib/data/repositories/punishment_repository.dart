import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_models.dart';

class PunishmentRepository {
  final _db = AppDatabase.instance;

  Future<List<PunishmentModel>> getAll({String? tag, String? difficulty}) async {
    final db = await _db.database;
    String? where;
    List<dynamic>? whereArgs;
    if (tag != null) {
      where = 'tag = ?';
      whereArgs = [tag];
      if (difficulty != null) {
        where += ' AND difficulty = ?';
        whereArgs.add(difficulty);
      }
    } else if (difficulty != null) {
      where = 'difficulty = ?';
      whereArgs = [difficulty];
    }
    final rows = await db.query('t_punishment_item',
        where: where, whereArgs: whereArgs, orderBy: 'use_count DESC');
    return rows.map(PunishmentModel.fromMap).toList();
  }

  Future<List<PunishmentModel>> getFavorites() async {
    final db = await _db.database;
    final rows = await db.query('t_punishment_item',
        where: 'is_favorite = 1', orderBy: 'use_count DESC');
    return rows.map(PunishmentModel.fromMap).toList();
  }

  Future<PunishmentModel?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('t_punishment_item', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return PunishmentModel.fromMap(rows.first);
  }

  Future<PunishmentModel?> getRandom({String? tag}) async {
    final all = await getAll(tag: tag);
    if (all.isEmpty) return null;
    all.shuffle();
    return all.first;
  }

  Future<void> insert(PunishmentModel item) async {
    final db = await _db.database;
    await db.insert('t_punishment_item', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(PunishmentModel item) async {
    final db = await _db.database;
    await db.update('t_punishment_item', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('t_punishment_item',
        where: 'id = ? AND source = ?', whereArgs: [id, 'custom']);
  }

  Future<void> incrementUseCount(String id) async {
    final db = await _db.database;
    await db.rawUpdate(
        'UPDATE t_punishment_item SET use_count = use_count + 1 WHERE id = ?',
        [id]);
  }

  Future<void> importAll(List<PunishmentModel> items) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final item in items) {
      if (item.source == 'custom') {
        batch.insert('t_punishment_item', item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }
}
