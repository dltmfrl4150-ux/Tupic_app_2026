import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/core/widgets/space_pattern_painter.dart';
import 'package:tupic/features/home/presentation/widgets/space_hero_illustration.dart';

void main() {
  testWidgets('space pattern paints on mobile/tablet/desktop widths', (
    tester,
  ) async {
    for (final width in const [390.0, 768.0, 1280.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: const SpacePatternPainter(seed: 42, intensity: 0.8),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('hero shows Flutter brand text without asset Image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpaceHeroIllustration(
            height: 140,
            title: 'TUPICK',
            subtitle: '안녕하세요, 테스터님',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('TUPICK'), findsOneWidget);
    expect(find.text('안녕하세요, 테스터님'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('same seed keeps stable cell hashing across sizes', () {
    const a = SpacePatternPainter(seed: 42, cellSize: 320);
    const b = SpacePatternPainter(seed: 42, cellSize: 320);
    expect(a.shouldRepaint(b), isFalse);
    expect(
      const SpacePatternPainter(seed: 1).shouldRepaint(
        const SpacePatternPainter(seed: 2),
      ),
      isTrue,
    );
  });
}
