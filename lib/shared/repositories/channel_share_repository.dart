import '../models/share_models.dart';
import '../models/shared_channel_category.dart';
import '../models/tupic_channel.dart';
import '../models/channel_video.dart';
import '../models/content_source.dart';

class SharePublishRequest {
  const SharePublishRequest({
    required this.ownerUid,
    required this.channel,
    required this.videos,
    required this.sources,
    required this.category,
    this.description,
  });

  final String ownerUid;
  final TupicChannel channel;
  final List<ChannelVideo> videos;
  final List<ContentSource> sources;
  final SharedChannelCategory category;
  final String? description;
}

abstract class ChannelShareRepository {
  Future<ShareGroup?> findGroup({
    required String ownerUid,
    required String sourceChannelId,
  });

  Future<SharePost> publish(SharePublishRequest request);

  Future<List<SharePost>> listMyPosts({
    required String ownerUid,
    int limit = 50,
  });

  Future<SharePost> cancelPost({
    required String ownerUid,
    required String postId,
  });
}

class ChannelShareException implements Exception {
  const ChannelShareException(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() => 'ChannelShareException($code)';
}

class ShareNotSignedInException extends ChannelShareException {
  const ShareNotSignedInException() : super('not_signed_in');
}

class SharePermissionDeniedException extends ChannelShareException {
  const SharePermissionDeniedException() : super('permission_denied');
}

class ShareUnavailableException extends ChannelShareException {
  const ShareUnavailableException([String? message])
      : super('unavailable', message);
}

class ShareValidationException extends ChannelShareException {
  const ShareValidationException(super.code);
}
