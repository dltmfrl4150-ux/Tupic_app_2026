import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../shared/models/public_profile.dart';
import '../../../shared/repositories/public_profile_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/nickname_validator.dart';

/// Loads/saves the signed-in user's public nickname (separate from Google name).
class PublicProfileController extends ChangeNotifier {
  PublicProfileController({
    required AuthController authController,
    required PublicProfileRepository repository,
  }) : _auth = authController,
       _repository = repository {
    _auth.addListener(_onAuthChanged);
    unawaited(refresh());
  }

  final AuthController _auth;
  final PublicProfileRepository _repository;

  PublicProfile? _profile;
  bool _loading = false;
  bool _saving = false;
  bool _disposed = false;
  String? _errorCode;
  NicknameValidationError? _validationError;

  PublicProfile? get profile => _profile;
  String? get nickname => _profile?.nickname;
  bool get hasNickname =>
      _profile != null && _profile!.nickname.trim().isNotEmpty;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get errorCode => _errorCode;
  NicknameValidationError? get validationError => _validationError;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _onAuthChanged() {
    if (_disposed) return;
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final uid = _auth.uid;
    _validationError = null;
    if (uid == null || uid.isEmpty || !_auth.isSignedIn) {
      _profile = null;
      _errorCode = null;
      _loading = false;
      _safeNotify();
      return;
    }

    _loading = true;
    _errorCode = null;
    _safeNotify();
    try {
      _profile = await _repository.getProfile(uid);
    } on ProfileUnavailableException {
      _errorCode = 'firestore_unavailable';
      _profile = null;
    } on ProfilePermissionDeniedException {
      _errorCode = 'permission_denied';
      _profile = null;
    } catch (_) {
      _errorCode = 'load_failed';
      _profile = null;
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  /// Validates and saves. Does not use Google displayName automatically.
  Future<bool> saveNickname(String raw) async {
    if (_disposed) return false;
    if (_saving) return false;

    final uid = _auth.uid;
    if (uid == null || uid.isEmpty || !_auth.isSignedIn) {
      _errorCode = 'not_signed_in';
      _safeNotify();
      return false;
    }

    final validated = NicknameValidator.validate(raw);
    if (!validated.isValid) {
      _validationError = validated.error;
      _errorCode = null;
      _safeNotify();
      return false;
    }

    _saving = true;
    _validationError = null;
    _errorCode = null;
    _safeNotify();
    try {
      _profile = await _repository.saveNickname(
        uid: uid,
        nickname: validated.nickname!,
      );
      return true;
    } on ProfileNotSignedInException {
      _errorCode = 'not_signed_in';
      return false;
    } on ProfilePermissionDeniedException {
      _errorCode = 'permission_denied';
      return false;
    } on ProfileUnavailableException {
      _errorCode = 'firestore_unavailable';
      return false;
    } on ProfileInvalidNicknameException {
      _validationError = NicknameValidationError.invalidCharacters;
      return false;
    } catch (_) {
      _errorCode = 'save_failed';
      return false;
    } finally {
      _saving = false;
      _safeNotify();
    }
  }


  /// Lookup helper for future share UI (ownerUid → current nickname).
  Future<String?> nicknameForUid(String uid) async {
    if (uid.isEmpty) return null;
    if (_profile?.uid == uid) return _profile?.nickname;
    try {
      return (await _repository.getProfile(uid))?.nickname;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

class PublicProfileScope extends InheritedNotifier<PublicProfileController> {
  const PublicProfileScope({
    super.key,
    required PublicProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static PublicProfileController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PublicProfileScope>();
    assert(scope != null, 'PublicProfileScope not found');
    return scope!.notifier!;
  }

  static PublicProfileController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PublicProfileScope>()
        ?.notifier;
  }
}
