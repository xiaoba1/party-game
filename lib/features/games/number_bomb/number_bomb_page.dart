import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/punishment_dialog.dart';
import '../../../shared/widgets/session_top_bar.dart';
import '../../session/providers/session_provider.dart';

/// 数字炸弹 - 轮流点数字，命中炸弹者罚酒
class NumberBombPage extends ConsumerStatefulWidget {
  const NumberBombPage({super.key});

  @override
  ConsumerState<NumberBombPage> createState() => _NumberBombPageState();
}

class _NumberBombPageState extends ConsumerState<NumberBombPage> {
  int _min = 1;
  int _max = 100;
  int? _bomb;
  int _currentPlayerIndex = 0;
  bool _exploded = false;

  void _newGame() {
    setState(() {
      _min = 1;
      _max = 100;
      _bomb = Random().nextInt(98) + 2;
      _currentPlayerIndex = 0;
      _exploded = false;
    });
    HapticFeedback.mediumImpact();
  }

  void _pickNumber(int number) {
    if (_exploded || _bomb == null) return;
    HapticFeedback.lightImpact();

    if (number == _bomb) {
      setState(() => _exploded = true);
      HapticFeedback.heavyImpact();
      _onExplode();
      return;
    }

    setState(() {
      if (number < _bomb!) {
        _min = number + 1;
      } else {
        _max = number - 1;
      }
      final session = ref.read(sessionProvider);
      if (session.players.isNotEmpty) {
        _currentPlayerIndex = (_currentPlayerIndex + 1) % session.players.length;
      }
    });
  }

  Future<void> _onExplode() async {
    final session = ref.read(sessionProvider);
    if (!session.isActive || session.players.isEmpty) return;

    final player = session.players[_currentPlayerIndex];
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💣 炸弹爆炸！'),
        content: Text('${_bomb} 是炸弹！\n${player.sessionNickname} 中招了！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('继续')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await PunishmentDialog.show(
                context,
                sessionPlayer: player,
                punishmentText: '数字炸弹',
                gameType: 'number_bomb',
              );
            },
            child: const Text('罚酒'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final currentPlayer = session.players.isNotEmpty
        ? session.players[_currentPlayerIndex]
        : null;

    return Scaffold(
      appBar: const SessionTopBar(title: '数字炸弹'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_bomb == null)
              Expanded(
                child: Center(
                  child: FilledButton(
                    onPressed: _newGame,
                    child: const Text('开始新游戏'),
                  ),
                ),
              )
            else ...[
              Text('范围: $_min - $_max',
                  style: Theme.of(context).textTheme.headlineSmall),
              if (currentPlayer != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('轮到: ${currentPlayer.sessionNickname}'),
                ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _max - _min + 1,
                  itemBuilder: (_, i) {
                    final num = _min + i;
                    return FilledButton(
                      onPressed: _exploded ? null : () => _pickNumber(num),
                      child: Text('$num'),
                    );
                  },
                ),
              ),
              if (_exploded)
                FilledButton(onPressed: _newGame, child: const Text('再来一局')),
            ],
          ],
        ),
      ),
    );
  }
}
