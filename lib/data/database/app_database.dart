import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';

/// SQLite 数据库管理
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static const _dbName = 'party_game.db';
  static const _dbVersion = 1;
  static const _uuid = Uuid();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE t_player (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nickname TEXT NOT NULL DEFAULT '',
        avatar_color INTEGER NOT NULL DEFAULT 4280391415,
        avatar_emoji TEXT NOT NULL DEFAULT '😀',
        created_at INTEGER NOT NULL,
        total_drinks INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE t_punishment_item (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        tag TEXT NOT NULL,
        difficulty TEXT NOT NULL DEFAULT 'mild',
        source TEXT NOT NULL DEFAULT 'custom',
        is_favorite INTEGER NOT NULL DEFAULT 0,
        use_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE t_wheel_template (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        options_json TEXT NOT NULL,
        is_built_in INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE t_game_session (
        id TEXT PRIMARY KEY,
        drink_mode TEXT NOT NULL DEFAULT 'immediate',
        status TEXT NOT NULL DEFAULT 'active',
        started_at INTEGER NOT NULL,
        ended_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE t_session_player (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        session_nickname TEXT NOT NULL,
        pending_cups INTEGER NOT NULL DEFAULT 0,
        avatar_color INTEGER NOT NULL DEFAULT 4280391415,
        avatar_emoji TEXT NOT NULL DEFAULT '😀',
        FOREIGN KEY (session_id) REFERENCES t_game_session(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE t_drink_record (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        nickname_snapshot TEXT NOT NULL,
        cups INTEGER NOT NULL,
        reason TEXT NOT NULL DEFAULT '',
        game_type TEXT NOT NULL DEFAULT '',
        timestamp INTEGER NOT NULL,
        is_undone INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE t_game_log (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        game_type TEXT NOT NULL,
        summary TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await _seedBuiltInData(db);
  }

  Future<void> _seedBuiltInData(Database db) async {
    try {
      final punishmentsJson =
          await rootBundle.loadString('assets/data/punishments.json');
      final punishments = jsonDecode(punishmentsJson) as List;
      for (final item in punishments) {
        final map = Map<String, dynamic>.from(item as Map);
        await db.insert('t_punishment_item', {
          'id': map['id'] ?? _uuid.v4(),
          'content': map['content'],
          'tag': map['tag'],
          'difficulty': map['difficulty'] ?? 'mild',
          'source': 'built_in',
          'is_favorite': 0,
          'use_count': 0,
        });
      }

      try {
        final extraJson =
            await rootBundle.loadString('assets/data/punishments_extra.json');
        final extra = jsonDecode(extraJson);
        final list = extra is List ? extra : [extra];
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          await db.insert('t_punishment_item', {
            'id': map['id'] ?? _uuid.v4(),
            'content': map['content'],
            'tag': map['tag'],
            'difficulty': map['difficulty'] ?? 'mild',
            'source': 'built_in',
            'is_favorite': 0,
            'use_count': 0,
          });
        }
      } catch (_) {}

      final wheelJson =
          await rootBundle.loadString('assets/data/wheel_presets.json');
      final wheels = jsonDecode(wheelJson) as List;
      for (final item in wheels) {
        final map = Map<String, dynamic>.from(item as Map);
        await db.insert('t_wheel_template', {
          'id': map['id'] ?? _uuid.v4(),
          'name': map['name'],
          'options_json': jsonEncode(map['options']),
          'is_built_in': 1,
        });
      }
    } catch (_) {
      // 内置数据加载失败时使用空库
    }
  }

  String generateId() => _uuid.v4();
}

/// 扩展 WheelTemplateModel 从 DB map
extension WheelTemplateFromDb on WheelTemplateModel {
  static WheelTemplateModel fromDbMap(Map<String, dynamic> map) {
    final optionsJson = jsonDecode(map['options_json'] as String) as List;
    return WheelTemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      options: optionsJson
          .map((e) => WheelOptionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isBuiltIn: (map['is_built_in'] as int? ?? 0) == 1,
    );
  }
}
