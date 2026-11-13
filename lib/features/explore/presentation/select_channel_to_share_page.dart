import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/account_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../channels/presentation/channels_controller.dart';
import '../../channels/presentation/create_channel_dialog.dart';
import '../../profile/presentation/public_profile_controller.dart';
import '../../share/presentation/share_channel_page.dart';

/// Pick a local channel, then open [ShareChannelPage].
class SelectChannelToSharePage extends StatelessWidget {
  const SelectChannelToSharePage({super.key});

  Future<void> _openShare(BuildContext context, String channelId) async {
    final l10n = AppLocalizations.of(context);
    final auth = AuthScope.of(context);
    final profile = PublicProfileScope.of(context);

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
      return;
    }

    final channels = ChannelsScope.of(context);
    final matches = channels.channels.where((c) => c.id == channelId);
    if (matches.isEmpty) return;
    final selected = matches.first;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShareChannelPage(channel: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channels = ChannelsScope.of(context);

    return Scaffold(
      backgroundColor: TupicColors.mainBackground,
      appBar: AppBar(
        title: Text(l10n.exploreShareMyChannel),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: channels,
        builder: (context, _) {
          final list = channels.channels;
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.exploreNoLocalChannelsToShare,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TupicColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => showCreateChannelDialog(context),
                    child: Text(l10n.createChannelCard),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final channel = list[index];
              return Material(
                color: TupicColors.card,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  key: Key('share_pick_channel_${channel.id}'),
                  title: Text(channel.name),
                  subtitle: Text(
                    '${channel.isKidsChannel ? l10n.kidsBadge : l10n.generalBadge}'
                    ' · ${l10n.videoCount(channel.videoCount)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openShare(context, channel.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
