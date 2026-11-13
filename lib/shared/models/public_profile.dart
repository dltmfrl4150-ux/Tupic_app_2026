/// Public publisher profile for shared channels (not Google account display).
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.nickname,
    required this.updatedAt,
    this.createdAt,
  });

  final String uid;
  final String nickname;
  final DateTime updatedAt;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'updatedAt': updatedAt,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  static PublicProfile? fromMap(
    Map<String, dynamic>? data, {
    required String uid,
    DateTime? updatedAtFallback,
  }) {
    if (data == null) return null;
    final nickname = data['nickname'];
    if (nickname is! String || nickname.trim().isEmpty) return null;
    final updatedAt = _parseTimestamp(data['updatedAt']) ??
        updatedAtFallback ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return PublicProfile(
      uid: uid,
      nickname: nickname.trim(),
      updatedAt: updatedAt,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    // Firestore Timestamp (avoid hard import in the model).
    try {
      final dynamic value = raw;
      final date = value.toDate();
      if (date is DateTime) return date;
    } catch (_) {}
    if (raw is Map) {
      final seconds = raw['seconds'] ?? raw['_seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return null;
  }
}
