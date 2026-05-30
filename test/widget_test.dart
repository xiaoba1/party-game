import 'package:flutter_test/flutter_test.dart';

import 'package:party_game/core/enums/app_enums.dart';
import 'package:party_game/data/models/app_models.dart';

void main() {
  test('PlayerModel displayName uses nickname when set', () {
    final player = PlayerModel(
      id: '1',
      name: '张三',
      nickname: '三哥',
      avatarColor: 0xFF6C5CE7,
      avatarEmoji: '😀',
      createdAt: DateTime(2026),
    );
    expect(player.displayName, '三哥');
  });

  test('DrinkCountMode has two modes', () {
    expect(DrinkCountMode.values.length, 2);
  });

  test('WheelOptionModel serializes correctly', () {
    const opt = WheelOptionModel(label: '喝一口', type: 'text', weight: 2);
    final json = opt.toJson();
    expect(json['label'], '喝一口');
    expect(json['weight'], 2);
  });
}
