import 'package:flutter/material.dart';

import '../../../../app/theme/tupic_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/shared_channel_category.dart';
import '../../../../shared/models/shared_channel_listing.dart';
import '../../../explore/presentation/shared_catalog_scope.dart';
import '../../../explore/presentation/shared_channel_preview_page.dart';

/// Home "채널 탐색" strip — loads a small latest page from the catalog.
class HomeExploreSection extends StatefulWidget {
  const HomeExploreSection({
    super.key,
    required this.onOpenExplore,
    required this.onOpenSearch,
  });

  final VoidCallback onOpenExplore;
  final VoidCallback onOpenSearch;

  @override
  State<HomeExploreSection> createState() => _HomeExploreSectionState();
}

class _HomeExploreSectionState extends State<HomeExploreSection> {
  List<SharedChannelListing> _listings = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final catalog = SharedCatalogScope.maybeOf(context);
    if (catalog == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = false;
        _listings = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await catalog.listLatest(limit: 6);
      if (!mounted) return;
      setState(() {
        _listings = page.items;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _listings = const [];
      });
    }
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

  String _categoryLabel(AppLocalizations l10n, SharedChannelCategory category) {
    return switch (category) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.exploreChannelsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: TupicColors.primaryText,
                  ),
                ),
              ),
              TextButton(
                key: const Key('home_explore_view_all'),
                onPressed: widget.onOpenExplore,
                child: Text(l10n.homeExploreViewAll),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('home_explore_search_entry'),
              onTap: widget.onOpenSearch,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  color: TupicColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TupicColors.borderSubtle),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: TupicColors.accentViolet,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.homeExploreSearchEntry,
                          style: const TextStyle(
                            color: TupicColors.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: SharedChannelCategory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = SharedChannelCategory.values[index];
              final selected = category == SharedChannelCategory.all;
              return ChoiceChip(
                label: Text(_categoryLabel(l10n, category)),
                selected: selected,
                onSelected: null,
                showCheckmark: false,
                selectedColor: TupicColors.selected,
                backgroundColor: TupicColors.card,
                labelStyle: TextStyle(
                  color: selected
                      ? TupicColors.primaryText
                      : TupicColors.mutedText,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected
                      ? TupicColors.accentViolet.withValues(alpha: 0.55)
                      : TupicColors.borderSubtle,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_failed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: _HomeExploreBanner(
              keyName: 'home_explore_error',
              text: l10n.exploreLoadFailedTitle,
              actionLabel: l10n.retry,
              onAction: _load,
            ),
          )
        else if (_listings.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: _HomeExploreBanner(
              keyName: 'home_explore_empty',
              text: l10n.exploreEmptyTitle,
            ),
          )
        else
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _listings.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = _listings[index];
                return _SharedListingCard(
                  listing: item,
                  categoryLabel: _categoryLabel(l10n, item.category),
                  onTap: () => _openPreview(item),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HomeExploreBanner extends StatelessWidget {
  const _HomeExploreBanner({
    required this.keyName,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String keyName;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key(keyName),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TupicColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.explore_outlined,
            size: 20,
            color: TupicColors.accentViolet,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: TupicColors.mutedText,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _SharedListingCard extends StatelessWidget {
  const _SharedListingCard({
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
    return SizedBox(
      width: 176,
      child: Material(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TupicColors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: TupicColors.selected,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.live_tv_outlined,
                        color: TupicColors.accentViolet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.displayAuthor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TupicColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$categoryLabel · ${l10n.videoCount(listing.videoCount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TupicColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
