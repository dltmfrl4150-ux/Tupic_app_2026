import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/shared_channel_category.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../account/presentation/account_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../content/presentation/content_controller.dart';
import '../../profile/presentation/public_profile_controller.dart';
import 'channel_share_controller.dart';

class ShareChannelPage extends StatefulWidget {
  const ShareChannelPage({super.key, required this.channel});

  final TupicChannel channel;

  @override
  State<ShareChannelPage> createState() => _ShareChannelPageState();
}

class _ShareChannelPageState extends State<ShareChannelPage> {
  final _descriptionController = TextEditingController();
  SharedChannelCategory _category = SharedChannelCategory.education;
  int? _existingVersion;
  bool _loadingGroup = true;
  bool _confirmedRepublish = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroup());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final share = ChannelShareScope.of(context);
    final group = await share.findGroupForChannel(widget.channel.id);
    if (!mounted) return;
    setState(() {
      _existingVersion = group?.latestVersion;
      _loadingGroup = false;
    });
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

  String _errorText(AppLocalizations l10n, String? code) {
    return switch (code) {
      'not_signed_in' => l10n.shareNeedSignIn,
      'nickname_required' => l10n.shareNeedNickname,
      'no_videos' => l10n.shareNoVideos,
      'too_many_videos' => l10n.shareTooManyVideos,
      'non_shareable_source' => l10n.shareNonShareableSource,
      'invalid_category' => l10n.shareInvalidCategory,
      'unavailable' => l10n.shareUnavailable,
      'permission_denied' => l10n.sharePermissionDenied,
      _ => l10n.sharePublishFailed,
    };
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final auth = AuthScope.of(context);
    final profile = PublicProfileScope.of(context);
    final content = ContentScope.of(context);
    final share = ChannelShareScope.of(context);

    if (!auth.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareNeedSignIn)),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AccountPage()),
      );
      return;
    }
    if (!profile.hasNickname) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareNeedNickname)),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AccountPage()),
      );
      await profile.refresh();
      return;
    }
    if (_existingVersion != null && !_confirmedRepublish) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareConfirmNewVersionRequired)),
      );
      return;
    }

    final videos = content.videosFor(widget.channel.id);
    final sources = content.sourcesFor(widget.channel.id);
    final post = await share.publish(
      channel: widget.channel,
      videos: videos,
      sources: sources,
      category: _category,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    if (post == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(l10n, share.errorCode))),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.sharePublishSuccess(post.version))),
    );
    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = AuthScope.of(context);
    final profile = PublicProfileScope.of(context);
    final content = ContentScope.of(context);
    final share = ChannelShareScope.of(context);
    final channel = widget.channel;
    final videoCount =
        content.videosFor(channel.id).where((v) => !v.isExcluded).length;
    final isRepublish = _existingVersion != null;
    final categories = SharedChannelCategory.values
        .where((c) => c != SharedChannelCategory.all)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRepublish ? l10n.shareAsNewVersionTitle : l10n.shareChannelTitle,
        ),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      // Auth / profile / share scopes are InheritedNotifier — no Listenable.merge.
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_loadingGroup)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
            ),
          _InfoCard(
            children: [
              Text(
                channel.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                '${channel.isKidsChannel ? l10n.kidsBadge : l10n.generalBadge} · ${l10n.videoCount(videoCount)}',
                style: const TextStyle(color: TupicColors.mutedText),
              ),
              const SizedBox(height: 8),
              Text(
                auth.isSignedIn
                    ? (profile.hasNickname
                        ? l10n.sharePublicNicknameLabel(profile.nickname!)
                        : l10n.shareNeedNickname)
                    : l10n.shareNeedSignIn,
                style: TextStyle(
                  color: profile.hasNickname
                      ? TupicColors.primaryText
                      : TupicColors.warning,
                ),
              ),
            ],
          ),
          if (isRepublish) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TupicColors.selected,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TupicColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shareNewVersionHint(
                      _existingVersion!,
                      _existingVersion! + 1,
                    ),
                    style: const TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _confirmedRepublish,
                    onChanged: share.publishing
                        ? null
                        : (v) => setState(
                              () => _confirmedRepublish = v == true,
                            ),
                    title: Text(l10n.shareConfirmNewVersionCheckbox),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            l10n.shareCategoryLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  label: Text(_categoryLabel(l10n, category)),
                  selected: _category == category,
                  onSelected: share.publishing
                      ? null
                      : (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _descriptionController,
            enabled: !share.publishing,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.shareDescriptionLabel,
              hintText: l10n.shareDescriptionHint,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('share_channel_submit'),
            onPressed: share.publishing ? null : _publish,
            child: share.publishing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isRepublish
                        ? l10n.shareAsNewVersionAction
                        : l10n.shareChannelAction,
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
