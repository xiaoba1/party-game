import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_enums.dart';
import '../../../shared/widgets/punishment_dialog.dart';
import '../../../shared/widgets/session_top_bar.dart';
import '../../session/providers/session_provider.dart';

class PokerPage extends ConsumerStatefulWidget {
  const PokerPage({super.key});

  @override
  ConsumerState<PokerPage> createState() => _PokerPageState();
}

class _PokerPageState extends ConsumerState<PokerPage> {
  PokerGameRule _rule = PokerGameRule.king;
  int? _drawnValue;
  String? _drawnLabel;
  bool _drawing = false;

  static const _suits = ['♠', '♥', '♦', '♣'];
  static const _ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

  Future<void> _drawCard() async {
    if (_drawing) return;
    setState(() {
      _drawing = true;
      _drawnValue = null;
      _drawnLabel = null;
    });
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final value = Random().nextInt(13) + 1;
    final suit = _suits[Random().nextInt(4)];
    final rank = _ranks[value - 1];

    setState(() {
      _drawing = false;
      _drawnValue = value;
      _drawnLabel = '$suit$rank';
    });
    HapticFeedback.heavyImpact();
  }

  String _getRuleText(int value) {
    if (_rule == PokerGameRule.king) {
      if (value == 13) return '👑 国王！可以发布任意指令';
      if (value == 12) return 'Q - 左边的人喝一口';
      if (value == 11) return 'J - 右边的人喝一口';
      if (value == 1) return 'A - 所有人喝一口';
      return '$value 点 - 数字相同的人喝';
    } else {
      if (value == 13) return 'K - 喝一大口';
      if (value == 12) return 'Q - 喝两口';
      if (value == 11) return 'J - 指定一人喝';
      return '安全，无惩罚';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: const SessionTopBar(title: '扑克小游戏'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SegmentedButton<PokerGameRule>(
              segments: PokerGameRule.values
                  .map((r) => ButtonSegment(value: r, label: Text(r.label)))
                  .toList(),
              selected: {_rule},
              onSelectionChanged: (s) => setState(() => _rule = s.first),
            ),
            const Spacer(),
            if (_drawing)
              const CircularProgressIndicator()
            else if (_drawnLabel != null)
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 168,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _drawnLabel!,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _drawnLabel!.contains('♥') || _drawnLabel!.contains('♦')
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getRuleText(_drawnValue!),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Text('抽一张牌', style: TextStyle(color: Colors.grey.shade500)),
            const Spacer(),
            if (_drawnValue != null && session.isActive)
              OutlinedButton.icon(
                onPressed: () async {
                  final player = await showSelectPlayerDialog(
                    context,
                    session.players,
                    title: '谁来执行？',
                  );
                  if (player != null && mounted) {
                    await PunishmentDialog.show(
                      context,
                      sessionPlayer: player,
                      punishmentText: _getRuleText(_drawnValue!),
                      gameType: 'poker',
                    );
                  }
                },
                icon: const Icon(Icons.local_bar),
                label: const Text('执行惩罚'),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _drawing ? null : _drawCard,
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: Text(_drawing ? '抽牌中...' : '🃏 抽牌'),
            ),
          ],
        ),
      ),
    );
  }
}