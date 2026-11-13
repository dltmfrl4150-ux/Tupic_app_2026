import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/shared_channel_category.dart';
import '../../../shared/models/shared_channel_listing.dart';
import '../../../shared/repositories/shared_channel_catalog_repository.dart';
import '../../share/presentation/my_shared_channels_page.dart';
import 'select_channel_to_share_page.dart';
import 'shared_catalog_scope.dart';
import 'shared_channel_preview_page.dart';

class ChannelExplorePage extends StatefulWidget {
  const ChannelExplorePage({
    super.key,
    SharedChannelCatalogRepository? catalog,
  }) : catalogOverride = catalog;

  /// Optional override for tests; otherwise [SharedCatalogScope] is used.
  final SharedChannelCatalogRepository? catalogOverride;

  @override
  State<ChannelExplorePage> createState() => _ChannelExplorePageState();
}

class _ChannelExplorePageState extends State<ChannelExplorePage> {
  final _searchController = TextEditingController();
  SharedChannelCategory _category = SharedChannelCategory.all;
  List<SharedChannelListing> _items = const [];
  SharedCatalogCursor? _cursor;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  Timer? _debounce;

  SharedChannelCatalogRepository _catalog(BuildContext context) =>
      widget.catalogOverride ?? SharedCatalogScope.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _failed = false;
      _items = const [];
      _cursor = null;
      _hasMore = false;
    });
    await _fetch(reset: true);
  }

  Future<void> _fetch({required bool reset}) async {
    final catalog = _catalog(context);
    final query = _searchController.text.trim();
    try {
      if (!reset) {
        setState(() => _loadingMore = true);
      }
      final page = query.isEmpty
          ? await catalog.listLatest(
              category: _category,
              limit: 20,
              startAfter: reset ? null : _cursor,
            )
          : await catalog.searchPrefix(
              query: query,
              category: _category,
              limit: 20,
              startAfter: reset ? null : _cursor,
            );
      if (!mounted) return;
      setState(() {
        _items = reset ? page.items : [..._items, ...page.items];
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _failed = true;
        if (reset) _items = const [];
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
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

  void _openPreview(SharedChannelListing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedChannelPreviewPage(
          postId: listing.id,
          initialNickname: listing.ownerNickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = !_loading && !_failed && _items.isEmpty;

    return Scaffold(
      backgroundColor: TupicColors.mainBackground,
      appBar: AppBar(
        title: Text(l10n.exploreChannelsTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            TextField(
              key: const Key('explore_search_field'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                hintText: l10n.exploreSearchHint,
                helperText: l10n.exploreSearchPrefixHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: TupicColors.card,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: SharedChannelCategory.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = SharedChannelCategory.values[index];
                  final selected = _category == category;
                  return ChoiceChip(
                    label: Text(_categoryLabel(l10n, category)),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      if (_category == category) return;
                      setState(() => _category = category);
                      _reload();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.exploreLatestSection,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_failed)
              _ExploreMessage(
                title: l10n.exploreLoadFailedTitle,
                body: l10n.exploreLoadFailedBody,
                actionLabel: l10n.retry,
                onAction: _reload,
              )
            else if (empty)
              _ExploreMessage(
                title: l10n.exploreEmptyTitle,
                body: l10n.exploreEmptyBody,
              )
            else ...[
              for (final item in _items)
                _ListingTile(
                  listing: item,
                  categoryLabel: _categoryLabel(l10n, item.category),
                  onTap: () => _openPreview(item),
                ),
              if (_hasMore) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    key: const Key('explore_load_more'),
                    onPressed: _loadingMore
                        ? null
                        : () => _fetch(reset: false),
                    child: _loadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.exploreLoadMore),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            _ActionTile(
              keyName: 'explore_share_my_channel',
              icon: Icons.ios_share_rounded,
              label: l10n.exploreShareMyChannel,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SelectChannelToSharePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              keyName: 'explore_my_shared_channels',
              icon: Icons.folder_shared_outlined,
              label: l10n.mySharedChannelsTitle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MySharedChannelsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TupicColors.selected,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key(keyName),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Icon(icon, color: TupicColors.accentViolet),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TupicColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreMessage extends StatelessWidget {
  const _ExploreMessage({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.explore_outlined,
            size: 36,
            color: TupicColors.accentViolet,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TupicColors.mutedText,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({
    required this.listing,
    required this.categoryLabel,
    required this.onTap,
  });

  final SharedChannelListing listing;
  final String categoryLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          title: Text(listing.title),
          subtitle: Text(
            '${listing.displayAuthor} · $categoryLabel · '
            '${l10n.videoCount(listing.videoCount)} · '
            '${l10n.shareVersionLabel(listing.version)}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
