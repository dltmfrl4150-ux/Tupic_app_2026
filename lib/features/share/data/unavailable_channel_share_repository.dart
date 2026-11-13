import '../../../shared/models/share_models.dart';
import '../../../shared/repositories/channel_share_repository.dart';

class UnavailableChannelShareRepository implements ChannelShareRepository {
  const UnavailableChannelShareRepository([this.message]);

  final String? message;

  @override
  Future<ShareGroup?> findGroup({
    required String ownerUid,
    required String sourceChannelId,
  }) async {
    throw ShareUnavailableException(message);
  }

  @override
  Future<SharePost> publish(SharePublishRequest request) async {
    throw ShareUnavailableException(message);
  }

  @override
  Future<List<SharePost>> listMyPosts({
    required String ownerUid,
    int limit = 50,
  }) async {
    throw ShareUnavailableException(message);
  }

  @override
  Future<SharePost> cancelPost({
    required String ownerUid,
    required String postId,
  }) async {
    throw ShareUnavailableException(message);
  }
}
