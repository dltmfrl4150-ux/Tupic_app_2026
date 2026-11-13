import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/core/utils/parental_gate.dart';

void main() {
  group('requiresParentalGateForChannelSwitch', () {
    test('kids → general requires gate', () {
      expect(
        requiresParentalGateForChannelSwitch(
          fromKidsChannel: true,
          toKidsChannel: false,
        ),
        isTrue,
      );
    });

    test('kids → kids does not require gate', () {
      expect(
        requiresParentalGateForChannelSwitch(
          fromKidsChannel: true,
          toKidsChannel: true,
        ),
        isFalse,
      );
    });

    test('general → kids does not require gate', () {
      expect(
        requiresParentalGateForChannelSwitch(
          fromKidsChannel: false,
          toKidsChannel: true,
        ),
        isFalse,
      );
    });

    test('general → general does not require gate', () {
      expect(
        requiresParentalGateForChannelSwitch(
          fromKidsChannel: false,
          toKidsChannel: false,
        ),
        isFalse,
      );
    });
  });

  test('passesParentalGate still age-based and stores nothing', () {
    final now = DateTime(2026, 11, 9);
    expect(passesParentalGate(2008, now: now), isTrue);
    expect(passesParentalGate(2009, now: now), isFalse);
  });
}
