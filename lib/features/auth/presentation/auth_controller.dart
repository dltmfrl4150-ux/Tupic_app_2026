import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../../core/config/dev_premium_access.dart';
import '../../../core/constants/plan_limits.dart';
import '../data/google_auth_service.dart';

/// Auth state for UI. Does not touch SharedPreferences channel/content keys.
class AuthController extends ChangeNotifier {
  AuthController({
    required this.firebaseReady,
    GoogleAuthService? googleAuthService,
    Stream<User?>? authStateChanges,
    this.devPremiumUidAllowList,
  }) : _service = googleAuthService {
    if (!firebaseReady) {
      _applyPlanEntitlement(null);
      return;
    }
    final service = _service ?? GoogleAuthService();
    _service = service;
    _user = service.currentUser;
    _applyPlanEntitlement(_user);
    _subscription = (authStateChanges ?? service.authStateChanges()).listen((
      user,
    ) {
      _user = user;
      _applyPlanEntitlement(user);
      notifyListeners();
    });
  }

  /// Test-only allow-list override (never pass production secrets here).
  final List<String>? devPremiumUidAllowList;

  /// False on unsupported platforms / failed init / widget tests without Firebase.
  final bool firebaseReady;

  GoogleAuthService? _service;
  StreamSubscription<User?>? _subscription;
  User? _user;
  bool _busy = false;
  String? _lastError;

  /// Widget-test only: pretend a Firebase session exists without Firebase Auth.
  String? _debugTestUid;
  String? _debugTestDisplayName;

  User? get user => _user;
  bool get isSignedIn =>
      _user != null || (_debugTestUid != null && _debugTestUid!.isNotEmpty);
  bool get busy => _busy;
  String? get lastError => _lastError;

  String? get displayName {
    final name = _user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final debugName = _debugTestDisplayName?.trim();
    if (debugName != null && debugName.isNotEmpty) return debugName;
    return null;
  }

  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;
  String? get uid => _user?.uid ?? _debugTestUid;

  /// Test helper: emulate signed-in UID without Firebase Auth.
  @visibleForTesting
  void debugEmulateSignedIn({
    required String uid,
    String? displayName,
  }) {
    _debugTestUid = uid;
    _debugTestDisplayName = displayName;
    _applyPlanEntitlement(null);
    notifyListeners();
  }

  /// Test helper: clear [debugEmulateSignedIn] state.
  @visibleForTesting
  void debugClearEmulatedSignIn() {
    _debugTestUid = null;
    _debugTestDisplayName = null;
    _applyPlanEntitlement(null);
    notifyListeners();
  }


  /// Debug developer-test Premium badge (not a paid subscription).
  bool get isDeveloperTestPremium => PlanLimits.isDeveloperTestPremium;

  void _applyPlanEntitlement(User? user) {
    _syncDeveloperTestPremium(user?.uid);
  }

  void _syncDeveloperTestPremium(String? firebaseUid) {
    PlanLimits.setDeveloperTestPremium(
      hasDevPremiumTestAccess(
        firebaseUid: firebaseUid,
        allowedUidsOverride: devPremiumUidAllowList,
      ),
    );
  }

  /// Test helper: simulate UID entitlement without Firebase Auth.
  @visibleForTesting
  void debugSyncPremiumForUid(String? firebaseUid) {
    _syncDeveloperTestPremium(firebaseUid);
    notifyListeners();
  }

  Future<GoogleSignInOutcome> signInWithGoogle() async {
    if (!firebaseReady || _service == null) {
      return const GoogleSignInFailure(
        'Google sign-in is only available when Firebase is configured '
        '(Android or Web).',
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
      _user = null;
      _applyPlanEntitlement(null);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _applyPlanEntitlement(null);
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
