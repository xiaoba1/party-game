import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/app_models.dart';

final playersProvider =
    StateNotifierProvider<PlayersNotifier, AsyncValue<List<PlayerModel>>>((ref) {
  return PlayersNotifier(ref);
});

class PlayersNotifier extends StateNotifier<AsyncValue<List<PlayerModel>>> {
  PlayersNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadPlayers();
  }

  final Ref ref;
  final _db = AppDatabase.instance;

  Future<void> loadPlayers() async {
    state = const AsyncValue.loading();
    try {
      final players = await ref.read(playerRepositoryProvider).getAll();
      state = AsyncValue.data(players);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPlayer({
    required String name,
    String nickname = '',
    int? avatarColor,
    String? avatarEmoji,
  }) async {
    final player = PlayerModel(
      id: _db.generateId(),
      name: name,
      nickname: nickname.isEmpty ? name : nickname,
      avatarColor: avatarColor ??
          AppConstants.avatarColors[
              DateTime.now().millisecond % AppConstants.avatarColors.length],
      avatarEmoji: avatarEmoji ??
          AppConstants.avatarEmojis[
              DateTime.now().millisecond % AppConstants.avatarEmojis.length],
      createdAt: DateTime.now(),
    );
    await ref.read(playerRepositoryProvider).insert(player);
    await loadPlayers();
  }

  Future<void> updatePlayer(PlayerModel player) async {
    await ref.read(playerRepositoryProvider).update(player);
    await loadPlayers();
  }

  Future<void> deletePlayer(String id) async {
    await ref.read(playerRepositoryProvider).delete(id);
    await loadPlayers();
  }
}

final punishmentsProvider =
    StateNotifierProvider<PunishmentsNotifier, AsyncValue<List<PunishmentModel>>>(
        (ref) {
  return PunishmentsNotifier(ref);
});

class PunishmentsNotifier
    extends StateNotifier<AsyncValue<List<PunishmentModel>>> {
  PunishmentsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadPunishments();
  }

  final Ref ref;
  final _db = AppDatabase.instance;
  String? _filterTag;
  String? _filterDifficulty;

  Future<void> loadPunishments({String? tag, String? difficulty}) async {
    _filterTag = tag;
    _filterDifficulty = difficulty;
    state = const AsyncValue.loading();
    try {
      final items = await ref.read(punishmentRepositoryProvider).getAll(
            tag: tag,
            difficulty: difficulty,
          );
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCustom({
    required String content,
    required String tag,
    String difficulty = 'mild',
  }) async {
    final item = PunishmentModel(
      id: _db.generateId(),
      content: content,
      tag: tag,
      difficulty: difficulty,
      source: 'custom',
    );
    await ref.read(punishmentRepositoryProvider).insert(item);
    await loadPunishments(tag: _filterTag, difficulty: _filterDifficulty);
  }

  Future<void> toggleFavorite(PunishmentModel item) async {
    await ref
        .read(punishmentRepositoryProvider)
        .update(item.copyWith(isFavorite: !item.isFavorite));
    await loadPunishments(tag: _filterTag, difficulty: _filterDifficulty);
  }

  Future<void> deleteCustom(String id) async {
    await ref.read(punishmentRepositoryProvider).delete(id);
    await loadPunishments(tag: _filterTag, difficulty: _filterDifficulty);
  }

  Future<PunishmentModel?> drawRandom({String? tag}) async {
    final item =
        await ref.read(punishmentRepositoryProvider).getRandom(tag: tag);
    if (item != null) {
      await ref.read(punishmentRepositoryProvider).incrementUseCount(item.id);
    }
    return item;
  }
}

final wheelTemplatesProvider =
    FutureProvider<List<WheelTemplateModel>>((ref) async {
  return ref.read(wheelRepositoryProvider).getAll();
});
