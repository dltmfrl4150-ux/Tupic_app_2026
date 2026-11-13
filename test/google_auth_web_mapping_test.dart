import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/features/auth/data/google_auth_service.dart';

void main() {
  test('web popup cancel codes map to canceled path', () {
    expect(isFirebaseAuthPopupCanceled('popup-closed-by-user'), isTrue);
    expect(isFirebaseAuthPopupCanceled('cancelled-popup-request'), isTrue);
    expect(isFirebaseAuthPopupCanceled('popup-blocked'), isFalse);
  });

  test('maps popup-blocked and unauthorized-domain for UI', () {
    expect(
      mapFirebaseAuthExceptionMessage('popup-blocked'),
      contains('popup was blocked'),
    );
    expect(
      mapFirebaseAuthExceptionMessage('unauthorized-domain'),
      contains('not authorized'),
    );
  });
}
