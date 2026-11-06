import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/tupic_channel.dart';
import 'channel_manage_page.dart';
import 'channels_controller.dart';
import 'create_channel_dialog.dart';
import 'parental_gate_dialog.dart';

class ChannelManageListPage extends StatelessWidget {
  const ChannelManageListPage({super.key});

  Future<void> _openManage(BuildContext context, TupicChannel channel) async {
    if (channel.isKidsChannel) {
      final passed = await showParentalGateDialog(context);
      if (!passed || !context.mounted) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChannelManagePage(channelId: channel.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channelsController = ChannelsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuManageChannels),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: channelsController,
        builder: (context, _) {
          final channels = channelsController.channels;
          if (channels.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.emptyChannelsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.emptyChannelsBody,
                    style: const TextStyle(color: TupicColors.mutedText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => showCreateChannelDialog(context),
                    child: Text(l10n.createChannelCard),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: channels.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Material(
                color: TupicColors.card,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: TupicColors.borderSubtle),
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
                  subtitle: Text(
                    '${channel.isKidsChannel ? l10n.kidsBadge : l10n.generalBadge} · ${l10n.videoCount(channel.videoCount)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openManage(context, channel),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
