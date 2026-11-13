import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/coming_soon_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/home_feed.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/models/video_item.dart';
import '../../account/presentation/account_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../channels/presentation/channel_detail_page.dart';
import '../../channels/presentation/channels_controller.dart';
import '../../channels/presentation/create_channel_dialog.dart';
import '../../explore/presentation/channel_explore_page.dart';
import '../../player/presentation/player_launcher.dart';
import '../../settings/presentation/settings_page.dart';
import 'home_controller.dart';
import 'widgets/app_end_drawer.dart';
import 'widgets/channel_card.dart';
import 'widgets/home_explore_section.dart';
import 'widgets/horizontal_rail.dart';
import 'widgets/space_hero_illustration.dart';
import 'widgets/video_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final HomeController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  HomeController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    controller.load();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  List<TupicChannel> get _channels => controller.userChannels;

  Future<void> _openChannel(TupicChannel channel) async {
    await ChannelsScope.of(context).selectChannel(channel.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChannelDetailPage(channelId: channel.id),
      ),
    );
  }

  Future<void> _playChannel(TupicChannel channel) async {
    await ChannelsScope.of(context).selectChannel(channel.id);
    if (!mounted) return;
    await startChannelPlayback(context, channel: channel);
  }

  void _openChannelExplore() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChannelExplorePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: AppEndDrawer(
        channels: _channels,
        onOpenChannel: _openChannel,
        onPlayChannel: _playChannel,
        onCreateChannel: () => showCreateChannelDialog(context),
        onExploreChannels: _openChannelExplore,
        onOpenSettings: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SettingsPage(),
            ),
          );
        },
        onOpenAccount: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AccountPage(),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: SpacePatternBackdrop(intensity: 0.34, seed: 42),
          ),
          Positioned.fill(
            child: switch (controller.state) {
              HomeFeedLoading() => const LoadingView(),
              HomeFeedError() => ErrorView(onRetry: controller.load),
              HomeFeedEmpty(:final userDisplayName, :final isMock) =>
                _HomeScrollBody(
                  userDisplayName: userDisplayName,
                  isMock: isMock,
                  channels: _channels,
                  recommended: const [],
                  showAudiencePicker: true,
                  onAudienceSelected: controller.setAudience,
                  onOpenChannel: _openChannel,
                  onPlayChannel: _playChannel,
                  onExploreChannels: _openChannelExplore,
                ),
              HomeFeedReady(:final feed) => _HomeScrollBody(
                userDisplayName: feed.userDisplayName,
                isMock: feed.isMock,
                channels: feed.channels,
                recommended: feed.recommended,
                showAudiencePicker: feed.lastAudience == null,
                onAudienceSelected: controller.setAudience,
                onOpenChannel: _openChannel,
                onPlayChannel: _playChannel,
                onExploreChannels: _openChannelExplore,
              ),
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            right: 8,
            child: IconButton(
              key: const Key('home_menu_button'),
              tooltip: l10n.menuOpen,
              style: IconButton.styleFrom(
                backgroundColor: TupicColors.secondary.withValues(alpha: 0.72),
                foregroundColor: TupicColors.primaryText,
              ),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeScrollBody extends StatelessWidget {
  const _HomeScrollBody({
    required this.userDisplayName,
    required this.isMock,
    required this.channels,
    required this.recommended,
    required this.showAudiencePicker,
    required this.onAudienceSelected,
    required this.onOpenChannel,
    required this.onPlayChannel,
    required this.onExploreChannels,
  });

  final String userDisplayName;
  final bool isMock;
  final List<TupicChannel> channels;
  final List<VideoItem> recommended;
  final bool showAudiencePicker;
  final ValueChanged<AudiencePreference> onAudienceSelected;
  final ValueChanged<TupicChannel> onOpenChannel;
  final ValueChanged<TupicChannel> onPlayChannel;
  final VoidCallback onExploreChannels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    // Header is pattern+text, not a 3D art banner — keep compact.
    final heroHeight = width < 480
        ? 132.0
        : width < 900
        ? 148.0
        : 160.0;
    final channelCardWidth = width < 480 ? 168.0 : 196.0;
    // ~22% shorter than prior 248/268 while keeping play tap target ≥40.
    final channelRailHeight = width < 480 ? 192.0 : 208.0;
    final videoCardWidth = width < 480 ? 150.0 : 176.0;
    final videoRailHeight = width < 480 ? 176.0 : 196.0;
    final contentMaxWidth = width >= 1100 ? 1080.0 : double.infinity;

    Widget feed(Widget child) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: child,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ListenableBuilder(
            listenable: AuthScope.of(context),
            builder: (context, _) {
              final auth = AuthScope.of(context);
              final name = auth.displayName;
              final subtitle = (name != null && name.isNotEmpty)
                  ? l10n.helloUser(name)
                  : l10n.helloGuest;
              return SpaceHeroIllustration(
                height: heroHeight,
                title: 'TUPICK',
                subtitle: subtitle,
              );
            },
          ),
        ),
        if (isMock)
          SliverToBoxAdapter(
            child: feed(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: TupicColors.selected.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TupicColors.borderSubtle),
                  ),
                  child: Text(
                    l10n.demoContentBanner,
                    style: const TextStyle(
                      color: TupicColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (showAudiencePicker)
          SliverToBoxAdapter(
            child: feed(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _AudiencePicker(onSelected: onAudienceSelected),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: feed(SectionHeader(title: l10n.myChannels)),
        ),
        SliverToBoxAdapter(
          child: feed(
            channels.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmptySection(
                          title: l10n.emptyChannelsTitle,
                          body: l10n.emptyChannelsBody,
                          icon: Icons.live_tv_outlined,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: channelRailHeight * 0.85,
                          child: CreateChannelCard(
                            width: channelCardWidth,
                            onTap: () => showCreateChannelDialog(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : HorizontalRail(
                    height: channelRailHeight,
                    itemCount: channels.length + 1,
                    itemBuilder: (context, index) {
                      if (index == channels.length) {
                        return CreateChannelCard(
                          width: channelCardWidth,
                          onTap: () => showCreateChannelDialog(context),
                        );
                      }
                      final channel = channels[index];
                      return ChannelCard(
                        channel: channel,
                        width: channelCardWidth,
                        onOpen: () => onOpenChannel(channel),
                        onPlay: () => onPlayChannel(channel),
                      );
                    },
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: feed(SectionHeader(title: l10n.recommended)),
        ),
        SliverToBoxAdapter(
          child: feed(
            recommended.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: EmptySection(
                      title: l10n.emptyRecommendedTitle,
                      body: l10n.emptyRecommendedBody,
                      icon: Icons.recommend_outlined,
                    ),
                  )
                : HorizontalRail(
                    height: videoRailHeight,
                    itemCount: recommended.length,
                    itemBuilder: (context, index) {
                      return VideoCard(
                        video: recommended[index],
                        width: videoCardWidth,
                        onTap: () => showComingSoonDialog(context),
                      );
                    },
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: feed(
            HomeExploreSection(
              onOpenExplore: onExploreChannels,
              onOpenSearch: onExploreChannels,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _AudiencePicker extends StatelessWidget {
  const _AudiencePicker({required this.onSelected});

  final ValueChanged<AudiencePreference> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.selectAudienceTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: TupicColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => onSelected(AudiencePreference.kids),
                child: Text(l10n.selectAudienceKids),
              ),
              OutlinedButton(
                onPressed: () => onSelected(AudiencePreference.general),
                child: Text(l10n.selectAudienceGeneral),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
