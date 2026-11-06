import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../shared/models/channel_video.dart';
import '../../../shared/models/play_order.dart';
import '../../../shared/repositories/playback_progress_repository.dart';
import '../../../shared/models/channel_playback_progress.dart';
import '../domain/playback_phase.dart';
import '../domain/playback_session.dart';

/// Owns one viewing session: pure [PlaybackSession] + YouTube IFrame controller.
class PlayerSessionController extends ChangeNotifier {
  PlayerSessionController({
    required List<ChannelVideo> queue,
    required this.tupicChannelId,
    required this.playOrder,
    int initialIndex = 0,
    this.initialStartSeconds = 0,
    bool isKidsChannel = false,
    PlaybackProgressRepository? progressRepository,
  }) : _progressRepository = progressRepository,
       session = PlaybackSession(
         queue: queue,
         initialIndex: initialIndex,
         isKidsChannel: isKidsChannel,
       );

  final PlaybackSession session;
  final String tupicChannelId;
  final PlayOrder playOrder;
  final double initialStartSeconds;
  final PlaybackProgressRepository? _progressRepository;

  YoutubePlayerController? _player;
  StreamSubscription<YoutubePlayerValue>? _playerSub;
  StreamSubscription<YoutubeVideoState>? _videoStateSub;
  Timer? _overlayTimer;
  Timer? _progressTimer;
  Timer? _autoplayWatchdog;

  bool _initialLoadStarted = false;
  bool _loadInFlight = false;
  int _loadToken = 0;
  bool _needsUserPlay = false;
  bool _disposed = false;
  bool _autoSkipInFlight = false;
  /// User/session intends playback (channel entry, next, retry) — not a timer.
  bool _autoplayIntent = false;
  /// One playVideo() kick after Ready/cued for the current intent.
  bool _autoplayKickAttempted = false;
  double _lastKnownPosition = 0;
  Future<void> _persistChain = Future<void>.value();
  final Set<String> _failedVideoIds = {};

  YoutubePlayerController? get player => _player;
  bool get needsUserPlay => _needsUserPlay;

  List<ChannelVideo> get queue => session.queue;
  int get currentIndex => session.currentIndex;
  PlaybackPhase get phase => session.phase;
  bool get locked => session.locked;
  bool get queuePanelOpen => session.queuePanelOpen;
  bool get overlayVisible => session.overlayVisible;
  bool get useSeparateQueueScreen => session.useSeparateQueueScreen;
  String? get errorMessage => session.errorMessage;
  ChannelVideo? get currentVideo => session.currentVideo;
  bool get hasNext => session.hasNext;
  bool get hasPrevious => session.hasPrevious;
  bool get isKidsChannel => session.isKidsChannel;

  /// Creates the IFrame controller once with the first video id so the package
  /// queues load/cue until Ready — avoids black screen from pre-ready loads.
  Future<void> initialize() async {
    if (session.isEmpty) {
      session.setPhase(PlaybackPhase.empty);
      notifyListeners();
      return;
    }
    session.markLoading();
    _beginAutoplayIntent();
    notifyListeners();
    await _ensurePlayerForCurrent(
      autoPlay: true,
      startSeconds: initialStartSeconds,
      isInitial: true,
    );
    _scheduleOverlayHide();
    _startProgressTicker();
  }

  void _beginAutoplayIntent() {
    _autoplayIntent = true;
    _autoplayKickAttempted = false;
    _needsUserPlay = false;
  }

  Future<void> _kickAutoplayOnce() async {
    if (_disposed || _player == null || !_autoplayIntent) return;
    try {
      await _player!.playVideo();
    } catch (_) {
      // Platform may block unmuted autoplay; watchdog may show a play CTA.
    }
  }

  Future<void> _ensurePlayerForCurrent({
    required bool autoPlay,
    double startSeconds = 0,
    bool isInitial = false,
  }) async {
    final video = session.currentVideo;
    if (video == null) return;

    final safeStart = startSeconds.isFinite && startSeconds > 0
        ? startSeconds
        : 0.0;

    if (_player == null) {
      if (autoPlay) _beginAutoplayIntent();
      // fromVideoId queues load/cue until the WebView Ready event.
      // Mount YoutubePlayer after this so Ready can flush the queue.
      _player = YoutubePlayerController.fromVideoId(
        videoId: video.youtubeVideoId,
        autoPlay: autoPlay,
        startSeconds: safeStart > 0 ? safeStart : null,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: false,
          mute: false,
          loop: false,
          enableCaption: true,
          strictRelatedVideos: true,
        ),
      );
      _playerSub = _player!.listen(_onPlayerValue);
      _videoStateSub = _player!.videoStateStream.listen(_onVideoState);
      _initialLoadStarted = true;
      _lastKnownPosition = safeStart;
      _armAutoplayWatchdog();
      notifyListeners();
      return;
    }

    if (isInitial && _initialLoadStarted) {
      return;
    }

    await _loadCurrent(autoPlay: autoPlay, startSeconds: safeStart);
  }

  void _onVideoState(YoutubeVideoState state) {
    final position = state.position.inMilliseconds / 1000.0;
    if (position.isFinite && position >= 0) {
      _lastKnownPosition = position;
    }
  }

  void _onPlayerValue(YoutubePlayerValue value) {
    if (_player == null || _disposed) return;

    if (value.hasError) {
      _autoplayWatchdog?.cancel();
      final unavailable =
          value.error == YoutubeError.notEmbeddable ||
          value.error == YoutubeError.sameAsNotEmbeddable ||
          value.error == YoutubeError.sameAsNotEmbeddable2 ||
          value.error == YoutubeError.cannotFindVideo ||
          value.error == YoutubeError.videoNotFound ||
          value.error == YoutubeError.invalidParam;
      final failedId = session.currentVideo?.youtubeVideoId;
      if (failedId != null) {
        _failedVideoIds.add(failedId);
      }
      session.markError(value.error.toString(), unavailable: unavailable);
      notifyListeners();
      if (unavailable) {
        _scheduleAutoSkipUnplayable();
      }
      return;
    }

    switch (value.playerState) {
      case PlayerState.playing:
        _autoplayWatchdog?.cancel();
        _autoplayIntent = false;
        _autoplayKickAttempted = false;
        _needsUserPlay = false;
        session.markPlaying();
        notifyListeners();
      case PlayerState.paused:
        _autoplayWatchdog?.cancel();
        session.markPaused();
        unawaited(persistProgress(force: true));
        notifyListeners();
      case PlayerState.buffering:
        session.markLoading();
        notifyListeners();
      case PlayerState.ended:
        _autoplayWatchdog?.cancel();
        _handleEnded();
      case PlayerState.cued:
      case PlayerState.unStarted:
        // Ready/cued with autoplay intent: kick play once (not a timed retry loop).
        if (_autoplayIntent && !_autoplayKickAttempted && _initialLoadStarted) {
          _autoplayKickAttempted = true;
          unawaited(_kickAutoplayOnce());
        }
      case PlayerState.unknown:
        break;
    }
  }

  void _armAutoplayWatchdog() {
    _autoplayWatchdog?.cancel();
    _autoplayWatchdog = Timer(const Duration(seconds: 8), () {
      if (_disposed) return;
      if (session.phase == PlaybackPhase.loading ||
          session.phase == PlaybackPhase.initializing) {
        _needsUserPlay = true;
        session.markPaused();
        session.overlayVisible = true;
        notifyListeners();
      }
    });
  }

  void _handleEnded() {
    unawaited(persistProgress(force: true, positionOverride: 0));
    final advanced = session.onVideoEnded();
    notifyListeners();
    if (advanced) {
      final nextId = session.currentVideo?.youtubeVideoId;
      if (nextId != null && _failedVideoIds.contains(nextId)) {
        _scheduleAutoSkipUnplayable();
        return;
      }
      final token = ++_loadToken;
      scheduleMicrotask(() async {
        if (_disposed || token != _loadToken) return;
        await _loadCurrent(autoPlay: true, startSeconds: 0);
        _scheduleOverlayHide();
        unawaited(persistProgress(force: true, positionOverride: 0));
      });
    } else {
      _overlayTimer?.cancel();
      unawaited(persistProgress(force: true, positionOverride: 0));
    }
  }

  /// Skips unplayable videos without retrying the same id forever.
  void _scheduleAutoSkipUnplayable() {
    if (_disposed || _autoSkipInFlight) return;
    _autoSkipInFlight = true;
    final token = ++_loadToken;
    scheduleMicrotask(() async {
      try {
        if (_disposed || token != _loadToken) return;
        final next = session.nextPlayableIndex(
          fromIndex: session.currentIndex,
          failedIds: _failedVideoIds,
        );
        if (next >= 0) {
          await playAt(next);
          return;
        }
        // No later playable item — if every queue entry failed, stop clearly.
        final allFailed = session.queue.every(
          (v) => _failedVideoIds.contains(v.youtubeVideoId),
        );
        if (allFailed) {
          session.markAllUnavailable();
        } else {
          session.setPhase(PlaybackPhase.queueComplete);
          session.overlayVisible = true;
        }
        notifyListeners();
      } finally {
        _autoSkipInFlight = false;
      }
    });
  }

  Future<void> _loadCurrent({
    required bool autoPlay,
    double startSeconds = 0,
  }) async {
    final video = session.currentVideo;
    if (video == null || _player == null) {
      session.setPhase(PlaybackPhase.empty);
      notifyListeners();
      return;
    }
    if (_loadInFlight) return;
    _loadInFlight = true;
    final token = ++_loadToken;
    session.markLoading();
    session.errorMessage = null;
    if (autoPlay) {
      _beginAutoplayIntent();
    } else {
      _autoplayIntent = false;
      _autoplayKickAttempted = false;
      _needsUserPlay = false;
    }
    notifyListeners();
    try {
      final safeStart = startSeconds.isFinite && startSeconds > 0
          ? startSeconds
          : null;
      if (autoPlay) {
        await _player!.loadVideoById(
          videoId: video.youtubeVideoId,
          startSeconds: safeStart,
        );
      } else {
        await _player!.cueVideoById(
          videoId: video.youtubeVideoId,
          startSeconds: safeStart,
        );
      }
      if (_disposed || token != _loadToken) return;
      _lastKnownPosition = safeStart ?? 0;
      _armAutoplayWatchdog();
    } catch (error) {
      if (_disposed || token != _loadToken) return;
      session.markError(error.toString());
      notifyListeners();
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> playAt(
    int index, {
    bool autoPlay = true,
    double startSeconds = 0,
  }) async {
    if (!session.selectIndex(index)) return;
    notifyListeners();
    unawaited(persistProgress(force: true));
    if (_player == null) {
      await _ensurePlayerForCurrent(
        autoPlay: autoPlay,
        startSeconds: startSeconds,
      );
    } else {
      await _loadCurrent(autoPlay: autoPlay, startSeconds: startSeconds);
    }
    _scheduleOverlayHide();
    unawaited(persistProgress(force: true, positionOverride: startSeconds));
  }

  Future<void> playNext() async {
    final next = session.nextPlayableIndex(
      fromIndex: session.currentIndex,
      failedIds: _failedVideoIds,
    );
    if (next < 0) {
      final allFailed = session.queue.every(
        (v) => _failedVideoIds.contains(v.youtubeVideoId),
      );
      if (allFailed) {
        session.markAllUnavailable();
      } else {
        session.setPhase(PlaybackPhase.queueComplete);
        session.overlayVisible = true;
      }
      notifyListeners();
      return;
    }
    await playAt(next);
  }

  Future<void> playPrevious() async {
    if (!session.hasPrevious) return;
    await playAt(session.currentIndex - 1);
  }

  Future<void> retry() async {
    final id = session.currentVideo?.youtubeVideoId;
    if (id != null) {
      _failedVideoIds.remove(id);
    }
    await _loadCurrent(autoPlay: true, startSeconds: _lastKnownPosition);
  }

  Future<void> replayQueue() async {
    if (session.isEmpty) return;
    _failedVideoIds.clear();
    await playAt(0);
  }

  Future<void> requestUserPlay() async {
    _beginAutoplayIntent();
    _autoplayKickAttempted = true;
    try {
      await _player?.playVideo();
    } catch (_) {
      await _loadCurrent(autoPlay: true, startSeconds: _lastKnownPosition);
    }
    notifyListeners();
  }

  void setLocked(bool value) {
    session.setLocked(value);
    if (!value) {
      _scheduleOverlayHide();
    } else {
      _overlayTimer?.cancel();
      // Closing the queue on lock keeps the video stage geometry stable.
      session.setQueuePanelOpen(false);
    }
    notifyListeners();
  }

  void toggleQueuePanel() {
    if (session.locked) return;
    session.toggleQueuePanel();
    _scheduleOverlayHide();
    notifyListeners();
  }

  void setQueuePanelOpen(bool open) {
    if (session.locked && open) return;
    session.setQueuePanelOpen(open);
    notifyListeners();
  }

  /// Closes the queue from an outside (letterbox) tap without covering the IFrame.
  void closeQueueFromOutsideTap() {
    if (!session.queuePanelOpen) return;
    session.setQueuePanelOpen(false);
    notifyListeners();
    _scheduleOverlayHide();
  }

  void setUseSeparateQueueScreen(bool value) {
    session.setUseSeparateQueueScreen(value);
    notifyListeners();
  }

  void showOverlay() {
    session.showOverlay();
    notifyListeners();
    if (!session.locked) {
      _scheduleOverlayHide();
    }
  }

  void _scheduleOverlayHide() {
    _overlayTimer?.cancel();
    if (session.locked ||
        session.queuePanelOpen ||
        session.useSeparateQueueScreen ||
        _needsUserPlay) {
      return;
    }
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      session.hideOverlay();
      notifyListeners();
    });
  }

  void _startProgressTicker() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(persistProgress());
    });
  }

  Future<void> persistProgress({
    bool force = false,
    double? positionOverride,
  }) async {
    final repo = _progressRepository;
    final video = session.currentVideo;
    if (repo == null || video == null) return;

    var position = positionOverride ?? _lastKnownPosition;
    if (!force) {
      try {
        final live = await _player?.currentTime;
        if (live != null && live.isFinite && live >= 0) {
          position = live;
          _lastKnownPosition = live;
        }
      } catch (_) {}
    } else if (positionOverride == null) {
      try {
        final live = await _player?.currentTime;
        if (live != null && live.isFinite && live >= 0) {
          position = live;
          _lastKnownPosition = live;
        }
      } catch (_) {}
    }

    if (!position.isFinite || position < 0) position = 0;

    final progress = ChannelPlaybackProgress(
      tupicChannelId: tupicChannelId,
      youtubeVideoId: video.youtubeVideoId,
      positionSeconds: position,
      updatedAt: DateTime.now(),
      sessionQueueIds: session.queue.map((v) => v.youtubeVideoId).toList(),
      sessionPlayOrder: playOrder,
    );

    _persistChain = _persistChain.then((_) => repo.saveProgress(progress));
    await _persistChain;
  }

  Future<void> pauseForAppBackground() async {
    await persistProgress(force: true);
    try {
      await _player?.pauseVideo();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _overlayTimer?.cancel();
    _progressTimer?.cancel();
    _autoplayWatchdog?.cancel();
    _playerSub?.cancel();
    _videoStateSub?.cancel();
    final player = _player;
    _player = null;
    unawaited(player?.close());
    super.dispose();
  }
}
