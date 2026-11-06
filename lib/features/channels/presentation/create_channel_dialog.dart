import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/tupic_channel.dart';
import '../../../shared/repositories/channel_repository.dart';
import 'channels_controller.dart';
import 'premium_upsell_page.dart';

Future<TupicChannel?> showCreateChannelDialog(BuildContext context) {
  return showDialog<TupicChannel>(
    context: context,
    builder: (dialogContext) => const _CreateChannelDialog(),
  );
}

class _CreateChannelDialog extends StatefulWidget {
  const _CreateChannelDialog();

  @override
  State<_CreateChannelDialog> createState() => _CreateChannelDialogState();
}

class _CreateChannelDialogState extends State<_CreateChannelDialog> {
  final _controller = TextEditingController();
  bool _isKidsChannel = true;
  String? _errorText;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = l10n.channelNameRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final channels = ChannelsScope.of(context);
    try {
      final channel = await channels.createChannel(
        name: name,
        isKidsChannel: _isKidsChannel,
      );
      if (!mounted) return;
      Navigator.of(context).pop(channel);
    } on ChannelLimitExceededException {
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PremiumUpsellPage()),
      );
    } on InvalidChannelNameException {
      if (!mounted) return;
      setState(() {
        _errorText = l10n.channelNameRequired;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = l10n.errorTitle;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.createChannelDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: l10n.createChannelNameHint,
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _isKidsChannel,
            activeColor: TupicColors.accentViolet,
            title: Text(l10n.createChannelKidsCheckbox),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: _submitting
                ? null
                : (value) {
                    setState(() => _isKidsChannel = value ?? true);
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
