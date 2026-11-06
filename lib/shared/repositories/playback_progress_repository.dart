import '../models/channel_playback_progress.dart';

abstract class PlaybackProgressRepository {
  Future<ChannelPlaybackProgress?> getProgress(String tupicChannelId);

  Future<void> saveProgress(ChannelPlaybackProgress progress);

  Future<void> clearProgress(String tupicChannelId);

  Future<void> clearAll();
}
