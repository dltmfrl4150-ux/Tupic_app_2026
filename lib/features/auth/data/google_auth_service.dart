import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Result of an interactive Google sign-in attempt.
sealed class GoogleSignInOutcome {
  const GoogleSignInOutcome();
}

class GoogleSignInSuccess extends GoogleSignInOutcome {
  const GoogleSignInSuccess(this.user);
  final User user;
}

class GoogleSignInCanceled extends GoogleSignInOutcome {
  const GoogleSignInCanceled();
}

class GoogleSignInFailure extends GoogleSignInOutcome {
  const GoogleSignInFailure(this.message);
  final String message;
}

/// Google Sign-In → Firebase Auth credential exchange.
///
/// Requests only basic profile/email identity scopes needed for Auth.
/// Does not request YouTube or other Google API data scopes.
class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    this.serverClientId =
        '396875776930-3tg2iou07b2g2ulaiidts83qo929tbb2.apps.googleusercontent.com',
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Web OAuth client (type 3) from google-services.json — used as
  /// [serverClientId] so Android receives an ID token for Firebase Auth.
  final String serverClientId;

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<GoogleSignInOutcome> signInWithGoogle() async {
    try {
      await ensureInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        return const GoogleSignInFailure(
          'This platform does not support Google sign-in yet.',
        );
      }

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const GoogleSignInFailure(
          'Google sign-in did not return an ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final credentialResult = await _auth.signInWithCredential(credential);
      final user = credentialResult.user;
      if (user == null) {
        return const GoogleSignInFailure('Firebase Auth returned no user.');
      }
      return GoogleSignInSuccess(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleSignInCanceled();
      }
      debugPrint('GoogleSignInException code=${e.code}');
      return GoogleSignInFailure(_mapGoogleException(e));
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code=${e.code}');
      return GoogleSignInFailure(_mapFirebaseException(e));
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return const GoogleSignInFailure(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await ensureInitialized();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google signOut ignored error: $e');
    }
    await _auth.signOut();
  }

  String _mapGoogleException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.interrupted =>
        'Google sign-in was interrupted. Please try again.',
      GoogleSignInExceptionCode.clientConfigurationError =>
        'Google sign-in is not configured correctly.',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google sign-in provider configuration error.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Google sign-in UI is unavailable right now.',
      GoogleSignInExceptionCode.userMismatch =>
        'Signed-in Google account mismatch. Please try again.',
      _ => 'Google sign-in failed. Please try again.',
    };
  }

  String _mapFirebaseException(FirebaseAuthException e) {
    return switch (e.code) {
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'user-disabled' => 'This account has been disabled.',
      'invalid-credential' => 'Invalid Google credential. Please try again.',
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
      _ => 'Sign-in failed. Please try again.',
    };
  }
}
