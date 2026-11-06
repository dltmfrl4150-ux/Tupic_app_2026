import 'play_order.dart';
import 'video_item.dart';

/// A TUPIC user-created channel (not a YouTube creator channel).
class TupicChannel {
  const TupicChannel({
    required this.id,
    required this.name,
    required this.isKidsChannel,
    required this.videoCount,
    required this.accentColor,
    required this.createdAt,
    this.playOrder = PlayOrder.sequential,
    this.coverLabel,
  });

  final String id;
  final String name;
  final bool isKidsChannel;
  final int videoCount;
  final ColorSeed accentColor;
  final DateTime createdAt;
  final PlayOrder playOrder;
  final String? coverLabel;

  TupicChannel copyWith({
    String? id,
    String? name,
    bool? isKidsChannel,
    int? videoCount,
    ColorSeed? accentColor,
    DateTime? createdAt,
    PlayOrder? playOrder,
    String? coverLabel,
  }) {
    return TupicChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      isKidsChannel: isKidsChannel ?? this.isKidsChannel,
      videoCount: videoCount ?? this.videoCount,
      accentColor: accentColor ?? this.accentColor,
      createdAt: createdAt ?? this.createdAt,
      playOrder: playOrder ?? this.playOrder,
      coverLabel: coverLabel ?? this.coverLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isKidsChannel': isKidsChannel,
      'videoCount': videoCount,
      'accentColor': accentColor.value,
      'createdAt': createdAt.toIso8601String(),
      'playOrder': playOrder.storageValue,
      'coverLabel': coverLabel,
    };
  }

  static TupicChannel? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      final id = json['id'];
      final name = json['name'];
      if (id is! String || name is! String || name.trim().isEmpty) {
        return null;
      }
      final createdRaw = json['createdAt'];
      final createdAt = createdRaw is String
          ? DateTime.tryParse(createdRaw) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);
      final accent = json['accentColor'];
      return TupicChannel(
        id: id,
        name: name,
        isKidsChannel: json['isKidsChannel'] == true,
        videoCount: (json['videoCount'] is int) ? json['videoCount'] as int : 0,
        accentColor: ColorSeed(accent is int ? accent : 0xFF6B4C9A),
        createdAt: createdAt,
        playOrder: PlayOrderX.fromStorage(
          json['playOrder'] is String ? json['playOrder'] as String : null,
        ),
        coverLabel: json['coverLabel'] is String
            ? json['coverLabel'] as String
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
