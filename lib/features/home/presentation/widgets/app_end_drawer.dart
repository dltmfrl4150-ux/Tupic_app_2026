import 'package:flutter/material.dart';

import '../../../../app/theme/tupic_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/tupic_channel.dart';

class AppEndDrawer extends StatefulWidget {
  const AppEndDrawer({
    super.key,
    required this.channels,
    required this.onOpenChannel,
    required this.onPlayChannel,
    required this.onCreateChannel,
    required this.onExploreChannels,
    required this.onOpenSettings,
    required this.onOpenAccount,
  });

  final List<TupicChannel> channels;
  final ValueChanged<TupicChannel> onOpenChannel;
  final ValueChanged<TupicChannel> onPlayChannel;
  final VoidCallback onCreateChannel;
  final VoidCallback onExploreChannels;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAccount;

  @override
  State<AppEndDrawer> createState() => _AppEndDrawerState();
}

class _AppEndDrawerState extends State<AppEndDrawer> {
  bool _channelsExpanded = true;

  void _closeAnd(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = width < 420 ? width * 0.86 : 320.0;

    return Drawer(
      width: drawerWidth,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Text(
                    'TUPIC',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: TupicColors.primaryText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.menuClose,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _ExpandableHeader(
                    title: l10n.menuChannels,
                    expanded: _channelsExpanded,
                    onTap: () {
                      setState(() => _channelsExpanded = !_channelsExpanded);
                    },
                  ),
                  if (_channelsExpanded) ...[
                    if (widget.channels.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 4, 20, 8),
                        child: Text(
                          l10n.emptyChannelsTitle,
                          style: const TextStyle(color: TupicColors.mutedText),
                        ),
                      )
                    else
                      ...widget.channels.map(
                        (channel) => ListTile(
                          key: Key('drawer_channel_${channel.id}'),
                          contentPadding: const EdgeInsets.only(
                            left: 28,
                            right: 8,
                          ),
                          leading: Icon(
                            channel.isKidsChannel
                                ? Icons.child_care_rounded
                                : Icons.person_outline_rounded,
                            color: TupicColors.accentViolet,
                          ),
                          title: Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            key: Key('drawer_play_${channel.id}'),
                            tooltip: l10n.playNow,
                            icon: const Icon(Icons.play_circle_fill_rounded),
                            color: TupicColors.accentViolet,
                            onPressed: () => _closeAnd(
                              () => widget.onPlayChannel(channel),
                            ),
                          ),
                          onTap: () => _closeAnd(
                            () => widget.onOpenChannel(channel),
                          ),
                        ),
                      ),
                  ],
                  const Divider(height: 24),
                  _DrawerTile(
                    icon: Icons.add_circle_outline,
                    label: l10n.menuCreateChannel,
                    onTap: () => _closeAnd(widget.onCreateChannel),
                  ),
                  _DrawerTile(
                    icon: Icons.explore_outlined,
                    label: l10n.menuImportSharedChannel,
                    onTap: () => _closeAnd(widget.onExploreChannels),
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: l10n.menuSettings,
                    onTap: () => _closeAnd(widget.onOpenSettings),
                  ),
                  _DrawerTile(
                    icon: Icons.account_circle_outlined,
                    label: l10n.menuMyAccount,
                    onTap: () => _closeAnd(widget.onOpenAccount),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Text(
                l10n.menuPremiumHint,
                style: const TextStyle(
                  color: TupicColors.mutedText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableHeader extends StatelessWidget {
  const _ExpandableHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TupicColors.primaryText,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: TupicColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: TupicColors.accentViolet),
      title: Text(label),
      onTap: onTap,
    );
  }
}
