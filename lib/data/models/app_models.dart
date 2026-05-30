/// 玩家档案
class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.name,
    required this.nickname,
    required this.avatarColor,
    required this.avatarEmoji,
    required this.createdAt,
    this.totalDrinks = 0,
  });

  final String id;
  final String name;
  final String nickname;
  final int avatarColor;
  final String avatarEmoji;
  final DateTime createdAt;
  final int totalDrinks;

  String get displayName => nickname.isNotEmpty ? nickname : name;

  PlayerModel copyWith({
    String? name,
    String? nickname,
    int? avatarColor,
    String? avatarEmoji,
    int? totalDrinks,
  }) {
    return PlayerModel(
      id: id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt,
      totalDrinks: totalDrinks ?? this.totalDrinks,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'avatar_color': avatarColor,
        'avatar_emoji': avatarEmoji,
        'created_at': createdAt.millisecondsSinceEpoch,
        'total_drinks': totalDrinks,
      };

  factory PlayerModel.fromMap(Map<String, dynamic> map) => PlayerModel(
        id: map['id'] as String,
        name: map['name'] as String,
        nickname: map['nickname'] as String? ?? '',
        avatarColor: map['avatar_color'] as int? ?? 0xFF6C5CE7,
        avatarEmoji: map['avatar_emoji'] as String? ?? '😀',
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        totalDrinks: map['total_drinks'] as int? ?? 0,
      );
}

/// 惩罚/奖励条目
class PunishmentModel {
  const PunishmentModel({
    required this.id,
    required this.content,
    required this.tag,
    required this.difficulty,
    required this.source,
    this.isFavorite = false,
    this.useCount = 0,
  });

  final String id;
  final String content;
  final String tag;
  final String difficulty;
  final String source;
  final bool isFavorite;
  final int useCount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'tag': tag,
        'difficulty': difficulty,
        'source': source,
        'is_favorite': isFavorite ? 1 : 0,
        'use_count': useCount,
      };

  factory PunishmentModel.fromMap(Map<String, dynamic> map) => PunishmentModel(
        id: map['id'] as String,
        content: map['content'] as String,
        tag: map['tag'] as String,
        difficulty: map['difficulty'] as String? ?? 'mild',
        source: map['source'] as String? ?? 'custom',
        isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
        useCount: map['use_count'] as int? ?? 0,
      );

  PunishmentModel copyWith({
    String? content,
    String? tag,
    String? difficulty,
    bool? isFavorite,
    int? useCount,
  }) {
    return PunishmentModel(
      id: id,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      difficulty: difficulty ?? this.difficulty,
      source: source,
      isFavorite: isFavorite ?? this.isFavorite,
      useCount: useCount ?? this.useCount,
    );
  }
}

/// 转盘选项
class WheelOptionModel {
  const WheelOptionModel({
    required this.label,
    required this.type,
    this.punishmentId,
    this.randomTag,
    this.weight = 1,
  });

  final String label;
  final String type;
  final String? punishmentId;
  final String? randomTag;
  final int weight;

  Map<String, dynamic> toJson() => {
        'label': label,
        'type': type,
        if (punishmentId != null) 'punishmentId': punishmentId,
        if (randomTag != null) 'randomTag': randomTag,
        'weight': weight,
      };

  factory WheelOptionModel.fromJson(Map<String, dynamic> json) =>
      WheelOptionModel(
        label: json['label'] as String,
        type: json['type'] as String? ?? 'text',
        punishmentId: json['punishmentId'] as String?,
        randomTag: json['randomTag'] as String?,
        weight: json['weight'] as int? ?? 1,
      );
}

/// 转盘模板
class WheelTemplateModel {
  const WheelTemplateModel({
    required this.id,
    required this.name,
    required this.options,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final List<WheelOptionModel> options;
  final bool isBuiltIn;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'options_json': options.map((e) => e.toJson()).toList(),
        'is_built_in': isBuiltIn ? 1 : 0,
      };

  factory WheelTemplateModel.fromMap(Map<String, dynamic> map) {
    final optionsJson = map['options_json'];
    List<WheelOptionModel> options = [];
    if (optionsJson is String) {
      // fallback
    } else if (optionsJson is List) {
      options = optionsJson
          .map((e) => WheelOptionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return WheelTemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      options: options,
      isBuiltIn: (map['is_built_in'] as int? ?? 0) == 1,
    );
  }
}

/// 场次玩家
class SessionPlayerModel {
  const SessionPlayerModel({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.sessionNickname,
    required this.pendingCups,
    this.avatarColor = 0xFF6C5CE7,
    this.avatarEmoji = '😀',
  });

  final String id;
  final String sessionId;
  final String playerId;
  final String sessionNickname;
  final int pendingCups;
  final int avatarColor;
  final String avatarEmoji;

  SessionPlayerModel copyWith({
    String? sessionNickname,
    int? pendingCups,
  }) {
    return SessionPlayerModel(
      id: id,
      sessionId: sessionId,
      playerId: playerId,
      sessionNickname: sessionNickname ?? this.sessionNickname,
      pendingCups: pendingCups ?? this.pendingCups,
      avatarColor: avatarColor,
      avatarEmoji: avatarEmoji,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'player_id': playerId,
        'session_nickname': sessionNickname,
        'pending_cups': pendingCups,
        'avatar_color': avatarColor,
        'avatar_emoji': avatarEmoji,
      };

  factory SessionPlayerModel.fromMap(Map<String, dynamic> map) =>
      SessionPlayerModel(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        playerId: map['player_id'] as String,
        sessionNickname: map['session_nickname'] as String,
        pendingCups: map['pending_cups'] as int? ?? 0,
        avatarColor: map['avatar_color'] as int? ?? 0xFF6C5CE7,
        avatarEmoji: map['avatar_emoji'] as String? ?? '😀',
      );
}

/// 聚会会话
class GameSessionModel {
  const GameSessionModel({
    required this.id,
    required this.drinkMode,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String drinkMode;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'drink_mode': drinkMode,
        'status': status,
        'started_at': startedAt.millisecondsSinceEpoch,
        'ended_at': endedAt?.millisecondsSinceEpoch,
      };

  factory GameSessionModel.fromMap(Map<String, dynamic> map) => GameSessionModel(
        id: map['id'] as String,
        drinkMode: map['drink_mode'] as String? ?? 'immediate',
        status: map['status'] as String? ?? 'active',
        startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
        endedAt: map['ended_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int)
            : null,
      );
}

/// 罚酒流水
class DrinkRecordModel {
  const DrinkRecordModel({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.nicknameSnapshot,
    required this.cups,
    required this.reason,
    required this.gameType,
    required this.timestamp,
    this.isUndone = false,
  });

  final String id;
  final String sessionId;
  final String playerId;
  final String nicknameSnapshot;
  final int cups;
  final String reason;
  final String gameType;
  final DateTime timestamp;
  final bool isUndone;

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'player_id': playerId,
        'nickname_snapshot': nicknameSnapshot,
        'cups': cups,
        'reason': reason,
        'game_type': gameType,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'is_undone': isUndone ? 1 : 0,
      };

  factory DrinkRecordModel.fromMap(Map<String, dynamic> map) => DrinkRecordModel(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        playerId: map['player_id'] as String,
        nicknameSnapshot: map['nickname_snapshot'] as String,
        cups: map['cups'] as int,
        reason: map['reason'] as String? ?? '',
        gameType: map['game_type'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        isUndone: (map['is_undone'] as int? ?? 0) == 1,
      );
}

/// 卧底词对
class UndercoverWordPair {
  const UndercoverWordPair({
    required this.id,
    required this.civilianWord,
    required this.spyWord,
    required this.category,
  });

  final String id;
  final String civilianWord;
  final String spyWord;
  final String category;

  factory UndercoverWordPair.fromJson(Map<String, dynamic> json) =>
      UndercoverWordPair(
        id: json['id'] as String,
        civilianWord: json['civilianWord'] as String,
        spyWord: json['spyWord'] as String,
        category: json['category'] as String? ?? '通用',
      );
}

/// 聚会战报
class PartyReportModel {
  const PartyReportModel({
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.playerStats,
    required this.gameLogs,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<PlayerReportStat> playerStats;
  final List<String> gameLogs;
}

class PlayerReportStat {
  const PlayerReportStat({
    required this.nickname,
    required this.totalDrinks,
    required this.punishmentsCompleted,
    required this.punishmentsSkipped,
  });

  final String nickname;
  final int totalDrinks;
  final int punishmentsCompleted;
  final int punishmentsSkipped;
}
