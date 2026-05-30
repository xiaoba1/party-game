import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_models.dart';

class SessionRepository {
  final _db = AppDatabase.instance;

  Future<GameSessionModel?> getActiveSession() async {
    final db = await _db.database;
    final rows = await db.query('t_game_session',
        where: 'status = ?', whereArgs: ['active'], limit: 1);
    if (rows.isEmpty) return null;
    return GameSessionModel.fromMap(rows.first);
  }

  Future<GameSessionModel?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('t_game_session', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return GameSessionModel.fromMap(rows.first);
  }

  Future<List<GameSessionModel>> getHistory() async {
    final db = await _db.database;
    final rows = await db.query('t_game_session',
        where: 'status = ?', whereArgs: ['ended'], orderBy: 'started_at DESC');
    return rows.map(GameSessionModel.fromMap).toList();
  }

  Future<void> createSession(GameSessionModel session) async {
    final db = await _db.database;
    await db.insert('t_game_session', session.toMap());
  }

  Future<void> endSession(String sessionId) async {
    final db = await _db.database;
    await db.update(
      't_game_session',
      {'status': 'ended', 'ended_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<SessionPlayerModel>> getSessionPlayers(String sessionId) async {
    final db = await _db.database;
    final rows = await db.query('t_session_player',
        where: 'session_id = ?', whereArgs: [sessionId]);
    return rows.map(SessionPlayerModel.fromMap).toList();
  }

  Future<void> addSessionPlayer(SessionPlayerModel player) async {
    final db = await _db.database;
    await db.insert('t_session_player', player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSessionPlayer(SessionPlayerModel player) async {
    final db = await _db.database;
    await db.update('t_session_player', player.toMap(),
        where: 'id = ?', whereArgs: [player.id]);
  }

  Future<void> updatePlayerNickname(
    String sessionPlayerId,
    String nickname,
  ) async {
    final db = await _db.database;
    await db.update(
      't_session_player',
      {'session_nickname': nickname},
      where: 'id = ?',
      whereArgs: [sessionPlayerId],
    );
  }

  Future<void> updatePendingCups(String sessionPlayerId, int cups) async {
    final db = await _db.database;
    await db.update(
      't_session_player',
      {'pending_cups': cups},
      where: 'id = ?',
      whereArgs: [sessionPlayerId],
    );
  }

  Future<void> insertDrinkRecord(DrinkRecordModel record) async {
    final db = await _db.database;
    await db.insert('t_drink_record', record.toMap());
  }

  Future<void> markRecordUndone(String recordId) async {
    final db = await _db.database;
    await db.update(
      't_drink_record',
      {'is_undone': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<DrinkRecordModel?> getLastRecord(String sessionId) async {
    final db = await _db.database;
    final rows = await db.query(
      't_drink_record',
      where: 'session_id = ? AND is_undone = 0',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DrinkRecordModel.fromMap(rows.first);
  }

  Future<List<DrinkRecordModel>> getSessionRecords(String sessionId) async {
    final db = await _db.database;
    final rows = await db.query('t_drink_record',
        where: 'session_id = ? AND is_undone = 0',
        whereArgs: [sessionId],
        orderBy: 'timestamp DESC');
    return rows.map(DrinkRecordModel.fromMap).toList();
  }

  Future<void> insertGameLog({
    required String sessionId,
    required String gameType,
    required String summary,
  }) async {
    final db = await _db.database;
    await db.insert('t_game_log', {
      'id': _db.generateId(),
      'session_id': sessionId,
      'game_type': gameType,
      'summary': summary,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getGameLogs(String sessionId) async {
    final db = await _db.database;
    return db.query('t_game_log',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp DESC');
  }
}
