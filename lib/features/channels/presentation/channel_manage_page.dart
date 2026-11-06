import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/play_order.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/repositories/channel_repository.dart';
import 'channels_controller.dart';

class ChannelManagePage extends StatefulWidget {
  const ChannelManagePage({super.key, required this.channelId});

  final String channelId;

  @override
  State<ChannelManagePage> createState() => _ChannelManagePageState();
}

class _ChannelManagePageState extends State<ChannelManagePage> {
  final _nameController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(TupicChannel channel) async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelNameRequired)),
      );
      return;
    }
    if (name == channel.name) return;

    setState(() => _saving = true);
    try {
      await ChannelsScope.of(context).renameChannel(
        id: channel.id,
        name: name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelRenamed)),
      );
    } on InvalidChannelNameException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.channelNameRequired)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setPlayOrder(TupicChannel channel, PlayOrder order) async {
    if (channel.playOrder == order) return;
    setState(() => _saving = true);
    try {
      await ChannelsScope.of(context).updatePlayOrder(
        id: channel.id,
        playOrder: order,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(TupicChannel channel) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteChannelTitle),
          content: Text(l10n.deleteChannelBody(channel.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await ChannelsScope.of(context).deleteChannel(channel.id);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channelsController = ChannelsScope.of(context);

    return ListenableBuilder(
      listenable: channelsController,
      builder: (context, _) {
        TupicChannel? channel;
        for (final item in channelsController.channels) {
          if (item.id == widget.channelId) {
            channel = item;
            break;
          }
        }

        if (channel == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.menuManageChannels)),
            body: Center(child: Text(l10n.channelNotFound)),
          );
        }

        if (!_initialized) {
          _nameController.text = channel.name;
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.menuManageChannels),
            leading: IconButton(
              tooltip: l10n.back,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                l10n.createChannelNameHint,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: TupicColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: l10n.createChannelNameHint,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _saveName(channel!),
                  child: Text(l10n.save),
                ),
              ),
              const SizedBox(height: 20),
              _MetaRow(
                label: l10n.channelTypeLabel,
                value: channel.isKidsChannel
                    ? l10n.kidsBadge
                    : l10n.generalBadge,
              ),
              _MetaRow(
                label: l10n.registeredVideosLabel,
                value: l10n.videoCount(channel.videoCount),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.playOrderLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: TupicColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PlayOrder>(
                segments: [
                  ButtonSegment(
                    value: PlayOrder.sequential,
                    label: Text(l10n.playOrderSequential),
                    icon: const Icon(Icons.reorder),
                  ),
                  ButtonSegment(
                    value: PlayOrder.shuffle,
                    label: Text(l10n.playOrderShuffle),
                    icon: const Icon(Icons.shuffle),
                  ),
                ],
                selected: {channel.playOrder},
                onSelectionChanged: _saving
                    ? null
                    : (values) {
                        if (values.isNotEmpty) {
                          _setPlayOrder(channel!, values.first);
                        }
                      },
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: TupicColors.error,
                  side: const BorderSide(color: TupicColors.error),
                ),
                onPressed: _saving ? null : () => _confirmDelete(channel!),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.deleteChannel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TupicColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TupicColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: TupicColors.mutedText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: TupicColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
