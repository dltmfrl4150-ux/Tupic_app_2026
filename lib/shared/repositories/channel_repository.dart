import '../models/play_order.dart';
import '../models/tupic_channel.dart';

/// Abstraction for TUPIC channel persistence (local now, Firestore later).
abstract class ChannelRepository {
  Future<List<TupicChannel>> getChannels();

  Future<TupicChannel?> getChannel(String id);

  Future<String?> getLastSelectedChannelId();

  Future<void> setLastSelectedChannelId(String? id);

  Future<TupicChannel> createChannel({
    required String name,
    required bool isKidsChannel,
  });

  Future<TupicChannel> renameChannel({
    required String id,
    required String name,
  });

  Future<TupicChannel> updatePlayOrder({
    required String id,
    required PlayOrder playOrder,
  });

  Future<TupicChannel> updateVideoCount({
    required String id,
    required int videoCount,
  });

  Future<void> deleteChannel(String id);
}

class ChannelLimitExceededException implements Exception {
  const ChannelLimitExceededException(this.maxChannels);

  final int maxChannels;

  @override
  String toString() => 'ChannelLimitExceededException($maxChannels)';
}

class ChannelNotFoundException implements Exception {
  const ChannelNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'ChannelNotFoundException($id)';
}

class InvalidChannelNameException implements Exception {
  const InvalidChannelNameException();

  @override
  String toString() => 'InvalidChannelNameException';
}
