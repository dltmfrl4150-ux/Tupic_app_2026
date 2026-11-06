import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

Future<void> showComingSoonDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.comingSoonTitle),
        content: Text(l10n.comingSoonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.comingSoonOk),
          ),
        ],
      );
    },
  );
}

void showComingSoonSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.comingSoonBody)));
}
