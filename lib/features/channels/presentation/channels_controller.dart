import 'package:flutter/material.dart';

import '../../../shared/models/play_order.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/repositories/channel_repository.dart';
import '../../../shared/repositories/content_repository.dart';
import '../../../shared/repositories/playback_progress_repository.dart';

class ChannelsController extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  ChannelsController({
    required ChannelRepository repository,
    ContentRepository? contentRepository,
    PlaybackProgressRepository? progressRepository,
  }) : _repository = repository,
       _contentRepository = contentRepository,
       _progressRepository = progressRepository;

  final ChannelRepository _repository;
  final ContentRepository? _contentRepository;
  final PlaybackProgressRepository? _progressRepository;

  List<TupicChannel> _channels = const [];
  String? _lastSelectedChannelId;
  bool _loading = false;
  String? _errorMessage;

  List<TupicChannel> get channels => _channels;
  String? get lastSelectedChannelId => _lastSelectedChannelId;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  TupicChannel? get lastSelectedChannel {
    final id = _lastSelectedChannelId;
    if (id == null) return null;
    for (final channel in _channels) {
      if (channel.id == id) return channel;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _channels = await _repository.getChannels();
      _lastSelectedChannelId = await _repository.getLastSelectedChannelId();
    } catch (error) {
      _errorMessage = error.toString();
      _channels = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<TupicChannel> createChannel({
    required String name,
    required bool isKidsChannel,
  }) async {
    final channel = await _repository.createChannel(
      name: name,
      isKidsChannel: isKidsChannel,
    );
    await load();
    return channel;
  }

  Future<TupicChannel> renameChannel({
    required String id,
    required String name,
  }) async {
    final channel = await _repository.renameChannel(id: id, name: name);
    await load();
    return channel;
  }

  Future<TupicChannel> updatePlayOrder({
    required String id,
    required PlayOrder playOrder,
  }) async {
    final channel = await _repository.updatePlayOrder(
      id: id,
      playOrder: playOrder,
    );
    await load();
    return channel;
  }

  Future<void> deleteChannel(String id) async {
    await _contentRepository?.deleteAllForChannel(id);
    await _progressRepository?.clearProgress(id);
    await _repository.deleteChannel(id);
    await load();
  }

  Future<void> refreshVideoCount(String id, int videoCount) async {
    await _repository.updateVideoCount(id: id, videoCount: videoCount);
    await load();
  }

  Future<void> selectChannel(String id) async {
    await _repository.setLastSelectedChannelId(id);
    _lastSelectedChannelId = id;
    notifyListeners();
  }
}

class ChannelsScope extends InheritedNotifier<ChannelsController> {
  const ChannelsScope({
    super.key,
    required ChannelsController controller,
    required super.child,
  }) : super(notifier: controller);

  static ChannelsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChannelsScope>();
    assert(scope != null, 'ChannelsScope not found');
    return scope!.notifier!;
  }

  static ChannelsController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChannelsScope>()?.notifier;
  }
}
