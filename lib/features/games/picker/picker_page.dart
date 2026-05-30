import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/punishment_dialog.dart';
import '../../../shared/widgets/session_top_bar.dart';
import '../../session/providers/session_provider.dart';

class PickerPage extends ConsumerStatefulWidget {
  const PickerPage({super.key});

  @override
  ConsumerState<PickerPage> createState() => _PickerPageState();
}

class _PickerPageState extends ConsumerState<PickerPage> {
  String? _pickedName;
  bool _picking = false;
  final _excludedIds = <String>{};

  Future<void> _pick() async {
    final session = ref.read(sessionProvider);
    if (!session.isActive || session.players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先开始聚会并添加玩家')),
      );
      return;
    }

    final available = session.players
        .where((p) => !_excludedIds.contains(p.id))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有玩家都已点过，已重置')),
      );
      setState(() => _excludedIds.clear());
      return;
    }

    setState(() {
      _picking = true;
      _pickedName = null;
    });
    HapticFeedback.mediumImpact();

    for (var i = 0; i < 15; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _pickedName = available[Random().nextInt(available.length)].sessionNickname;
      });
    }

    final picked = available[Random().nextInt(available.length)];
    setState(() {
      _picking = false;
      _pickedName = picked.sessionNickname;
      _excludedIds.add(picked.id);
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: const SessionTopBar(title: '随机点名'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (session.isActive)
              Text(
                '已排除 ${_excludedIds.length}/${session.players.length} 人',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            const Spacer(),
            if (_pickedName != null)
              Text(
                _pickedName!,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
            else
              Text(
                session.isActive ? '准备好了吗？' : '请先开始聚会',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
              ),
            const Spacer(),
            if (_pickedName != null && session.isActive)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _excludedIds.clear()),
                    child: const Text('重置排除'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: () async {
                      final player = session.players.firstWhere(
                        (p) => p.sessionNickname == _pickedName,
                        orElse: () => session.players.first,
                      );
                      await PunishmentDialog.show(
                        context,
                        sessionPlayer: player,
                        punishmentText: '被点名',
                        gameType: 'picker',
                      );
                    },
                    child: const Text('罚酒'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _picking || !session.isActive ? null : _pick,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(_picking ? '抽取中...' : '🎯 随机点名'),
            ),
          ],
        ),
      ),
    );
  }
}
