import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/app_models.dart';
import '../../features/session/providers/session_provider.dart';

/// 可点击编辑昵称的玩家 Chip
class EditablePlayerChip extends ConsumerWidget {
  const EditablePlayerChip({
    super.key,
    required this.sessionPlayer,
    this.compact = false,
    this.showPendingCups = true,
  });

  final SessionPlayerModel sessionPlayer;
  final bool compact;
  final bool showPendingCups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = sessionPlayer.pendingCups;
    return GestureDetector(
      onTap: () => _showEditDialog(context, ref),
      onLongPress: () => _showEditDialog(context, ref),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: Color(sessionPlayer.avatarColor),
          radius: compact ? 12 : 14,
          child: Text(
            sessionPlayer.avatarEmoji,
            style: TextStyle(fontSize: compact ? 12 : 14),
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                sessionPlayer.sessionNickname,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
            ),
            if (showPendingCups && pending > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pending🍺',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: sessionPlayer.sessionNickname);
    var sessionOnly = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('修改昵称'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: AppConstants.maxNicknameLength,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  hintText: '输入新昵称',
                ),
                autofocus: true,
              ),
              SwitchListTile(
                title: const Text('仅本场生效'),
                subtitle: const Text('关闭则同步到玩家档案'),
                value: sessionOnly,
                onChanged: (v) => setState(() => sessionOnly = v),
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
                final nickname = controller.text.trim();
                if (nickname.isEmpty) return;
                HapticFeedback.lightImpact();
                await ref.read(sessionProvider.notifier).updateNickname(
                      sessionPlayerId: sessionPlayer.id,
                      newNickname: nickname,
                      sessionOnly: sessionOnly,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

/// 玩家头像组件
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 40,
  });

  final String emoji;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Color(color),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

/// 玩家档案 Chip（非 Session 场景）
class ProfilePlayerChip extends StatelessWidget {
  const ProfilePlayerChip({
    super.key,
    required this.player,
    this.selected = false,
    this.onTap,
  });

  final PlayerModel player;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap?.call(),
      avatar: PlayerAvatar(
        emoji: player.avatarEmoji,
        color: player.avatarColor,
        size: 28,
      ),
      label: Text(player.displayName),
    );
  }
}
