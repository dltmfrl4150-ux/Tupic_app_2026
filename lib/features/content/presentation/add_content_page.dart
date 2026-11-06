import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/constants/plan_limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/content_enums.dart';
import '../../../shared/models/youtube_url_parse_result.dart';
import '../../../shared/repositories/content_repository.dart';
import '../../channels/presentation/premium_upsell_page.dart';
import 'content_controller.dart';

class AddContentPage extends StatefulWidget {
  const AddContentPage({super.key, required this.channelId});

  final String channelId;

  @override
  State<AddContentPage> createState() => _AddContentPageState();
}

class _AddContentPageState extends State<AddContentPage> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  YoutubeUrlParseResult? _parsed;
  String? _errorText;
  bool _submitting = false;
  CreatorImportMode _importMode = CreatorImportMode.recent30;
  CreatorSortOrder _sortOrder = CreatorSortOrder.newest;
  bool _autoSync = false;
  bool _chooseVideo = true; // for ambiguous links

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _analyze() {
    final content = ContentScope.of(context);
    final l10n = AppLocalizations.of(context);
    final result = content.parseUrl(_urlController.text);
    setState(() {
      _parsed = result;
      _errorText = switch (result) {
        YoutubeUrlParseFailure(:final reason) => switch (reason) {
          YoutubeUrlParseFailureReason.empty => l10n.contentUrlEmpty,
          YoutubeUrlParseFailureReason.unsupportedHost =>
            l10n.contentUrlUnsupportedHost,
          YoutubeUrlParseFailureReason.redirectNotFollowed =>
            l10n.contentUrlRedirectBlocked,
          _ => l10n.contentUrlInvalid,
        },
        _ => null,
      };
      if (result is YoutubeParsedVideo && _nameController.text.isEmpty) {
        _nameController.text = 'YouTube video · ${result.videoId}';
      } else if (result is YoutubeParsedPlaylist &&
          _nameController.text.isEmpty) {
        _nameController.text = 'YouTube playlist · ${result.playlistId}';
      } else if (result is YoutubeParsedCreator &&
          _nameController.text.isEmpty) {
        _nameController.text = result.handle != null
            ? '@${result.handle}'
            : result.channelId ??
                  result.username ??
                  result.customName ??
                  'YouTube creator';
      } else if (result is YoutubeParsedAmbiguousWatchPlaylist) {
        _chooseVideo = true;
      }
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    setState(() => _urlController.text = text.trim());
    _analyze();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final content = ContentScope.of(context);
    var parsed = _parsed ?? content.parseUrl(_urlController.text);
    if (parsed is YoutubeUrlParseFailure) {
      setState(() {
        _parsed = parsed;
        _errorText = l10n.contentUrlInvalid;
      });
      return;
    }

    if (parsed is YoutubeParsedAmbiguousWatchPlaylist) {
      parsed = _chooseVideo
          ? YoutubeParsedVideo(
              videoId: parsed.videoId,
              originalUrl: parsed.originalUrl,
            )
          : YoutubeParsedPlaylist(
              playlistId: parsed.playlistId,
              originalUrl: parsed.originalUrl,
              videoId: parsed.videoId,
            );
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await content.addParsedContent(
        channelId: widget.channelId,
        parsed: parsed,
        displayName: _nameController.text,
        importMode: _importMode,
        sortOrder: _sortOrder,
        autoSyncEnabled: _autoSync,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DuplicateVideoException {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentDuplicateVideo);
    } on VideoLimitExceededException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = l10n.contentVideoLimit(error.maxVideos));
    } on AutoSyncNotAllowedException {
      if (!mounted) return;
      setState(() => _autoSync = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PremiumUpsellPage()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = l10n.errorTitle);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = _parsed;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addContentTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.addContentUrlHint,
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_parsed != null || _errorText != null) {
                setState(() {
                  _parsed = null;
                  _errorText = null;
                });
              }
            },
            onSubmitted: (_) => _analyze(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _submitting ? null : _paste,
                icon: const Icon(Icons.content_paste),
                label: Text(l10n.paste),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitting ? null : _analyze,
                child: Text(l10n.analyzeUrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (parsed is YoutubeParsedVideo)
            _DetectedCard(
              label: l10n.contentTypeVideo,
              detail: parsed.videoId,
            ),
          if (parsed is YoutubeParsedPlaylist)
            _DetectedCard(
              label: l10n.contentTypePlaylist,
              detail: parsed.playlistId,
              footnote: l10n.playlistPendingFetch,
            ),
          if (parsed is YoutubeParsedCreator)
            _DetectedCard(
              label: l10n.contentTypeCreator,
              detail: parsed.handle != null
                  ? '@${parsed.handle}'
                  : parsed.channelId ??
                        parsed.username ??
                        parsed.customName ??
                        '',
              footnote: l10n.creatorPendingFetch,
            ),
          if (parsed is YoutubeParsedAmbiguousWatchPlaylist) ...[
            _DetectedCard(
              label: l10n.contentAmbiguousTitle,
              detail: '${parsed.videoId} / ${parsed.playlistId}',
            ),
            RadioGroup<bool>(
              groupValue: _chooseVideo,
              onChanged: (value) {
                if (value != null) setState(() => _chooseVideo = value);
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    title: Text(l10n.contentAmbiguousVideo),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: Text(l10n.contentAmbiguousPlaylist),
                  ),
                ],
              ),
            ),
          ],
          if (parsed is YoutubeParsedCreator) ...[
            const SizedBox(height: 12),
            Text(
              l10n.creatorImportModeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.creatorImportRecent30),
                  selected: _importMode == CreatorImportMode.recent30,
                  onSelected: (_) =>
                      setState(() => _importMode = CreatorImportMode.recent30),
                ),
                ChoiceChip(
                  label: Text(l10n.creatorImportAll),
                  selected: _importMode == CreatorImportMode.all,
                  onSelected: (_) =>
                      setState(() => _importMode = CreatorImportMode.all),
                ),
                ChoiceChip(
                  label: Text(l10n.creatorImportManual),
                  selected: _importMode == CreatorImportMode.manual,
                  onSelected: (_) =>
                      setState(() => _importMode = CreatorImportMode.manual),
                ),
              ],
            ),
            if (_importMode == CreatorImportMode.manual)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.creatorManualNeedsApi,
                  style: const TextStyle(color: TupicColors.mutedText),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.creatorSortLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.creatorSortNewest),
                  selected: _sortOrder == CreatorSortOrder.newest,
                  onSelected: (_) =>
                      setState(() => _sortOrder = CreatorSortOrder.newest),
                ),
                ChoiceChip(
                  label: Text(l10n.creatorSortOldest),
                  selected: _sortOrder == CreatorSortOrder.oldest,
                  onSelected: (_) =>
                      setState(() => _sortOrder = CreatorSortOrder.oldest),
                ),
                ChoiceChip(
                  label: Text(l10n.creatorSortShuffle),
                  selected: _sortOrder == CreatorSortOrder.shuffle,
                  onSelected: (_) =>
                      setState(() => _sortOrder = CreatorSortOrder.shuffle),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.autoSyncLabel),
              subtitle: Text(
                PlanLimits.isPremium
                    ? l10n.autoSyncPremiumHint
                    : l10n.autoSyncFreeLocked,
              ),
              value: _autoSync,
              activeThumbColor: TupicColors.accentViolet,
              onChanged: PlanLimits.isPremium
                  ? (value) => setState(() => _autoSync = value)
                  : (value) async {
                      if (value) {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PremiumUpsellPage(),
                          ),
                        );
                      }
                      setState(() => _autoSync = false);
                    },
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: l10n.displayNameHint),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(l10n.registerContent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetectedCard extends StatelessWidget {
  const _DetectedCard({
    required this.label,
    required this.detail,
    this.footnote,
  });

  final String label;
  final String detail;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TupicColors.accentViolet,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: TupicColors.primaryText)),
          if (footnote != null) ...[
            const SizedBox(height: 8),
            Text(
              footnote!,
              style: const TextStyle(color: TupicColors.mutedText, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
