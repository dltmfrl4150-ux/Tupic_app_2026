import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/tupic_colors.dart';

/// Deterministic 2D flat space pattern.
///
/// Uses fixed logical-pixel cell size so planets/stars keep stable sizes while
/// wider viewports simply reveal more cells (responsive density, not scale).
class SpacePatternPainter extends CustomPainter {
  const SpacePatternPainter({
    this.seed = 42,
    this.intensity = 1,
    this.fadeBottom = false,
    this.cellSize = 320,
  });

  final int seed;
  final double intensity;
  final bool fadeBottom;

  /// World cell size in logical pixels — never scales with viewport.
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final i = intensity.clamp(0.0, 1.0);

    // 1) Base deep violet
    canvas.drawRect(rect, Paint()..color = TupicColors.mainBackground);

    // 2) Soft nebula ribbons (world-anchored, not stretched blobs)
    _paintNebula(canvas, size, i);

    // 3–4) Stars + sparse points of interest in fixed cells
    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;
    for (var cy = -1; cy < rows; cy++) {
      for (var cx = -1; cx < cols; cx++) {
        _paintCell(canvas, cx, cy, size, i);
      }
    }

    if (fadeBottom) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              TupicColors.mainBackground.withValues(alpha: 0.55 * i),
              TupicColors.mainBackground.withValues(alpha: 0.92),
            ],
            stops: const [0.35, 0.72, 1.0],
          ).createShader(rect),
      );
    }
  }

  void _paintNebula(Canvas canvas, Size size, double i) {
    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = TupicColors.secondary.withValues(alpha: 0.55 * i);

    final path = Path()
      ..moveTo(0, size.height * 0.22)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.08,
        size.width * 0.45,
        size.height * 0.38,
        size.width * 0.72,
        size.height * 0.18,
      )
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.08,
        size.width,
        size.height * 0.28,
        size.width,
        size.height * 0.28,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, wavePaint);

    final lower = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, 0.85),
        radius: 1.1,
        colors: [
          TupicColors.selected.withValues(alpha: 0.28 * i),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, lower);
  }

  void _paintCell(
    Canvas canvas,
    int cx,
    int cy,
    Size viewport,
    double intensity,
  ) {
    final rng = math.Random(_cellSeed(cx, cy));
    final origin = Offset(cx * cellSize, cy * cellSize);

    // Tiny stars — fixed px radii
    final starCount = 14 + rng.nextInt(10);
    for (var s = 0; s < starCount; s++) {
      final p = origin + Offset(rng.nextDouble() * cellSize, rng.nextDouble() * cellSize);
      if (!_inView(p, viewport, pad: 4)) continue;
      final r = 0.4 + rng.nextDouble() * 1.3;
      final a = (0.12 + rng.nextDouble() * 0.35) * intensity;
      canvas.drawCircle(
        p,
        r,
        Paint()..color = TupicColors.star.withValues(alpha: a),
      );
    }

    // Twinkle (4-point) — sparse
    if (rng.nextDouble() < 0.45) {
      final p = origin + Offset(
        40 + rng.nextDouble() * (cellSize - 80),
        40 + rng.nextDouble() * (cellSize - 80),
      );
      if (_inView(p, viewport, pad: 12)) {
        _drawTwinkle(
          canvas,
          p,
          3.5 + rng.nextDouble() * 3.5,
          (rng.nextBool() ? TupicColors.accentViolet : const Color(0xFFE8D48A))
              .withValues(alpha: 0.55 * intensity),
        );
      }
    }

    // One specialty element per cell (deterministic choice)
    final kind = rng.nextInt(7);
    final center = origin + Offset(
      56 + rng.nextDouble() * (cellSize - 112),
      56 + rng.nextDouble() * (cellSize - 112),
    );
    if (!_inView(center, viewport, pad: 48)) return;

    switch (kind) {
      case 0:
        _drawRingedPlanet(
          canvas,
          center,
          14 + rng.nextDouble() * 10,
          intensity,
          rng,
        );
      case 1:
        _drawCraterPlanet(
          canvas,
          center,
          12 + rng.nextDouble() * 9,
          intensity,
          rng,
        );
      case 2:
        if (rng.nextDouble() < 0.7) {
          _drawGalaxy(canvas, center, 16 + rng.nextDouble() * 8, intensity);
        }
      case 3:
        if (rng.nextDouble() < 0.55) {
          _drawRocket(canvas, center, 0.85 + rng.nextDouble() * 0.25, intensity);
        }
      case 4:
        if (rng.nextDouble() < 0.5) {
          _drawComet(canvas, center, intensity, rng);
        }
      case 5:
        _drawOrbitArc(canvas, center, 22 + rng.nextDouble() * 18, intensity);
      default:
        _drawSmallPlanet(
          canvas,
          center,
          7 + rng.nextDouble() * 6,
          intensity,
          rng.nextBool() ? TupicColors.planetBlue : TupicColors.accentViolet,
        );
    }
  }

  int _cellSeed(int cx, int cy) {
    // Stable mix — same cell always same content regardless of viewport.
    return seed ^ (cx * 73856093) ^ (cy * 19349663);
  }

  bool _inView(Offset p, Size size, {double pad = 0}) {
    return p.dx >= -pad &&
        p.dy >= -pad &&
        p.dx <= size.width + pad &&
        p.dy <= size.height + pad;
  }

  void _drawTwinkle(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    final s = r * 0.55;
    canvas.drawLine(
      Offset(c.dx - s, c.dy - s),
      Offset(c.dx + s, c.dy + s),
      paint..strokeWidth = 0.9,
    );
    canvas.drawLine(
      Offset(c.dx + s, c.dy - s),
      Offset(c.dx - s, c.dy + s),
      paint,
    );
  }

  void _drawSmallPlanet(
    Canvas canvas,
    Offset c,
    double r,
    double intensity,
    Color color,
  ) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.75 * intensity),
            color.withValues(alpha: 0.25 * intensity),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _drawRingedPlanet(
    Canvas canvas,
    Offset c,
    double r,
    double intensity,
    math.Random rng,
  ) {
    final body = Color.lerp(
      TupicColors.accentViolet,
      const Color(0xFFC4B5FD),
      rng.nextDouble() * 0.4,
    )!;
    _drawSmallPlanet(canvas, c, r, intensity, body);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = TupicColors.primaryText.withValues(alpha: 0.28 * intensity);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.6, height: r * 0.7),
      ring,
    );
    canvas.restore();
  }

  void _drawCraterPlanet(
    Canvas canvas,
    Offset c,
    double r,
    double intensity,
    math.Random rng,
  ) {
    final color = Color.lerp(
      TupicColors.selected,
      TupicColors.accentViolet,
      0.35,
    )!;
    _drawSmallPlanet(canvas, c, r, intensity, color);
    final crater = Paint()
      ..color = TupicColors.mainBackground.withValues(alpha: 0.35 * intensity);
    for (var i = 0; i < 3; i++) {
      final o = Offset(
        (rng.nextDouble() - 0.5) * r * 0.9,
        (rng.nextDouble() - 0.5) * r * 0.9,
      );
      canvas.drawCircle(c + o, 1.2 + rng.nextDouble() * 2.2, crater);
    }
  }

  void _drawGalaxy(Canvas canvas, Offset c, double r, double intensity) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = TupicColors.accentViolet.withValues(alpha: 0.45 * intensity);
    for (var arm = 0; arm < 2; arm++) {
      final path = Path();
      for (var t = 0.0; t <= 1.0; t += 0.08) {
        final ang = t * math.pi * 2.2 + arm * math.pi;
        final rad = r * (0.15 + t * 0.85);
        final p = Offset(c.dx + math.cos(ang) * rad, c.dy + math.sin(ang) * rad);
        if (t == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(
      c,
      2.2,
      Paint()..color = TupicColors.primaryText.withValues(alpha: 0.55 * intensity),
    );
  }

  void _drawRocket(Canvas canvas, Offset c, double scale, double intensity) {
    final s = 11.0 * scale;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.55);
    final body = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.45, s * 0.55)
      ..lineTo(-s * 0.45, s * 0.55)
      ..close();
    canvas.drawPath(
      body,
      Paint()..color = TupicColors.primaryText.withValues(alpha: 0.85 * intensity),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-s * 0.35, s * 0.25)
        ..lineTo(-s * 0.75, s * 0.7)
        ..lineTo(-s * 0.1, s * 0.55)
        ..close(),
      Paint()..color = TupicColors.accentViolet.withValues(alpha: 0.8 * intensity),
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.35, s * 0.25)
        ..lineTo(s * 0.75, s * 0.7)
        ..lineTo(s * 0.1, s * 0.55)
        ..close(),
      Paint()..color = TupicColors.accentViolet.withValues(alpha: 0.8 * intensity),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-s * 0.22, s * 0.55)
        ..lineTo(0, s * 1.05)
        ..lineTo(s * 0.22, s * 0.55)
        ..close(),
      Paint()..color = const Color(0xFFF0C674).withValues(alpha: 0.9 * intensity),
    );
    canvas.restore();
  }

  void _drawComet(
    Canvas canvas,
    Offset c,
    double intensity,
    math.Random rng,
  ) {
    final dir = Offset(-0.75 - rng.nextDouble() * 0.2, 0.35);
    final len = 28.0 + rng.nextDouble() * 18;
    final tail = c + dir * len;
    canvas.drawLine(
      c,
      tail,
      Paint()
        ..shader = ui.Gradient.linear(
          c,
          tail,
          [
            const Color(0xFFE8D48A).withValues(alpha: 0.75 * intensity),
            Colors.transparent,
          ],
        )
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      c,
      2.4,
      Paint()..color = const Color(0xFFF6F3FC).withValues(alpha: 0.9 * intensity),
    );
  }

  void _drawOrbitArc(Canvas canvas, Offset c, double r, double intensity) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = TupicColors.primaryText.withValues(alpha: 0.18 * intensity);
    const dashCount = 18;
    for (var i = 0; i < dashCount; i += 2) {
      final a0 = -0.5 + (i / dashCount) * math.pi * 1.6;
      final a1 = -0.5 + ((i + 1) / dashCount) * math.pi * 1.6;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a0,
        a1 - a0,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpacePatternPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.intensity != intensity ||
        oldDelegate.fadeBottom != fadeBottom ||
        oldDelegate.cellSize != cellSize;
  }
}
