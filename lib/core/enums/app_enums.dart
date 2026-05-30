/// 罚酒计数模式
enum DrinkCountMode {
  immediate('直和模式', '每次惩罚确认后立即扣减'),
  cumulative('累计模式', '惩罚累加，主动结算时一次性扣减');

  const DrinkCountMode(this.label, this.description);
  final String label;
  final String description;
}

/// 惩罚库标签
enum PunishmentTag {
  truth('真心话'),
  dare('大冒险'),
  drink('罚酒'),
  performance('表演'),
  interaction('互动'),
  reward('奖励');

  const PunishmentTag(this.label);
  final String label;

  static PunishmentTag? fromString(String value) {
    return PunishmentTag.values.cast<PunishmentTag?>().firstWhere(
          (e) => e?.name == value,
          orElse: () => null,
        );
  }
}

/// 惩罚难度
enum PunishmentDifficulty {
  mild('轻度'),
  medium('中度'),
  heavy('重度');

  const PunishmentDifficulty(this.label);
  final String label;

  static PunishmentDifficulty fromString(String value) {
    return PunishmentDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PunishmentDifficulty.mild,
    );
  }
}

/// 惩罚来源
enum PunishmentSource {
  builtIn('内置'),
  custom('自定义');

  const PunishmentSource(this.label);
  final String label;
}

/// 转盘选项类型
enum WheelOptionType {
  text('固定文案'),
  punishment('惩罚库条目'),
  randomTag('随机标签');

  const WheelOptionType(this.label);
  final String label;

  static WheelOptionType fromString(String value) {
    return WheelOptionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WheelOptionType.text,
    );
  }
}

/// 聚会会话状态
enum SessionStatus {
  active('进行中'),
  ended('已结束');

  const SessionStatus(this.label);
  final String label;
}

/// 联机消息类型
enum RoomMessageType {
  join,
  syncState,
  vote,
  drinkUpdate,
  playerNicknameUpdated,
  gameAction,
  ping,
  pong,
}

/// 卧底游戏阶段
enum UndercoverPhase {
  waiting('等待开始'),
  dealing('发牌中'),
  discussing('讨论中'),
  voting('投票中'),
  reveal('揭晓'),
  ended('已结束');

  const UndercoverPhase(this.label);
  final String label;
}

/// 扑克游戏规则
enum PokerGameRule {
  king('国王游戏'),
  jqk('JQK 惩罚');

  const PokerGameRule(this.label);
  final String label;
}
