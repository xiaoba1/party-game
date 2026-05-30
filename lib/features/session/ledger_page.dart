import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/enums/app_enums.dart';
import '../../shared/widgets/editable_player_chip.dart';
import 'providers/session_provider.dart';

class LedgerPage extends ConsumerWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('罚酒详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销上一笔',
            onPressed: () async {
              final ok =
                  await ref.read(sessionProvider.notifier).undoLastRecord();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? '已撤销' : '没有可撤销的记录'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: session.session == null
          ? const Center(child: Text('暂无进行中的聚会'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (session.drinkMode == DrinkCountMode.cumulative) ...[
                  Text('累计待喝',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...session.players.map((p) {
                    if (p.pendingCups <= 0) return const SizedBox.shrink();
                    return Card(
                      child: ListTile(
                        leading: EditablePlayerChip(
                          sessionPlayer: p,
                          showPendingCups: false,
                        ),
                        title: Text('待喝 ${p.pendingCups} 杯'),
                        trailing: FilledButton(
                          onPressed: () async {
                            await ref
                                .read(sessionProvider.notifier)
                                .settleDrinks(p.id, p.pendingCups);
                          },
                          child: const Text('结算'),
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 32),
                ],
                Text('罚酒流水', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (session.records.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('暂无记录')),
                  )
                else
                  ...session.records.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.drinkColor.withValues(alpha: 0.2),
                            child: Text('${r.cups}🍺',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(r.nicknameSnapshot),
                          subtitle: Text('${r.reason}\n${r.gameType}'),
                          isThreeLine: true,
                        ),
                      )),
              ],
            ),
    );
  }
}
