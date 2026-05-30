import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../data/models/app_models.dart';

/// 转盘 CustomPainter
class WheelPainter extends CustomPainter {
  WheelPainter({required this.options});

  final List<WheelOptionModel> options;

  static const _colors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFFFF7675),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
    Color(0xFF4DD0E1),
    Color(0xFFA1887F),
    Color(0xFF90A4AE),
    Color(0xFFF06292),
    Color(0xFF7986CB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (options.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final sliceAngle = 2 * pi / options.length;

    for (var i = 0; i < options.length; i++) {
      final startAngle = i * sliceAngle - pi / 2;
      final sweepAngle = sliceAngle;
      final color = _colors[i % _colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // 分隔线
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // 文字
      _drawLabel(canvas, center, radius, startAngle + sweepAngle / 2, options[i].label, options.length);
    }

    // 中心圆
    canvas.drawCircle(
      center,
      20,
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.drawCircle(
      center,
      20,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String label,
    int totalOptions,
  ) {
    final fontSize = totalOptions > 20 ? 8.0 : (totalOptions > 12 ? 10.0 : 12.0);
    final displayText = totalOptions > 20
        ? '${label.length > 4 ? '${label.substring(0, 4)}…' : label}'
        : (label.length > 8 ? '${label.substring(0, 8)}…' : label);

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final labelRadius = radius * 0.65;
    final x = center.dx + labelRadius * cos(angle) - textPainter.width / 2;
    final y = center.dy + labelRadius * sin(angle) - textPainter.height / 2;

    canvas.save();
    canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
    canvas.rotate(angle + pi / 2);
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.options.length != options.length;
}
