import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/app_enums.dart';
import '../../shared/widgets/editable_player_chip.dart';
import '../players/providers/players_provider.dart';
import '../session/providers/session_provider.dart';

class SessionStartPage extends ConsumerStatefulWidget {
  const SessionStartPage({super.key});

  @override
  ConsumerState<SessionStartPage> createState() => _SessionStartPageState();
}

class _SessionStartPageState extends ConsumerState<SessionStartPage> {
  final _selectedIds = <String>{};
  DrinkCountMode _drinkMode = DrinkCountMode.immediate;

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final session = ref.watch(sessionProvider);

    if (session.isActive) {
      return Scaffold(
        appBar: AppBar(title: const Text('开始聚会')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('已有进行中的聚会'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('返回首页继续'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('开始聚会')),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (players) {
          if (players.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('请先添加玩家'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/players'),
                    child: const Text('去添加'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<DrinkCountMode>(
                  segments: DrinkCountMode.values
                      .map((m) => ButtonSegment(
                            value: m,
                            label: Text(m.label),
                          ))
                      .toList(),
                  selected: {_drinkMode},
                  onSelectionChanged: (s) =>
                      setState(() => _drinkMode = s.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _drinkMode.description,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('选择玩家 (${_selectedIds.length})',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedIds.length == players.length) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(players.map((p) => p.id));
                          }
                        });
                      },
                      child: Text(_selectedIds.length == players.length
                          ? '取消全选'
                          : '全选'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: players.length,
                  itemBuilder: (_, i) {
                    final p = players[i];
                    final selected = _selectedIds.contains(p.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : null,
                      child: ListTile(
                        leading: PlayerAvatar(
                          emoji: p.avatarEmoji,
                          color: p.avatarColor,
                        ),
                        title: Text(p.displayName),
                        subtitle: Text(p.name),
                        trailing: Icon(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(p.id);
                            } else {
                              _selectedIds.add(p.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () async {
                    final players = ref.read(playersProvider).value ?? [];
                    final selected = players
                        .where((p) => _selectedIds.contains(p.id))
                        .toList();
                    await ref.read(sessionProvider.notifier).startSession(
                          selectedPlayers: selected,
                          drinkMode: _drinkMode,
                        );
                    if (context.mounted) context.go('/');
                  },
            child: Text('开始聚会 (${_selectedIds.length} 人)'),
          ),
        ),
      ),
    );
  }
}
