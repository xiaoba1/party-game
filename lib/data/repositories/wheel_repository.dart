import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_models.dart';

class WheelRepository {
  final _db = AppDatabase.instance;

  Future<List<WheelTemplateModel>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('t_wheel_template', orderBy: 'is_built_in DESC, name ASC');
    return rows.map(WheelTemplateFromDb.fromDbMap).toList();
  }

  Future<WheelTemplateModel?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('t_wheel_template', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WheelTemplateFromDb.fromDbMap(rows.first);
  }

  Future<void> save(WheelTemplateModel template) async {
    final db = await _db.database;
    await db.insert(
      't_wheel_template',
      {
        'id': template.id,
        'name': template.name,
        'options_json': jsonEncode(template.options.map((e) => e.toJson()).toList()),
        'is_built_in': template.isBuiltIn ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('t_wheel_template',
        where: 'id = ? AND is_built_in = 0', whereArgs: [id]);
  }
}
