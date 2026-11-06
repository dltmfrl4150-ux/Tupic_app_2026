import 'package:flutter/foundation.dart';

import '../../../shared/models/content_category.dart';
import '../../../shared/models/home_feed.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/repositories/home_repository.dart';
import '../../channels/presentation/channels_controller.dart';

class HomeController extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  HomeController({
    required HomeRepository repository,
    required ChannelsController channelsController,
  }) : _repository = repository,
       _channelsController = channelsController {
    _channelsController.addListener(_onChannelsChanged);
  }

  final HomeRepository _repository;
  final ChannelsController _channelsController;

  HomeFeedState _state = const HomeFeedLoading();
  ContentCategory _selectedCategory = ContentCategory.all;
  AudiencePreference? _audienceOverride;
  List<TupicChannel> _userChannels = const [];

  HomeFeedState get state => _state;
  ContentCategory get selectedCategory => _selectedCategory;
  AudiencePreference? get audienceOverride => _audienceOverride;
  List<TupicChannel> get userChannels => _userChannels;

  void _onChannelsChanged() {
    _userChannels = _channelsController.channels;
    final current = _state;
    if (current is HomeFeedReady) {
      _state = HomeFeedReady(
        current.feed.copyWith(channels: _userChannels),
      );
      notifyListeners();
    } else if (current is HomeFeedEmpty) {
      // Promote empty shell to ready when channels appear while demo rails load.
      load();
    }
  }

  Future<void> load() async {
    _state = const HomeFeedLoading();
    notifyListeners();
    try {
      if (_channelsController.channels.isEmpty &&
          !_channelsController.loading) {
        await _channelsController.load();
      }
      _userChannels = _channelsController.channels;

      final demo = await _repository.fetchHomeFeed(
        audienceOverride: _audienceOverride ??
            _audienceFromLastChannel(_channelsController.lastSelectedChannel),
      );

      final feed = HomeFeed(
        userDisplayName: demo.userDisplayName,
        channels: _userChannels,
        recommended: demo.recommended,
        exploreVideos: demo.exploreVideos,
        lastAudience: _audienceOverride ??
            demo.lastAudience ??
            _audienceFromLastChannel(_channelsController.lastSelectedChannel),
        isMock: true,
      );

      if (feed.channels.isEmpty &&
          feed.recommended.isEmpty &&
          feed.exploreVideos.isEmpty) {
        _state = HomeFeedEmpty(
          userDisplayName: feed.userDisplayName,
          isMock: feed.isMock,
        );
      } else {
        _state = HomeFeedReady(feed);
      }
    } catch (error) {
      _state = HomeFeedError(error.toString());
    }
    notifyListeners();
  }

  AudiencePreference? _audienceFromLastChannel(TupicChannel? channel) {
    if (channel == null) return null;
    return channel.isKidsChannel
        ? AudiencePreference.kids
        : AudiencePreference.general;
  }

  void selectCategory(ContentCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> setAudience(AudiencePreference audience) async {
    _audienceOverride = audience;
    await load();
  }

  @override
  void dispose() {
    _channelsController.removeListener(_onChannelsChanged);
    super.dispose();
  }
}
