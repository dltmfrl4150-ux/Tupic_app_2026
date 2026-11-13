/// Client-side nickname rules for publicProfiles (mirrored in firestore.rules).
enum NicknameValidationError {
  empty,
  tooShort,
  tooLong,
  invalidCharacters,
  inappropriate,
}

class NicknameValidationResult {
  const NicknameValidationResult.ok(this.nickname) : error = null;
  const NicknameValidationResult.invalid(this.error) : nickname = null;

  final String? nickname;
  final NicknameValidationError? error;

  bool get isValid => error == null && nickname != null;
}

abstract final class NicknameValidator {
  static const minLength = 2;
  static const maxLength = 20;

  /// Letters, numbers, Hangul syllables, spaces, . _ - (no @ to avoid emails).
  static final _allowed = RegExp(
    r'^[\p{L}\p{N}._\- ]+$',
    unicode: true,
  );

  static final _emailLike = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Minimal blocklist — not a full moderation system.
  static const _blocked = <String>{
    'admin',
    'administrator',
    'tupic',
    'official',
    'fuck',
    'shit',
    'bitch',
    'asshole',
    '씨발',
    '시발',
    '병신',
    '지랄',
    '좆',
    '니미',
    '새끼',
  };

  static NicknameValidationResult validate(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      return const NicknameValidationResult.invalid(
        NicknameValidationError.empty,
      );
    }
    if (trimmed.length < minLength) {
      return const NicknameValidationResult.invalid(
        NicknameValidationError.tooShort,
      );
    }
    if (trimmed.length > maxLength) {
      return const NicknameValidationResult.invalid(
        NicknameValidationError.tooLong,
      );
    }
    if (_emailLike.hasMatch(trimmed) || trimmed.contains('@')) {
      return const NicknameValidationResult.invalid(
        NicknameValidationError.invalidCharacters,
      );
    }
    if (!_allowed.hasMatch(trimmed)) {
      return const NicknameValidationResult.invalid(
        NicknameValidationError.invalidCharacters,
      );
    }
    final folded = trimmed.toLowerCase().replaceAll(' ', '');
    for (final word in _blocked) {
      if (folded.contains(word.toLowerCase())) {
        return const NicknameValidationResult.invalid(
          NicknameValidationError.inappropriate,
        );
      }
    }
    return NicknameValidationResult.ok(trimmed);
  }
}
