import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../data/google_auth_service.dart';

/// Auth state for UI. Does not touch SharedPreferences channel/content keys.
class AuthController extends ChangeNotifier {
  AuthController({
    required this.firebaseReady,
    GoogleAuthService? googleAuthService,
    Stream<User?>? authStateChanges,
  }) : _service = googleAuthService {
    if (!firebaseReady) return;
    final service = _service ?? GoogleAuthService();
    _service = service;
    _user = service.currentUser;
    _subscription = (authStateChanges ?? service.authStateChanges()).listen((
      user,
    ) {
      _user = user;
      notifyListeners();
    });
  }

  /// False on unsupported platforms / failed init / widget tests without Firebase.
  final bool firebaseReady;

  GoogleAuthService? _service;
  StreamSubscription<User?>? _subscription;
  User? _user;
  bool _busy = false;
  String? _lastError;

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get busy => _busy;
  String? get lastError => _lastError;

  String? get displayName {
    final name = _user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  Future<GoogleSignInOutcome> signInWithGoogle() async {
    if (!firebaseReady || _service == null) {
      return const GoogleSignInFailure(
        'Google sign-in is only available on the Android build with Firebase.',
      );
    }
    if (_busy) {
      return const GoogleSignInFailure('Sign-in is already in progress.');
    }

    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      final outcome = await _service!.signInWithGoogle();
      if (outcome is GoogleSignInFailure) {
        _lastError = outcome.message;
      }
      return outcome;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!firebaseReady || _service == null) return;
    if (_busy) return;
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service!.signOut();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found');
    return scope!.notifier!;
  }

  static AuthController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
  }
}
