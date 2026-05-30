import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/app_models.dart';
import '../../shared/widgets/editable_player_chip.dart';
import 'providers/players_provider.dart';

class PlayersPage extends ConsumerWidget {
  const PlayersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('玩家档案')),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (players) {
          if (players.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('还没有玩家，添加第一位朋友吧'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
                    icon: const Icon(Icons.person_add),
                    label: const Text('添加玩家'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (_, i) => _PlayerTile(player: players[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final nicknameController = TextEditingController();
    var selectedColor = AppConstants.avatarColors[0];
    var selectedEmoji = AppConstants.avatarEmojis[0];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('添加玩家'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名字 *'),
                  maxLength: AppConstants.maxNameLength,
                ),
                TextField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    hintText: '留空则使用名字',
                  ),
                  maxLength: AppConstants.maxNicknameLength,
                ),
                const SizedBox(height: 12),
                const Text('选择头像'),
                Wrap(
                  spacing: 8,
                  children: AppConstants.avatarEmojis.take(8).map((e) {
                    return ChoiceChip(
                      label: Text(e),
                      selected: selectedEmoji == e,
                      onSelected: (_) => setState(() => selectedEmoji = e),
                    );
                  }).toList(),
                ),
                Wrap(
                  spacing: 8,
                  children: AppConstants.avatarColors.take(6).map((c) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = c),
                      child: CircleAvatar(
                        backgroundColor: Color(c),
                        radius: selectedColor == c ? 18 : 14,
                        child: selectedColor == c
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await ref.read(playersProvider.notifier).addPlayer(
                      name: nameController.text.trim(),
                      nickname: nicknameController.text.trim(),
                      avatarColor: selectedColor,
                      avatarEmoji: selectedEmoji,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    nicknameController.dispose();
  }
}

class _PlayerTile extends ConsumerWidget {
  const _PlayerTile({required this.player});
  final PlayerModel player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: PlayerAvatar(
          emoji: player.avatarEmoji,
          color: player.avatarColor,
        ),
        title: Text(player.displayName),
        subtitle: Text('名字: ${player.name}'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') {
              await _showEditDialog(context, ref, player);
            } else if (action == 'delete') {
              await ref.read(playersProvider.notifier).deletePlayer(player.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    PlayerModel player,
  ) async {
    final nameController = TextEditingController(text: player.name);
    final nicknameController = TextEditingController(text: player.nickname);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑玩家'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '名字'),
            ),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: '昵称'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(playersProvider.notifier).updatePlayer(
                    player.copyWith(
                      name: nameController.text.trim(),
                      nickname: nicknameController.text.trim(),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    nameController.dispose();
    nicknameController.dispose();
  }
}
