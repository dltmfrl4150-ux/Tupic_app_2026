import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/google_auth_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../legal/domain/legal_document.dart';
import '../../legal/presentation/consent_panel.dart';
import '../../legal/presentation/legal_document_page.dart';
import '../../profile/domain/nickname_validator.dart';
import '../../profile/presentation/public_profile_controller.dart';
import '../../share/presentation/my_shared_channels_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<void> _onGoogleContinue(AuthController auth) async {
    final l10n = AppLocalizations.of(context);
    final consented = await ConsentFlow().ensureTermsConsent(context);
    if (!mounted) return;
    if (!consented) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountConsentRequired)),
      );
      return;
    }

    final outcome = await auth.signInWithGoogle();
    if (!mounted) return;

    switch (outcome) {
      case GoogleSignInSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountSignInSuccess)),
        );
        await PublicProfileScope.maybeOf(context)?.refresh();
      case GoogleSignInCanceled():
        break;
      case GoogleSignInFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_localizeFailure(l10n, message))),
        );
    }
  }

  String _localizeFailure(AppLocalizations l10n, String message) {
    if (message.contains('only available when Firebase') ||
        message.contains('only available on the Android')) {
      return l10n.accountSignInUnavailable;
    }
    if (message.contains('already in progress')) {
      return l10n.accountSignInBusy;
    }
    if (message.contains('popup was blocked') ||
        message.contains('Allow popups')) {
      return l10n.accountSignInPopupBlocked;
    }
    if (message.contains('not authorized') ||
        message.contains('unauthorized-domain')) {
      return l10n.accountSignInUnauthorizedDomain;
    }
    if (message.contains('Network')) {
      return l10n.accountSignInNetworkError;
    }
    return l10n.accountSignInFailed;
  }

  String _nicknameErrorText(
    AppLocalizations l10n,
    PublicProfileController profile,
  ) {
    final validation = profile.validationError;
    if (validation != null) {
      return switch (validation) {
        NicknameValidationError.empty => l10n.accountNicknameInvalidEmpty,
        NicknameValidationError.tooShort ||
        NicknameValidationError.tooLong =>
          l10n.accountNicknameInvalidLength,
        NicknameValidationError.invalidCharacters =>
          l10n.accountNicknameInvalidChars,
        NicknameValidationError.inappropriate =>
          l10n.accountNicknameInappropriate,
      };
    }
    return switch (profile.errorCode) {
      'not_signed_in' => l10n.accountNicknameNotSignedIn,
      'permission_denied' => l10n.accountNicknamePermissionDenied,
      'firestore_unavailable' => l10n.accountNicknameUnavailable,
      'save_failed' || 'load_failed' => l10n.accountNicknameSaveFailed,
      _ => l10n.accountNicknameSaveFailed,
    };
  }

  Future<void> _editNickname(PublicProfileController profile) async {
    final l10n = AppLocalizations.of(context);
    final auth = AuthScope.of(context);
    final hasNickname = profile.hasNickname;
    final googleName = auth.displayName?.trim();
    final initial = hasNickname
        ? (profile.nickname ?? '')
        : (googleName != null && googleName.isNotEmpty ? googleName : '');
    final suggestGoogle =
        !hasNickname && googleName != null && googleName.isNotEmpty;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: !profile.saving,
      builder: (dialogContext) {
        return _NicknameEditDialog(
          profile: profile,
          initialText: initial,
          suggestGoogle: suggestGoogle,
          errorTextBuilder: (profile) => _nicknameErrorText(l10n, profile),
        );
      },
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.accountNicknameSaveSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // AuthScope / PublicProfileScope are InheritedNotifier — rebuilds arrive
    // here without Listenable.merge (avoids disposed-listener races).
    final auth = AuthScope.of(context);
    final profile = PublicProfileScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          if (auth.isSignedIn)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.accountGoogleSectionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: TupicColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                _SignedInCard(
                  displayName: auth.displayName ?? l10n.accountAnonymousName,
                  email: auth.email ?? '',
                  photoUrl: auth.photoUrl,
                  busy: auth.busy,
                  showDeveloperTestPremium: auth.isDeveloperTestPremium,
                  onSignOut: () async {
                    await auth.signOut();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.accountSignedOut)),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.accountPublicNicknameSectionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: TupicColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                _PublicNicknameCard(
                  nickname: profile.nickname,
                  loading: profile.loading,
                  saving: profile.saving,
                  onEdit: () => _editNickname(profile),
                ),
                const SizedBox(height: 20),
                ListTile(
                  key: const Key('account_my_shared_channels'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.share_outlined,
                    color: TupicColors.accentViolet,
                  ),
                  title: Text(l10n.mySharedChannelsTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MySharedChannelsPage(),
                      ),
                    );
                  },
                ),
              ],
            )
          else
            _SignedOutCard(
              firebaseReady: auth.firebaseReady,
              busy: auth.busy,
              onContinue: () => _onGoogleContinue(auth),
            ),
          const SizedBox(height: 16),
          Text(
            l10n.accountUnder14Policy,
            style: const TextStyle(
              color: TupicColors.mutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => openLegalDocument(
                context,
                LegalDocumentKind.privacyPolicy,
              ),
              child: Text(l10n.privacyPolicyViewAlways),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns [TextEditingController] for the dialog lifetime (dispose in [State]).
class _NicknameEditDialog extends StatefulWidget {
  const _NicknameEditDialog({
    required this.profile,
    required this.initialText,
    required this.suggestGoogle,
    required this.errorTextBuilder,
  });

  final PublicProfileController profile;
  final String initialText;
  final bool suggestGoogle;
  final String Function(PublicProfileController profile) errorTextBuilder;

  @override
  State<_NicknameEditDialog> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends State<_NicknameEditDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || widget.profile.saving) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final ok = await widget.profile.saveNickname(_controller.text);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitting = false;
      _errorText = widget.errorTextBuilder(widget.profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _submitting || widget.profile.saving;

    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(l10n.accountNicknameDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountPublicNicknameHint,
              style: const TextStyle(
                color: TupicColors.mutedText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (widget.suggestGoogle) ...[
              const SizedBox(height: 8),
              Text(
                l10n.accountNicknameSuggestGoogle,
                style: const TextStyle(
                  color: TupicColors.mutedText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const Key('account_nickname_field'),
              controller: _controller,
              autofocus: true,
              enabled: !busy,
              maxLength: NicknameValidator.maxLength,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.accountPublicNicknameLabel,
                errorText: _errorText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            key: const Key('account_nickname_save'),
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _PublicNicknameCard extends StatelessWidget {
  const _PublicNicknameCard({
    required this.nickname,
    required this.loading,
    required this.saving,
    required this.onEdit,
  });

  final String? nickname;
  final bool loading;
  final bool saving;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasNickname = nickname != null && nickname!.trim().isNotEmpty;
    return Container(
      key: const Key('account_public_nickname_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.accountPublicNicknameHint,
            style: const TextStyle(
              color: TupicColors.mutedText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Text(
              hasNickname ? nickname! : l10n.accountPublicNicknameEmpty,
              key: const Key('account_public_nickname_value'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: hasNickname
                    ? TupicColors.primaryText
                    : TupicColors.mutedText,
              ),
            ),
          const SizedBox(height: 14),
          ElevatedButton(
            key: const Key('account_edit_nickname'),
            onPressed: (loading || saving) ? null : onEdit,
            child: Text(
              hasNickname
                  ? l10n.accountChangeNickname
                  : l10n.accountSetNickname,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard({
    required this.firebaseReady,
    required this.busy,
    required this.onContinue,
  });

  final bool firebaseReady;
  final bool busy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.accountGuestTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TupicColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.accountGuestBody,
            style: const TextStyle(color: TupicColors.mutedText, height: 1.45),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('account_google_sign_in'),
            onPressed: (!firebaseReady || busy) ? null : onContinue,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(l10n.accountContinueWithGoogle),
          ),
          if (!firebaseReady) ...[
            const SizedBox(height: 10),
            Text(
              l10n.accountSignInUnavailable,
              style: const TextStyle(
                color: TupicColors.mutedText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.busy,
    required this.showDeveloperTestPremium,
    required this.onSignOut,
  });

  final String displayName;
  final String email;
  final String? photoUrl;
  final bool busy;
  final bool showDeveloperTestPremium;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TupicColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TupicColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: TupicColors.selected,
                backgroundImage:
                    photoUrl != null && photoUrl!.isNotEmpty
                        ? NetworkImage(photoUrl!)
                        : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: TupicColors.primaryText,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TupicColors.primaryText,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: TupicColors.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (showDeveloperTestPremium) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.premiumDeveloperTestBadge,
                        key: const Key('account_dev_premium_badge'),
                        style: const TextStyle(
                          color: TupicColors.accentViolet,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.accountLocalDataNote,
            style: const TextStyle(
              color: TupicColors.mutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const Key('account_sign_out'),
            onPressed: busy ? null : onSignOut,
            child: Text(l10n.accountSignOut),
          ),
        ],
      ),
    );
  }
}
