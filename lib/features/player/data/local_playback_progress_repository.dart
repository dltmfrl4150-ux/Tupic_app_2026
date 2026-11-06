import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/channel_playback_progress.dart';
import '../../../shared/repositories/playback_progress_repository.dart';

/// SharedPreferences map keyed by TUPIC channel id.
class LocalPlaybackProgressRepository implements PlaybackProgressRepository {
  LocalPlaybackProgressRepository({
    SharedPreferences? prefs,
    this.storageKey = 'tupic_playback_progress_v1',
  }) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  final String storageKey;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  /// Serializes read-modify-write so overlapping saves cannot reorder.
  Future<void> _writeChain = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final done = _writeChain.then((_) => action());
    _writeChain = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  Future<Map<String, ChannelPlaybackProgress>> _readAllUnlocked(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, ChannelPlaybackProgress>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! Map) continue;
        final progress = ChannelPlaybackProgress.fromJson(
          Map<String, dynamic>.from(value),
        );
        if (progress != null) {
          result[key] = progress;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<ChannelPlaybackProgress?> getProgress(String tupicChannelId) {
    return _enqueue(() async {
      final prefs = await _prefs;
      final all = await _readAllUnlocked(prefs);
      return all[tupicChannelId];
    });
  }

  @override
  Future<void> saveProgress(ChannelPlaybackProgress progress) {
    return _enqueue(() async {
      final prefs = await _prefs;
      final all = await _readAllUnlocked(prefs);
      all[progress.tupicChannelId] = progress;
      final encoded = jsonEncode({
        for (final e in all.entries) e.key: e.value.toJson(),
      });
      await prefs.setString(storageKey, encoded);
    });
  }

  @override
  Future<void> clearProgress(String tupicChannelId) {
    return _enqueue(() async {
      final prefs = await _prefs;
      final all = await _readAllUnlocked(prefs);
      if (!all.containsKey(tupicChannelId)) return;
      all.remove(tupicChannelId);
      final encoded = jsonEncode({
        for (final e in all.entries) e.key: e.value.toJson(),
      });
      await prefs.setString(storageKey, encoded);
    });
  }

  @override
  Future<void> clearAll() {
    return _enqueue(() async {
      final prefs = await _prefs;
      await prefs.remove(storageKey);
    });
  }
}
