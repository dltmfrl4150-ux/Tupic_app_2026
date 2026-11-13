import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/plan_limits.dart';
import '../../../shared/models/play_order.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/models/video_item.dart';
import '../../../shared/repositories/channel_repository.dart';

const _channelsKey = 'tupic_user_channels_v1';
const _lastSelectedKey = 'tupic_last_selected_channel_id';

const _accentPalette = <int>[
  0xFF6B4C9A,
  0xFF4A6FA5,
  0xFF3D5A4C,
  0xFF8A5A4A,
  0xFF5A4A6A,
  0xFF3A6A8A,
];

/// Persists user channels in SharedPreferences as JSON.
/// Corrupt payloads are ignored so the app keeps running.
class LocalChannelRepository implements ChannelRepository {
  LocalChannelRepository({
    SharedPreferences? prefs,
    this.freeMaxChannels = PlanLimits.freeMaxChannels,
    Random? random,
  }) : _prefsOverride = prefs,
       _random = random ?? Random();

  final SharedPreferences? _prefsOverride;
  final int freeMaxChannels;
  final Random _random;
  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> _prefs() async {
    return _cachedPrefs ??=
        _prefsOverride ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<TupicChannel>> getChannels() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_channelsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final channels = <TupicChannel>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final channel = TupicChannel.fromJson(item);
          if (channel != null) channels.add(channel);
        } else if (item is Map) {
          final channel = TupicChannel.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          );
          if (channel != null) channels.add(channel);
        }
      }
      channels.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return channels;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<TupicChannel?> getChannel(String id) async {
    final channels = await getChannels();
    for (final channel in channels) {
      if (channel.id == id) return channel;
    }
    return null;
  }

  @override
  Future<String?> getLastSelectedChannelId() async {
    final prefs = await _prefs();
    return prefs.getString(_lastSelectedKey);
  }

  @override
  Future<void> setLastSelectedChannelId(String? id) async {
    final prefs = await _prefs();
    if (id == null || id.isEmpty) {
      await prefs.remove(_lastSelectedKey);
    } else {
      await prefs.setString(_lastSelectedKey, id);
    }
  }

  @override
  Future<TupicChannel> createChannel({
    required String name,
    required bool isKidsChannel,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const InvalidChannelNameException();
    }

    final existing = await getChannels();
    final maxChannels = PlanLimits.isPremium
        ? PlanLimits.maxChannels(premium: true)
        : freeMaxChannels;
    if (existing.length >= maxChannels) {
      throw ChannelLimitExceededException(maxChannels);
    }

    final channel = TupicChannel(
      id: 'ch_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
      name: trimmed,
      isKidsChannel: isKidsChannel,
      videoCount: 0,
      accentColor: ColorSeed(
        _accentPalette[existing.length % _accentPalette.length],
      ),
      createdAt: DateTime.now(),
      playOrder: PlayOrder.oldestAdded,
      coverLabel: isKidsChannel ? 'KIDS' : 'CH',
    );

    final next = [...existing, channel];
    await _save(next);
    await setLastSelectedChannelId(channel.id);
    return channel;
  }

  @override
  Future<TupicChannel> renameChannel({
    required String id,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const InvalidChannelNameException();
    }
    return _update(id, (channel) => channel.copyWith(name: trimmed));
  }

  @override
  Future<TupicChannel> updatePlayOrder({
    required String id,
    required PlayOrder playOrder,
  }) {
    return _update(id, (channel) => channel.copyWith(playOrder: playOrder));
  }

  @override
  Future<TupicChannel> updateVideoCount({
    required String id,
    required int videoCount,
  }) {
    return _update(
      id,
      (channel) => channel.copyWith(videoCount: videoCount < 0 ? 0 : videoCount),
    );
  }

  @override
  Future<void> deleteChannel(String id) async {
    final existing = await getChannels();
    final next = existing.where((channel) => channel.id != id).toList();
    await _save(next);

    final lastSelected = await getLastSelectedChannelId();
    if (lastSelected == id) {
      await setLastSelectedChannelId(next.isEmpty ? null : next.last.id);
    }
  }

  Future<TupicChannel> _update(
    String id,
    TupicChannel Function(TupicChannel channel) transform,
  ) async {
    final existing = await getChannels();
    final index = existing.indexWhere((channel) => channel.id == id);
    if (index < 0) {
      throw ChannelNotFoundException(id);
    }
    final updated = transform(existing[index]);
    final next = [...existing];
    next[index] = updated;
    await _save(next);
    return updated;
  }

  Future<void> _save(List<TupicChannel> channels) async {
    final prefs = await _prefs();
    final payload = jsonEncode(
      channels.map((channel) => channel.toJson()).toList(),
    );
    await prefs.setString(_channelsKey, payload);
  }
}
