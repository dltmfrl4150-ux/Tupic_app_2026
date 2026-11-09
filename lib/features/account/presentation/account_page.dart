import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/google_auth_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../legal/domain/legal_document.dart';
import '../../legal/presentation/consent_panel.dart';
import '../../legal/presentation/legal_document_page.dart';

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
      case GoogleSignInCanceled():
        // Cancellation is not an error — silent.
        break;
      case GoogleSignInFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_localizeFailure(l10n, message))),
        );
    }
  }

  String _localizeFailure(AppLocalizations l10n, String message) {
    // Prefer localized generic when service returns English fallbacks.
    if (message.contains('only available on the Android')) {
      return l10n.accountSignInUnavailable;
    }
    if (message.contains('already in progress')) {
      return l10n.accountSignInBusy;
    }
    if (message.contains('Network')) {
      return l10n.accountSignInNetworkError;
    }
    return l10n.accountSignInFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = AuthScope.of(context);

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
          ListenableBuilder(
            listenable: auth,
            builder: (context, _) {
              if (auth.isSignedIn) {
                return _SignedInCard(
                  displayName: auth.displayName ?? l10n.accountAnonymousName,
                  email: auth.email ?? '',
                  photoUrl: auth.photoUrl,
                  busy: auth.busy,
                  onSignOut: () async {
                    await auth.signOut();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.accountSignedOut)),
                    );
                  },
                );
              }
              return _SignedOutCard(
                firebaseReady: auth.firebaseReady,
                busy: auth.busy,
                onContinue: () => _onGoogleContinue(auth),
              );
            },
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
    required this.onSignOut,
  });

  final String displayName;
  final String email;
  final String? photoUrl;
  final bool busy;
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
