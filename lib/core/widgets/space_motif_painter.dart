import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tupic_colors.dart';

/// Sparse 2D flat accents for channel cards / empty states.
/// Fixed logical sizes — not a full pattern, never dominates card content.
class SpaceMotifPainter extends CustomPainter {
  const SpaceMotifPainter({
    this.seed = 1,
    this.accent = TupicColors.accentViolet,
    this.dense = false,
  });

  final int seed;
  final Color accent;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rng = math.Random(seed);
    final starCount = dense ? 12 : 7;
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);

    for (var i = 0; i < starCount; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.5 + rng.nextDouble() * 1.1,
        starPaint,
      );
    }

    // One small planet — fixed px radius, not % of card that grows huge.
    final r = dense ? 10.0 : 8.0;
    final planet = Offset(size.width * 0.78, size.height * 0.28);
    canvas.drawCircle(
      planet,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.4),
            accent.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromCircle(center: planet, radius: r)),
    );

    if (dense) {
      final orbit = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.2);
      canvas.drawOval(
        Rect.fromCenter(
          center: planet.translate(0, 1),
          width: r * 2.4,
          height: r * 0.6,
        ),
        orbit,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpaceMotifPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.accent != accent ||
        oldDelegate.dense != dense;
  }
}
