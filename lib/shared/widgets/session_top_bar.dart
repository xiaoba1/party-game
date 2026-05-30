import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/app_models.dart';
import '../../features/session/providers/session_provider.dart';
import 'editable_player_chip.dart';

/// 聚会中顶栏 - 显示待喝、玩家、快捷操作
class SessionTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const SessionTopBar({
    super.key,
    this.title,
    this.showLedgerButton = true,
  });

  final String? title;
  final bool showLedgerButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.isActive) {
      return AppBar(title: Text(title ?? ''));
    }

    final totalPending =
        session.players.fold<int>(0, (sum, p) => sum + p.pendingCups);

    return AppBar(
      title: title != null ? Text(title!) : null,
      actions: [
        if (totalPending > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.drinkColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.drinkColor),
                ),
                child: Text(
                  '待喝 $totalPending🍺',
                  style: const TextStyle(
                    color: AppTheme.drinkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        if (showLedgerButton)
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: '罚酒详情',
            onPressed: () => context.push('/session/ledger'),
          ),
        IconButton(
          icon: const Icon(Icons.people),
          tooltip: '玩家列表',
          onPressed: () => _showPlayersSheet(context, ref, session.players),
        ),
      ],
      bottom: session.players.isNotEmpty
          ? PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: session.players.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => EditablePlayerChip(
                    sessionPlayer: session.players[i],
                    compact: true,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showPlayersSheet(
    BuildContext context,
    WidgetRef ref,
    List<SessionPlayerModel> players,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('本场玩家', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final p in players)
                  EditablePlayerChip(sessionPlayer: p, showPendingCups: true),
              ],
            ),
            const SizedBox(height: 16),
            if (ref.read(sessionProvider).drinkMode == DrinkCountMode.cumulative)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '累计模式：在罚酒详情页可批量结算',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
