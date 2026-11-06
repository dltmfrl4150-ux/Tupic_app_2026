import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/player/presentation/widgets/player_unlock_hold_button.dart';
import 'package:tupic/l10n/app_localizations.dart';

void main() {
  testWidgets('short press does not unlock and shows icon only', (tester) async {
    var unlocked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerUnlockHoldButton(
              semanticLabel: '잠금 해제',
              semanticHint: '길게 눌러 잠금해제',
              holdDuration: const Duration(seconds: 1),
              onUnlock: () async {
                unlocked += 1;
              },
            ),
          ),
        ),
      ),
    );

    final button = find.byType(PlayerUnlockHoldButton);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pump();

    expect(unlocked, 0);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text('길게 눌러 잠금해제'), findsNothing);
  });

  testWidgets('holding unlocks once without visible hint text', (tester) async {
    var unlocked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerUnlockHoldButton(
              semanticLabel: 'Unlock',
              semanticHint: 'Long press to unlock',
              holdDuration: const Duration(milliseconds: 200),
              onUnlock: () async {
                unlocked += 1;
              },
            ),
          ),
        ),
      ),
    );

    final target = find.byIcon(Icons.lock);
    final gesture = await tester.startGesture(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pump();

    expect(unlocked, 1);
    expect(find.textContaining('Long press'), findsNothing);
  });

  testWidgets('localized unlock hints remain available for semantics', (
    tester,
  ) async {
    for (final locale in const [Locale('ko'), Locale('en')]) {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      if (locale.languageCode == 'ko') {
        expect(l10n.playerUnlockHint, '길게 눌러 잠금해제');
      } else {
        expect(l10n.playerUnlockHint, 'Long press to unlock');
      }
    }
  });
}
