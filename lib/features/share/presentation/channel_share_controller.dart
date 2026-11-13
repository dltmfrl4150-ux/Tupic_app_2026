import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/models/channel_video.dart';
import '../../../shared/models/content_source.dart';
import '../../../shared/models/share_models.dart';
import '../../../shared/models/shared_channel_category.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/repositories/channel_share_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/public_profile_controller.dart';

class ChannelShareController extends ChangeNotifier {
  ChannelShareController({
    required AuthController authController,
    required PublicProfileController profileController,
    required ChannelShareRepository repository,
  }) : _auth = authController,
       _profile = profileController,
       _repository = repository;

  final AuthController _auth;
  final PublicProfileController _profile;
  final ChannelShareRepository _repository;

  bool _publishing = false;
  bool _loadingMine = false;
  String? _errorCode;
  List<SharePost> _myPosts = const [];

  bool get publishing => _publishing;
  bool get loadingMine => _loadingMine;
  String? get errorCode => _errorCode;
  List<SharePost> get myPosts => _myPosts;
  bool get isSignedIn => _auth.isSignedIn && (_auth.uid?.isNotEmpty ?? false);
  bool get hasNickname => _profile.hasNickname;
  String? get nickname => _profile.nickname;
  String? get uid => _auth.uid;

  Future<ShareGroup?> findGroupForChannel(String sourceChannelId) async {
    final ownerUid = _auth.uid;
    if (ownerUid == null || ownerUid.isEmpty) return null;
    try {
      return await _repository.findGroup(
        ownerUid: ownerUid,
        sourceChannelId: sourceChannelId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<SharePost?> publish({
    required TupicChannel channel,
    required List<ChannelVideo> videos,
    required List<ContentSource> sources,
    required SharedChannelCategory category,
    String? description,
  }) async {
    if (_publishing) return null;
    final ownerUid = _auth.uid;
    if (ownerUid == null || ownerUid.isEmpty || !_auth.isSignedIn) {
      _errorCode = 'not_signed_in';
      notifyListeners();
      return null;
    }
    if (!_profile.hasNickname) {
      _errorCode = 'nickname_required';
      notifyListeners();
      return null;
    }
    if (category == SharedChannelCategory.all) {
      _errorCode = 'invalid_category';
      notifyListeners();
      return null;
    }

    _publishing = true;
    _errorCode = null;
    notifyListeners();
    try {
      if (kDebugMode) {
        debugPrint(
          'ChannelShare publish start: '
          'channelIdLen=${channel.id.length} '
          'videoCount=${videos.where((v) => !v.isExcluded).length} '
          'category=${category.name}',
        );
      }
      final post = await _repository.publish(
        SharePublishRequest(
          ownerUid: ownerUid,
          channel: channel,
          videos: videos,
          sources: sources,
          category: category,
          description: description,
        ),
      );
      _myPosts = [post, ..._myPosts.where((p) => p.id != post.id)];
      if (kDebugMode) {
        debugPrint(
          'ChannelShare publish ok: version=${post.version} postIdLen=${post.id.length}',
        );
      }
      return post;
    } on ShareNotSignedInException {
      _errorCode = 'not_signed_in';
      return null;
    } on SharePermissionDeniedException {
      _errorCode = 'permission_denied';
      if (kDebugMode) {
        debugPrint(
          'ChannelShare publish denied (Firestore permission-denied or '
          'owner mismatch). Redeploy rules with getAfter/existsAfter if '
          'local rules were fixed but Console was not.',
        );
      }
      return null;
    } on ShareUnavailableException {
      _errorCode = 'unavailable';
      return null;
    } on ShareValidationException catch (e) {
      _errorCode = e.code;
      if (kDebugMode) {
        debugPrint('ChannelShare publish validation: ${e.code}');
      }
      return null;
    } catch (e) {
      _errorCode = 'publish_failed';
      if (kDebugMode) {
        debugPrint('ChannelShare publish failed: ${e.runtimeType}');
      }
      return null;
    } finally {
      _publishing = false;
      notifyListeners();
    }
  }

  Future<void> refreshMyPosts() async {
    final ownerUid = _auth.uid;
    if (ownerUid == null || ownerUid.isEmpty || !_auth.isSignedIn) {
      _myPosts = const [];
      _errorCode = null;
      notifyListeners();
      return;
    }
    _loadingMine = true;
    _errorCode = null;
    notifyListeners();
    try {
      _myPosts = await _repository.listMyPosts(ownerUid: ownerUid);
    } on ShareUnavailableException {
      _errorCode = 'unavailable';
      _myPosts = const [];
    } on SharePermissionDeniedException {
      _errorCode = 'permission_denied';
      _myPosts = const [];
    } catch (_) {
      _errorCode = 'load_failed';
      _myPosts = const [];
    } finally {
      _loadingMine = false;
      notifyListeners();
    }
  }

  Future<bool> cancelPost(String postId) async {
    final ownerUid = _auth.uid;
    if (ownerUid == null || ownerUid.isEmpty || !_auth.isSignedIn) {
      _errorCode = 'not_signed_in';
      notifyListeners();
      return false;
    }
    try {
      final updated = await _repository.cancelPost(
        ownerUid: ownerUid,
        postId: postId,
      );
      _myPosts = _myPosts
          .map((p) => p.id == updated.id ? updated : p)
          .toList(growable: false);
      notifyListeners();
      return true;
    } on SharePermissionDeniedException {
      _errorCode = 'permission_denied';
      notifyListeners();
      return false;
    } on ShareUnavailableException {
      _errorCode = 'unavailable';
      notifyListeners();
      return false;
    } catch (_) {
      _errorCode = 'cancel_failed';
      notifyListeners();
      return false;
    }
  }
}

class ChannelShareScope extends InheritedNotifier<ChannelShareController> {
  const ChannelShareScope({
    super.key,
    required ChannelShareController controller,
    required super.child,
  }) : super(notifier: controller);

  static ChannelShareController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ChannelShareScope>();
    assert(scope != null, 'ChannelShareScope not found');
    return scope!.notifier!;
  }

  static ChannelShareController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ChannelShareScope>()
        ?.notifier;
  }
}
