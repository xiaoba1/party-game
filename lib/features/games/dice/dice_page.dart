import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/session_top_bar.dart';

class DicePage extends ConsumerStatefulWidget {
  const DicePage({super.key});

  @override
  ConsumerState<DicePage> createState() => _DicePageState();
}

class _DicePageState extends ConsumerState<DicePage> {
  int _diceCount = 2;
  List<int> _values = [1, 1];
  bool _rolling = false;

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() => _rolling = true);
    HapticFeedback.mediumImpact();

    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        _values = List.generate(_diceCount, (_) => math.Random().nextInt(6) + 1);
      });
    }

    HapticFeedback.heavyImpact();
    setState(() => _rolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final total = _values.fold<int>(0, (a, b) => a + b);
    final maxValue = _values.reduce(math.max);

    return Scaffold(
      appBar: const SessionTopBar(title: '摇骰子'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('骰子数量: '),
                ...List.generate(5, (i) {
                  final count = i + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text('$count'),
                      selected: _diceCount == count,
                      onSelected: (_) {
                        setState(() {
                          _diceCount = count;
                          _values = List.generate(count, (_) => 1);
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(_diceCount, (i) {
                  return _DiceWidget(value: _values[i], rolling: _rolling)
                      .animate(key: ValueKey('$_rolling-${_values[i]}-$i'))
                      .shake(duration: _rolling ? 80.ms : 0.ms);
                }),
              ),
            ),
          ),
          if (_diceCount > 1)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '总和: $total · 最大: $maxValue',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: _rolling ? null : _roll,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(_rolling ? '摇动中...' : '🎲 摇骰子'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceWidget extends StatelessWidget {
  const _DiceWidget({required this.value, required this.rolling});

  final int value;
  final bool rolling;

  static const _dots = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.25, 0.25), Offset(0.75, 0.75)],
    3: [Offset(0.25, 0.25), Offset(0.5, 0.5), Offset(0.75, 0.75)],
    4: [Offset(0.25, 0.25), Offset(0.75, 0.25), Offset(0.25, 0.75), Offset(0.75, 0.75)],
    5: [Offset(0.25, 0.25), Offset(0.75, 0.25), Offset(0.5, 0.5), Offset(0.25, 0.75), Offset(0.75, 0.75)],
    6: [Offset(0.25, 0.25), Offset(0.75, 0.25), Offset(0.25, 0.5), Offset(0.75, 0.5), Offset(0.25, 0.75), Offset(0.75, 0.75)],
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: rolling ? 12 : 6,
            offset: Offset(0, rolling ? 6 : 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DiceDotsPainter(dots: _dots[value] ?? []),
      ),
    );
  }
}

class _DiceDotsPainter extends CustomPainter {
  _DiceDotsPainter({required this.dots});
  final List<Offset> dots;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1A2E);
    for (final dot in dots) {
      canvas.drawCircle(
        Offset(dot.dx * size.width, dot.dy * size.height),
        size.width * 0.08,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiceDotsPainter old) => old.dots != dots;
}
