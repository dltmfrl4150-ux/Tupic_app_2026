import 'package:flutter/material.dart';

import '../../../../app/theme/tupic_colors.dart';
import '../../../../core/widgets/space_pattern_painter.dart';

/// Home header: 2D space pattern + Flutter brand/welcome text (no baked-in logo).
///
/// Replaces the former 3D channel-art style banner image.
class SpaceHeroIllustration extends StatelessWidget {
  const SpaceHeroIllustration({
    super.key,
    this.height = 160,
    required this.title,
    required this.subtitle,
  });

  final double height;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: height + topInset,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: TupicColors.mainBackground),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: SpacePatternPainter(
                  seed: 42,
                  intensity: 0.95,
                  fadeBottom: true,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: topInset + 12,
            right: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: TupicColors.accentViolet,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: TupicColors.primaryText,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle full-bleed pattern for the home scaffold (low intensity).
class SpacePatternBackdrop extends StatelessWidget {
  const SpacePatternBackdrop({
    super.key,
    this.intensity = 0.38,
    this.seed = 42,
  });

  final double intensity;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: SpacePatternPainter(
          seed: seed,
          intensity: intensity,
          fadeBottom: false,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
