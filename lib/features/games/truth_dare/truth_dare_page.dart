import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_enums.dart';
import '../../../shared/widgets/punishment_dialog.dart';
import '../../../shared/widgets/session_top_bar.dart';
import '../../players/providers/players_provider.dart';
import '../../session/providers/session_provider.dart';

class TruthDarePage extends ConsumerStatefulWidget {
  const TruthDarePage({super.key});

  @override
  ConsumerState<TruthDarePage> createState() => _TruthDarePageState();
}

class _TruthDarePageState extends ConsumerState<TruthDarePage> {
  String? _mode; // null=混合, truth, dare
  String? _currentContent;
  String? _currentTag;
  bool _drawing = false;

  Future<void> _draw() async {
    if (_drawing) return;
    setState(() {
      _drawing = true;
      _currentContent = null;
    });
    HapticFeedback.mediumImpact();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    String? tag;
    if (_mode == 'truth') {
      tag = PunishmentTag.truth.name;
    } else if (_mode == 'dare') {
      tag = PunishmentTag.dare.name;
    } else {
      tag = [PunishmentTag.truth.name, PunishmentTag.dare.name][DateTime.now().millisecond % 2];
    }

    final item = await ref.read(punishmentsProvider.notifier).drawRandom(tag: tag);

    if (!mounted) return;
    setState(() {
      _drawing = false;
      _currentContent = item?.content ?? '库中没有更多题目了，去添加一些吧！';
      _currentTag = item?.tag ?? tag;
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final tagLabel = _currentTag != null
        ? PunishmentTag.values
            .cast<PunishmentTag?>()
            .firstWhere((t) => t?.name == _currentTag, orElse: () => null)
            ?.label
        : null;

    return Scaffold(
      appBar: const SessionTopBar(title: '真心话大冒险'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text('混合')),
                ButtonSegment(value: 'truth', label: Text('真心话')),
                ButtonSegment(value: 'dare', label: Text('大冒险')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const Spacer(),
            if (_drawing)
              const CircularProgressIndicator()
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 800.ms)
            else if (_currentContent != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      if (tagLabel != null)
                        Chip(label: Text(tagLabel)),
                      const SizedBox(height: 16),
                      Text(
                        _currentContent!,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9))
            else
              Text(
                '点击下方按钮抽题',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            const Spacer(),
            if (_currentContent != null && session.isActive)
              OutlinedButton.icon(
                onPressed: () async {
                  final player = await showSelectPlayerDialog(
                    context,
                    session.players,
                    title: '谁来回答/执行？',
                  );
                  if (player != null && mounted) {
                    await PunishmentDialog.show(
                      context,
                      sessionPlayer: player,
                      punishmentText: _currentContent!,
                      gameType: 'truth_dare',
                    );
                  }
                },
                icon: const Icon(Icons.local_bar),
                label: const Text('指定玩家执行'),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _drawing ? null : _draw,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(_drawing ? '抽取中...' : '抽一题'),
            ),
          ],
        ),
      ),
    );
  }
}
