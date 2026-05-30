import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/player_repository.dart';
import '../../data/repositories/punishment_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/wheel_repository.dart';

final playerRepositoryProvider = Provider((ref) => PlayerRepository());
final punishmentRepositoryProvider = Provider((ref) => PunishmentRepository());
final wheelRepositoryProvider = Provider((ref) => WheelRepository());
final sessionRepositoryProvider = Provider((ref) => SessionRepository());
