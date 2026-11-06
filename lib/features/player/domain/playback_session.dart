import '../../../shared/models/channel_video.dart';
import 'playback_phase.dart';

/// Pure playback-session state (no YouTube / WebView dependency).
class PlaybackSession {
  PlaybackSession({
    required List<ChannelVideo> queue,
    int initialIndex = 0,
    this.isKidsChannel = false,
  }) : queue = List<ChannelVideo>.unmodifiable(queue),
       currentIndex = queue.isEmpty
           ? -1
           : initialIndex.clamp(0, queue.length - 1),
       phase = queue.isEmpty
           ? PlaybackPhase.empty
           : PlaybackPhase.initializing;

  final List<ChannelVideo> queue;
  final bool isKidsChannel;

  int currentIndex;
  PlaybackPhase phase;
  bool locked = false;
  bool queuePanelOpen = false;
  bool overlayVisible = true;
  bool useSeparateQueueScreen = false;
  String? errorMessage;

  bool _handlingEnded = false;
  DateTime? _lastEndedAt;
  String? _lastEndedVideoId;

  ChannelVideo? get currentVideo =>
      (currentIndex >= 0 && currentIndex < queue.length)
      ? queue[currentIndex]
      : null;

  bool get hasNext => currentIndex >= 0 && currentIndex < queue.length - 1;

  bool get hasPrevious => currentIndex > 0;

  bool get isEmpty => queue.isEmpty;

  void setPhase(PlaybackPhase value, {String? error}) {
    phase = value;
    if (error != null) errorMessage = error;
  }

  /// Returns true when the index changed to the next video.
  bool selectIndex(int index) {
    if (locked) return false;
    if (index < 0 || index >= queue.length) return false;
    currentIndex = index;
    _handlingEnded = false;
    phase = PlaybackPhase.loading;
    errorMessage = null;
    return true;
  }

  /// Advances after a video ends. Duplicate ended events within 2s for the
  /// same video id are ignored. Returns whether the index advanced.
  bool onVideoEnded({DateTime? now}) {
    final videoId = currentVideo?.youtubeVideoId;
    final at = now ?? DateTime.now();
    if (_handlingEnded) return false;
    if (videoId != null &&
        _lastEndedVideoId == videoId &&
        _lastEndedAt != null &&
        at.difference(_lastEndedAt!) < const Duration(seconds: 2)) {
      return false;
    }
    _handlingEnded = true;
    _lastEndedAt = at;
    _lastEndedVideoId = videoId;
    phase = PlaybackPhase.ended;

    if (hasNext) {
      currentIndex += 1;
      _handlingEnded = false;
      phase = PlaybackPhase.loading;
      return true;
    }
    phase = PlaybackPhase.queueComplete;
    overlayVisible = true;
    return false;
  }

  void markPlaying() {
    _handlingEnded = false;
    phase = PlaybackPhase.playing;
  }

  void markPaused() {
    if (phase == PlaybackPhase.ended ||
        phase == PlaybackPhase.queueComplete) {
      return;
    }
    phase = PlaybackPhase.paused;
  }

  void markLoading() {
    phase = PlaybackPhase.loading;
  }

  void markError(String message, {bool unavailable = false}) {
    phase = unavailable
        ? PlaybackPhase.unavailable
        : PlaybackPhase.error;
    errorMessage = message;
  }

  void markAllUnavailable([String? message]) {
    phase = PlaybackPhase.allUnavailable;
    errorMessage = message;
    overlayVisible = true;
  }

  /// Finds the next queue index after [fromIndex] whose id is not in [failedIds].
  /// Returns -1 when none remain.
  int nextPlayableIndex({
    required int fromIndex,
    required Set<String> failedIds,
  }) {
    for (var i = fromIndex + 1; i < queue.length; i++) {
      if (!failedIds.contains(queue[i].youtubeVideoId)) return i;
    }
    return -1;
  }

  void setLocked(bool value) {
    locked = value;
    if (value) {
      queuePanelOpen = false;
      overlayVisible = true;
      useSeparateQueueScreen = false;
    }
  }

  void toggleQueuePanel() {
    if (locked) return;
    queuePanelOpen = !queuePanelOpen;
    overlayVisible = true;
  }

  void setQueuePanelOpen(bool open) {
    if (locked && open) return;
    queuePanelOpen = open;
  }

  void setUseSeparateQueueScreen(bool value) {
    useSeparateQueueScreen = value;
  }

  void showOverlay() {
    overlayVisible = true;
  }

  void hideOverlay() {
    if (locked || queuePanelOpen || useSeparateQueueScreen) return;
    overlayVisible = false;
  }
}
