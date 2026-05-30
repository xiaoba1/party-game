import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_enums.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/app_models.dart';
import '../../room/providers/room_provider.dart';

/// 当前聚会会话状态
class SessionState {
  const SessionState({
    this.session,
    this.players = const [],
    this.drinkMode = DrinkCountMode.immediate,
    this.records = const [],
  });

  final GameSessionModel? session;
  final List<SessionPlayerModel> players;
  final DrinkCountMode drinkMode;
  final List<DrinkRecordModel> records;

  bool get isActive => session != null && session!.status == 'active';

  SessionState copyWith({
    GameSessionModel? session,
    List<SessionPlayerModel>? players,
    DrinkCountMode? drinkMode,
    List<DrinkRecordModel>? records,
  }) {
    return SessionState(
      session: session ?? this.session,
      players: players ?? this.players,
      drinkMode: drinkMode ?? this.drinkMode,
      records: records ?? this.records,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this.ref) : super(const SessionState()) {
    _loadActiveSession();
  }

  final Ref ref;
  final _db = AppDatabase.instance;

  Future<void> _loadActiveSession() async {
    final repo = ref.read(sessionRepositoryProvider);
    final session = await repo.getActiveSession();
    if (session == null) return;

    final players = await repo.getSessionPlayers(session.id);
    final records = await repo.getSessionRecords(session.id);
    state = SessionState(
      session: session,
      players: players,
      drinkMode: session.drinkMode == 'cumulative'
          ? DrinkCountMode.cumulative
          : DrinkCountMode.immediate,
      records: records,
    );
  }

  Future<void> startSession({
    required List<PlayerModel> selectedPlayers,
    DrinkCountMode drinkMode = DrinkCountMode.immediate,
  }) async {
    final repo = ref.read(sessionRepositoryProvider);
    final sessionId = _db.generateId();
    final session = GameSessionModel(
      id: sessionId,
      drinkMode: drinkMode.name,
      status: 'active',
      startedAt: DateTime.now(),
    );
    await repo.createSession(session);

    final sessionPlayers = <SessionPlayerModel>[];
    for (final p in selectedPlayers) {
      final sp = SessionPlayerModel(
        id: _db.generateId(),
        sessionId: sessionId,
        playerId: p.id,
        sessionNickname: p.displayName,
        pendingCups: 0,
        avatarColor: p.avatarColor,
        avatarEmoji: p.avatarEmoji,
      );
      await repo.addSessionPlayer(sp);
      sessionPlayers.add(sp);
    }

    state = SessionState(
      session: session,
      players: sessionPlayers,
      drinkMode: drinkMode,
      records: [],
    );
  }

  Future<void> addPlayerToSession(PlayerModel player) async {
    if (!state.isActive) return;
    final repo = ref.read(sessionRepositoryProvider);
    final sp = SessionPlayerModel(
      id: _db.generateId(),
      sessionId: state.session!.id,
      playerId: player.id,
      sessionNickname: player.displayName,
      pendingCups: 0,
      avatarColor: player.avatarColor,
      avatarEmoji: player.avatarEmoji,
    );
    await repo.addSessionPlayer(sp);
    state = state.copyWith(players: [...state.players, sp]);
  }

  Future<void> updateNickname({
    required String sessionPlayerId,
    required String newNickname,
    bool sessionOnly = false,
  }) async {
    final repo = ref.read(sessionRepositoryProvider);
    await repo.updatePlayerNickname(sessionPlayerId, newNickname);

    final updatedPlayers = state.players.map((p) {
      if (p.id == sessionPlayerId) {
        return p.copyWith(sessionNickname: newNickname);
      }
      return p;
    }).toList();

    state = state.copyWith(players: updatedPlayers);

    if (!sessionOnly) {
      final sp = updatedPlayers.firstWhere((p) => p.id == sessionPlayerId);
      final playerRepo = ref.read(playerRepositoryProvider);
      final player = await playerRepo.getById(sp.playerId);
      if (player != null) {
        await playerRepo.update(player.copyWith(nickname: newNickname));
      }
    }

    // 联机同步昵称变更
    final room = ref.read(roomProvider);
    if (room.isConnected) {
      if (room.isHost) {
        ref.read(roomProvider.notifier).broadcastNicknameUpdate(
              sessionPlayerId,
              newNickname,
            );
      } else if (room.clientChannel != null) {
        room.clientChannel!.sink.add(
          '{"type":"player_nickname_updated","payload":{"sessionPlayerId":"$sessionPlayerId","nickname":"$newNickname","sessionOnly":$sessionOnly}}',
        );
      }
    }
  }

  Future<DrinkRecordModel?> applyPenalty({
    required String sessionPlayerId,
    required int cups,
    required String reason,
    required String gameType,
    bool skip = false,
  }) async {
    if (!state.isActive || skip) {
      if (skip) {
        await ref.read(sessionRepositoryProvider).insertGameLog(
              sessionId: state.session!.id,
              gameType: gameType,
              summary: '跳过惩罚: $reason',
            );
      }
      return null;
    }

    final repo = ref.read(sessionRepositoryProvider);
    final player = state.players.firstWhere((p) => p.id == sessionPlayerId);
    final record = DrinkRecordModel(
      id: _db.generateId(),
      sessionId: state.session!.id,
      playerId: player.playerId,
      nicknameSnapshot: player.sessionNickname,
      cups: cups,
      reason: reason,
      gameType: gameType,
      timestamp: DateTime.now(),
    );

    if (state.drinkMode == DrinkCountMode.immediate) {
      // 直和模式：记录但不累加 pending（直接扣减概念 - 记录已喝）
      await repo.insertDrinkRecord(record);
      await repo.insertGameLog(
        sessionId: state.session!.id,
        gameType: gameType,
        summary: '${player.sessionNickname} 喝了 $cups 杯 - $reason',
      );
    } else {
      // 累计模式：累加 pending
      final newPending = player.pendingCups + cups;
      await repo.updatePendingCups(sessionPlayerId, newPending);
      await repo.insertDrinkRecord(record);
      final updatedPlayers = state.players.map((p) {
        if (p.id == sessionPlayerId) {
          return p.copyWith(pendingCups: newPending);
        }
        return p;
      }).toList();
      state = state.copyWith(players: updatedPlayers);
      await repo.insertGameLog(
        sessionId: state.session!.id,
        gameType: gameType,
        summary: '${player.sessionNickname} 累计 +$cups 杯 - $reason',
      );
    }

    final records = await repo.getSessionRecords(state.session!.id);
    state = state.copyWith(records: records);
    return record;
  }

  Future<void> settleDrinks(String sessionPlayerId, int cupsToSettle) async {
    if (!state.isActive) return;
    final repo = ref.read(sessionRepositoryProvider);
    final player = state.players.firstWhere((p) => p.id == sessionPlayerId);
    final newPending = (player.pendingCups - cupsToSettle).clamp(0, 999);
    await repo.updatePendingCups(sessionPlayerId, newPending);

    final record = DrinkRecordModel(
      id: _db.generateId(),
      sessionId: state.session!.id,
      playerId: player.playerId,
      nicknameSnapshot: player.sessionNickname,
      cups: cupsToSettle,
      reason: '结算喝酒',
      gameType: 'settle',
      timestamp: DateTime.now(),
    );
    await repo.insertDrinkRecord(record);

    final updatedPlayers = state.players.map((p) {
      if (p.id == sessionPlayerId) {
        return p.copyWith(pendingCups: newPending);
      }
      return p;
    }).toList();

    final records = await repo.getSessionRecords(state.session!.id);
    state = state.copyWith(players: updatedPlayers, records: records);
  }

  Future<bool> undoLastRecord() async {
    if (!state.isActive) return false;
    final repo = ref.read(sessionRepositoryProvider);
    final last = await repo.getLastRecord(state.session!.id);
    if (last == null) return false;

    await repo.markRecordUndone(last.id);

    if (state.drinkMode == DrinkCountMode.cumulative) {
      final sp = state.players.firstWhere(
        (p) => p.playerId == last.playerId,
        orElse: () => state.players.first,
      );
      final newPending = (sp.pendingCups - last.cups).clamp(0, 999);
      await repo.updatePendingCups(sp.id, newPending);
      final updatedPlayers = state.players.map((p) {
        if (p.id == sp.id) return p.copyWith(pendingCups: newPending);
        return p;
      }).toList();
      final records = await repo.getSessionRecords(state.session!.id);
      state = state.copyWith(players: updatedPlayers, records: records);
    } else {
      final records = await repo.getSessionRecords(state.session!.id);
      state = state.copyWith(records: records);
    }
    return true;
  }

  Future<PartyReportModel?> endSession() async {
    if (!state.isActive) return null;
    final repo = ref.read(sessionRepositoryProvider);
    final sessionId = state.session!.id;
    await repo.endSession(sessionId);

    final records = await repo.getSessionRecords(sessionId);
    final logs = await repo.getGameLogs(sessionId);

    final statsMap = <String, PlayerReportStat>{};
    for (final r in records) {
      final key = r.nicknameSnapshot;
      final existing = statsMap[key];
      if (existing == null) {
        statsMap[key] = PlayerReportStat(
          nickname: key,
          totalDrinks: r.cups,
          punishmentsCompleted: 1,
          punishmentsSkipped: 0,
        );
      } else {
        statsMap[key] = PlayerReportStat(
          nickname: key,
          totalDrinks: existing.totalDrinks + r.cups,
          punishmentsCompleted: existing.punishmentsCompleted + 1,
          punishmentsSkipped: existing.punishmentsSkipped,
        );
      }
    }

    final report = PartyReportModel(
      sessionId: sessionId,
      startedAt: state.session!.startedAt,
      endedAt: DateTime.now(),
      playerStats: statsMap.values.toList()
        ..sort((a, b) => b.totalDrinks.compareTo(a.totalDrinks)),
      gameLogs: logs.map((l) => l['summary'] as String).toList(),
    );

    state = const SessionState();
    return report;
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
