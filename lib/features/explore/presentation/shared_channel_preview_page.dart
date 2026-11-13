import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/widgets/coming_soon_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/share_models.dart';
import '../../../shared/models/shared_channel_category.dart';
import '../domain/shared_playback_queue.dart';
import 'shared_catalog_scope.dart';
import 'shared_playback_launcher.dart';

class SharedChannelPreviewPage extends StatefulWidget {
  const SharedChannelPreviewPage({
    super.key,
    required this.postId,
    this.initialNickname,
  });

  final String postId;
  final String? initialNickname;

  @override
  State<SharedChannelPreviewPage> createState() =>
      _SharedChannelPreviewPageState();
}

class _SharedChannelPreviewPageState extends State<SharedChannelPreviewPage> {
  SharePost? _post;
  String? _nickname;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nickname = widget.initialNickname;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final catalog = SharedCatalogScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await catalog.getPublishedPost(widget.postId);
      if (!mounted) return;
      if (post == null) {
        setState(() {
          _post = null;
          _loading = false;
          _error = 'missing';
        });
        return;
      }
      var nick = _nickname;
      if (nick == null || nick.isEmpty) {
        final map = await catalog.nicknamesFor([post.ownerUid]);
        nick = map[post.ownerUid];
      }
      if (!mounted) return;
      setState(() {
        _post = post;
        _nickname = nick;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load_failed';
      });
    }
  }

  String _categoryLabel(AppLocalizations l10n, SharedChannelCategory c) {
    return switch (c) {
      SharedChannelCategory.all => l10n.exploreCategoryAll,
      SharedChannelCategory.kids => l10n.exploreCategoryKids,
      SharedChannelCategory.education => l10n.exploreCategoryEducation,
      SharedChannelCategory.music => l10n.exploreCategoryMusic,
      SharedChannelCategory.entertainment => l10n.exploreCategoryEntertainment,
      SharedChannelCategory.games => l10n.exploreCategoryGames,
      SharedChannelCategory.sports => l10n.exploreCategorySports,
      SharedChannelCategory.lifestyle => l10n.exploreCategoryLifestyle,
      SharedChannelCategory.other => l10n.exploreCategoryOther,
    };
  }

  bool get _canPlay {
    final post = _post;
    if (post == null || !post.isPublished) return false;
    return SharedPlaybackQueue.build(post) != null;
  }

  Future<void> _playAll() async {
    final post = _post;
    if (post == null) return;
    await startSharedChannelPlayback(context, post: post);
  }

  Future<void> _playFrom(ShareSnapshotVideo video) async {
    final post = _post;
    if (post == null) return;
    await startSharedChannelPlayback(
      context,
      post: post,
      startYoutubeVideoId: video.youtubeVideoId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final post = _post;
    final canPlay = _canPlay;

    return Scaffold(
      backgroundColor: TupicColors.mainBackground,
      appBar: AppBar(
        title: Text(l10n.sharePreviewTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || post == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.sharePreviewUnavailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: TupicColors.mutedText),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        children: [
                          Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.sharePublicNicknameLabel(
                              (_nickname != null && _nickname!.isNotEmpty)
                                  ? _nickname!
                                  : '—',
                            ),
                            style: const TextStyle(color: TupicColors.mutedText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${post.isKids ? l10n.kidsBadge : l10n.generalBadge}'
                            ' · ${_categoryLabel(l10n, post.category)}'
                            ' · ${l10n.videoCount(post.videoCount)}'
                            ' · ${l10n.shareVersionLabel(post.version)}',
                            style: const TextStyle(
                              color: TupicColors.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          if (post.description != null &&
                              post.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              post.description!,
                              style: const TextStyle(height: 1.4),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            key: const Key('share_preview_play_all'),
                            onPressed: canPlay ? _playAll : null,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.sharePreviewPlayAll),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.sharePreviewVideosSection,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (post.snapshot.videos.isEmpty)
                            Text(
                              l10n.playerEmptyQueue,
                              style: const TextStyle(
                                color: TupicColors.mutedText,
                              ),
                            )
                          else
                            ...post.snapshot.videos.map(
                              (v) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: TupicColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    key: Key(
                                      'share_preview_video_${v.youtubeVideoId}',
                                    ),
                                    onTap: canPlay ? () => _playFrom(v) : null,
                                    leading: const Icon(
                                      Icons.play_circle_outline,
                                      color: TupicColors.accentViolet,
                                    ),
                                    title: Text(
                                      v.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: v.durationSeconds != null
                                        ? Text('${v.durationSeconds}s')
                                        : null,
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              key: const Key('share_preview_add_channel'),
                              onPressed: () => showComingSoonDialog(context),
                              child: Text(l10n.sharePreviewAddChannel),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              key: const Key('share_preview_add_videos'),
                              onPressed: () => showComingSoonDialog(context),
                              child: Text(l10n.sharePreviewAddVideos),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
