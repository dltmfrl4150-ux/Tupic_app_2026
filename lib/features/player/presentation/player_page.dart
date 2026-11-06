import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/utils/orientation_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/channel_video.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/repositories/playback_progress_repository.dart';
import '../../channels/presentation/channels_controller.dart';
import '../../content/presentation/content_controller.dart';
import '../domain/playback_phase.dart';
import '../domain/playback_resume.dart';
import 'player_session_controller.dart';
import 'widgets/player_queue_strip.dart';
import 'widgets/player_unlock_hold_button.dart';

const double _kMinPlayerSize = 200;
const double _kInlineQueueHeight = 132;
/// Flutter-only chrome width so controls never sit on the Android WebView.
const double _kChromeRailWidth = 72;

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.channel,
    required this.queue,
    this.initialIndex = 0,
    this.initialStartSeconds = 0,
    this.progressRepository,
    this.resumed = false,
  });

  final TupicChannel channel;
  final List<ChannelVideo> queue;
  final int initialIndex;
  final double initialStartSeconds;
  final PlaybackProgressRepository? progressRepository;
  final bool resumed;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final PlayerSessionController _session;
  late final AnimationController _queueAnim;
  bool _orientationReady = false;
  bool _queueAnimTargetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _queueAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _session = PlayerSessionController(
      queue: widget.queue,
      tupicChannelId: widget.channel.id,
      playOrder: widget.channel.playOrder,
      initialIndex: widget.initialIndex,
      initialStartSeconds: widget.initialStartSeconds,
      isKidsChannel: widget.channel.isKidsChannel,
      progressRepository: widget.progressRepository,
    );
    _session.addListener(_syncQueueAnimation);
    _enterPlayerChrome();
  }

  void _syncQueueAnimation() {
    final wantOpen = _session.queuePanelOpen && !_session.locked;
    if (wantOpen == _queueAnimTargetOpen) return;
    _queueAnimTargetOpen = wantOpen;
    if (wantOpen) {
      _queueAnim.forward();
    } else {
      _queueAnim.reverse();
    }
  }

  Future<void> _enterPlayerChrome() async {
    if (OrientationHelper.supportsForcedOrientation) {
      await OrientationHelper.lockLandscape();
    }
    if (!mounted) return;
    // Create the controller first so the initial YoutubePlayer mount has a
    // live controller; fromVideoId queues until WebView Ready.
    await _session.initialize();
    if (!mounted) return;
    setState(() => _orientationReady = true);
  }

  Future<void> _exitPlayer() async {
    await _session.persistProgress(force: true);
    await OrientationHelper.lockPortrait();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _session.pauseForAppBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_syncQueueAnimation);
    _queueAnim.dispose();
    // Progress is flushed on exit/back; dispose closes the IFrame.
    // Do not restore portrait here — channel switch uses pushReplacement and
    // would briefly flip orientation. Exit paths restore portrait explicitly.
    _session.dispose();
    super.dispose();
  }

  Future<void> _onUnlockRequest() async {
    if (!_session.locked) return;
    // Screen lock is a player chrome guard only — never parental gate.
    _session.setLocked(false);
  }

  Future<void> _openChannelSwitcher() async {
    if (_session.locked) return;
    final l10n = AppLocalizations.of(context);
    final channelsController = ChannelsScope.maybeOf(context);
    final channels = channelsController?.channels ?? const <TupicChannel>[];
    if (channels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelNotFound)),
      );
      return;
    }

    final selected = await showModalBottomSheet<TupicChannel>(
      context: context,
      backgroundColor: TupicColors.card,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(l10n.playerChannelListTitle),
                  leading: const Icon(Icons.smart_display_outlined),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      final current = channel.id == widget.channel.id;
                      return ListTile(
                        leading: Icon(
                          current
                              ? Icons.smart_display
                              : Icons.smart_display_outlined,
                          color: current ? TupicColors.accentViolet : null,
                        ),
                        title: Text(channel.name),
                        subtitle: channel.isKidsChannel
                            ? Text(l10n.kidsBadge)
                            : null,
                        selected: current,
                        trailing: current
                            ? const Icon(Icons.check, color: TupicColors.accentViolet)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, channel),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    if (selected.id == widget.channel.id) return;
    await _switchToChannel(selected);
  }

  Future<void> _switchToChannel(TupicChannel channel) async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);

    await _session.persistProgress(force: true);
    await content.loadChannel(channel.id);
    if (!mounted) return;

    final builtQueue = content.buildQueue(
      channelId: channel.id,
      playOrder: channel.playOrder,
    );
    if (builtQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.playerEmptyQueue)),
      );
      return;
    }

    final progress = widget.progressRepository == null
        ? null
        : await widget.progressRepository!.getProgress(channel.id);
    if (!mounted) return;

    final plan = PlaybackResume.resolve(
      builtQueue: builtQueue,
      playOrder: channel.playOrder,
      progress: progress,
    );
    if (plan.queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.playerEmptyQueue)),
      );
      return;
    }

    await ChannelsScope.maybeOf(context)?.selectChannel(channel.id);
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PlayerPage(
          channel: channel,
          queue: List<ChannelVideo>.from(plan.queue),
          initialIndex: plan.index,
          initialStartSeconds: plan.startSeconds,
          progressRepository: widget.progressRepository,
          resumed: plan.resumed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_session.locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.playerUnlockHint)),
          );
          return;
        }
        await _session.persistProgress(force: true);
        await OrientationHelper.lockPortrait();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: TupicColors.playerBlack,
            body: !_orientationReady
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.playerPreparing,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      _buildBody(context, l10n),
                      if (_session.phase == PlaybackPhase.loading ||
                          _session.phase == PlaybackPhase.initializing)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 72,
                          child: IgnorePointer(
                            child: Text(
                              l10n.playerPreparing,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      if (_session.needsUserPlay)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _session.requestUserPlay,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.playChannel),
                          ),
                        ),
                      if (kIsWeb)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: MediaQuery.paddingOf(context).top + 4,
                          child: IgnorePointer(
                            child: Text(
                              l10n.playerWebOrientationHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    // Cap strip height on short landscape so the IFrame stays ≥ min size.
    final availableH = MediaQuery.sizeOf(context).height;
    final stripH = availableH < _kMinPlayerSize + _kInlineQueueHeight + 24
        ? (availableH * 0.32).clamp(96.0, _kInlineQueueHeight)
        : _kInlineQueueHeight;

    return AnimatedBuilder(
      animation: _queueAnim,
      builder: (context, _) {
        return Column(
          children: [
            // Fixed side rails + centered 16:9 stage. Panel height only changes
            // the Expanded sibling — horizontal center axis stays stable.
            Expanded(child: _buildPlayerArea(l10n)),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _queueAnim.value,
                child: SizedBox(
                  height: stripH,
                  width: double.infinity,
                  child: PlayerQueueStrip(
                    videos: _session.queue,
                    currentIndex: _session.currentIndex,
                    enabled: !_session.locked,
                    onSelect: (index) => _session.playAt(index),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerArea(AppLocalizations l10n) {
    final locked = _session.locked;
    final showChrome = _session.overlayVisible && !locked;
    // Always keep identical rail widths so lock/unlock never shifts the video.
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _kChromeRailWidth,
            child: locked
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PlayerUnlockHoldButton(
                        semanticLabel: l10n.playerUnlock,
                        semanticHint: l10n.playerUnlockHint,
                        onUnlock: _onUnlockRequest,
                      ),
                    ),
                  )
                : showChrome
                ? _LeftChromeRail(
                    l10n: l10n,
                    onBack: () async {
                      await _exitPlayer();
                    },
                    onLock: () => _session.setLocked(true),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_session.queuePanelOpen) {
                        _session.closeQueueFromOutsideTap();
                      } else {
                        _session.showOverlay();
                      }
                    },
                    child: const SizedBox.expand(),
                  ),
          ),
          Expanded(child: _buildVideoStage(l10n)),
          SizedBox(
            width: _kChromeRailWidth,
            child: locked
                ? const SizedBox.expand()
                : showChrome
                ? _RightChromeRail(
                    l10n: l10n,
                    queueOpen: _session.queuePanelOpen,
                    onSwitchChannel: _openChannelSwitcher,
                    onToggleQueue: _session.toggleQueuePanel,
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_session.queuePanelOpen) {
                        _session.closeQueueFromOutsideTap();
                      } else {
                        _session.showOverlay();
                      }
                    },
                    child: const SizedBox.expand(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStage(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        // Fit 16:9 inside the stage without forcing below YouTube min size when
        // space allows — keeps the geometric center fixed as maxH animates.
        var playerW = maxW;
        var playerH = playerW * 9 / 16;
        if (playerH > maxH) {
          playerH = maxH;
          playerW = playerH * 16 / 9;
        }
        if (playerW < _kMinPlayerSize && maxW >= _kMinPlayerSize) {
          playerW = _kMinPlayerSize.clamp(0, maxW);
          playerH = playerW * 9 / 16;
          if (playerH > maxH) {
            playerH = maxH;
            playerW = playerH * 16 / 9;
          }
        }

        final w = playerW.clamp(1.0, maxW);
        final h = playerH.clamp(1.0, maxH);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Flutter-owned letterbox only — never covers the IFrame bounds.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_session.locked) return;
                  if (_session.queuePanelOpen) {
                    _session.closeQueueFromOutsideTap();
                    return;
                  }
                  if (!_session.overlayVisible) {
                    _session.showOverlay();
                  }
                },
              ),
            ),
            Center(
              child: SizedBox(
                width: w,
                height: h,
                child: _buildYoutubeOrStatus(l10n),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYoutubeOrStatus(AppLocalizations l10n) {
    final phase = _session.phase;
    final yt = _session.player;

    if (phase == PlaybackPhase.empty) {
      return _StatusPanel(
        title: l10n.playerEmptyQueue,
        actionLabel: l10n.back,
        onAction: _exitPlayer,
      );
    }

    if (phase == PlaybackPhase.queueComplete) {
      return _StatusPanel(
        title: l10n.playerLastVideo,
        actionLabel: l10n.playerReplayQueue,
        onAction: _session.replayQueue,
        secondaryLabel: l10n.back,
        onSecondary: _exitPlayer,
      );
    }

    if (phase == PlaybackPhase.allUnavailable) {
      return _StatusPanel(
        title: l10n.playerAllVideosUnavailable,
        actionLabel: l10n.playerReplayQueue,
        onAction: _session.replayQueue,
        secondaryLabel: l10n.back,
        onSecondary: _exitPlayer,
      );
    }

    if (phase == PlaybackPhase.error || phase == PlaybackPhase.unavailable) {
      return _StatusPanel(
        title: phase == PlaybackPhase.unavailable
            ? l10n.playerVideoUnavailable
            : l10n.playerPlaybackError,
        actionLabel: l10n.playerRetry,
        onAction: _session.retry,
        secondaryLabel: _session.hasNext
            ? l10n.playerNextVideo
            : l10n.back,
        onSecondary: _session.hasNext ? _session.playNext : _exitPlayer,
      );
    }

    if (yt == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: YoutubePlayer(
        controller: yt,
        aspectRatio: 16 / 9,
        backgroundColor: Colors.black,
        enableFullScreenOnVerticalDrag: false,
        autoFullScreen: false,
        gestureRecognizers: const {},
      ),
    );
  }
}

class _LeftChromeRail extends StatelessWidget {
  const _LeftChromeRail({
    required this.l10n,
    required this.onBack,
    required this.onLock,
  });

  final AppLocalizations l10n;
  final VoidCallback onBack;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _ChromeIconButton(
            tooltip: l10n.back,
            icon: Icons.arrow_back,
            enabled: true,
            onPressed: onBack,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ChromeIconButton(
            tooltip: l10n.playerLock,
            icon: Icons.lock_open_outlined,
            enabled: true,
            onPressed: onLock,
          ),
        ),
      ],
    );
  }
}

class _RightChromeRail extends StatelessWidget {
  const _RightChromeRail({
    required this.l10n,
    required this.queueOpen,
    required this.onSwitchChannel,
    required this.onToggleQueue,
  });

  final AppLocalizations l10n;
  final bool queueOpen;
  final VoidCallback onSwitchChannel;
  final VoidCallback onToggleQueue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _ChromeIconButton(
            tooltip: l10n.playerSwitchChannel,
            // monitor-play / TV-style — distinct from the video-list icon below.
            icon: Icons.smart_display_outlined,
            enabled: true,
            onPressed: onSwitchChannel,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ChromeIconButton(
            tooltip: l10n.playerVideoList,
            // list-video style — current channel thumbnails only.
            icon: queueOpen
                ? Icons.video_library
                : Icons.video_library_outlined,
            enabled: true,
            onPressed: onToggleQueue,
          ),
        ),
      ],
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.enabled,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, color: enabled ? Colors.white : Colors.white38),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String actionLabel;
  final Future<void> Function()? onAction;
  final String? secondaryLabel;
  final Future<void> Function()? onSecondary;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction == null ? null : () => onAction!(),
                child: Text(actionLabel),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => onSecondary!(),
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

