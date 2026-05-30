/// 应用常量
class AppConstants {
  AppConstants._();

  static const String appName = '聚会游戏集';
  static const int defaultPenaltyCups = 1;
  static const int maxNicknameLength = 20;
  static const int maxNameLength = 30;
  static const int roomPort = 8765;
  static const String roomScheme = 'partygame';
  static const int undercoverDefaultSpies = 1;

  static const List<int> avatarColors = [
    0xFFE57373, 0xFF81C784, 0xFF64B5F6, 0xFFFFB74D,
    0xFFBA68C8, 0xFF4DD0E1, 0xFFA1887F, 0xFF90A4AE,
    0xFFF06292, 0xFF7986CB, 0xFF4DB6AC, 0xFFFF8A65,
  ];

  static const List<String> avatarEmojis = [
    '😀', '😎', '🤩', '🥳', '😈', '👻', '🦊', '🐼',
    '🦁', '🐸', '🦄', '🐙', '🍺', '🎲', '🎯', '🔥',
  ];
}
