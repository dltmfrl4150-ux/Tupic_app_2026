import 'package:flutter/material.dart';

import '../../../app/theme/tupic_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/share_models.dart';
import '../../account/presentation/account_page.dart';
import '../../auth/presentation/auth_controller.dart';
import 'channel_share_controller.dart';

class MySharedChannelsPage extends StatefulWidget {
  const MySharedChannelsPage({super.key});

  @override
  State<MySharedChannelsPage> createState() => _MySharedChannelsPageState();
}

class _MySharedChannelsPageState extends State<MySharedChannelsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChannelShareScope.of(context).refreshMyPosts();
    });
  }

  Future<void> _cancel(SharePost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.shareCancelTitle),
          content: Text(l10n.shareCancelBody(post.title, post.version)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.shareCancelConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final share = ChannelShareScope.of(context);
    final ok = await share.cancelPost(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.shareCancelSuccess : l10n.shareCancelFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = AuthScope.of(context);
    final share = ChannelShareScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySharedChannelsTitle),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([auth, share]),
        builder: (context, _) {
          if (!auth.isSignedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.shareNeedSignIn, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AccountPage(),
                          ),
                        );
                      },
                      child: Text(l10n.accountContinueWithGoogle),
                    ),
                  ],
                ),
              ),
            );
          }
          if (share.loadingMine) {
            return const Center(child: CircularProgressIndicator());
          }
          if (share.myPosts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.mySharedChannelsEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TupicColors.mutedText),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: share.refreshMyPosts,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: share.myPosts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final post = share.myPosts[index];
                final date = post.createdAt.toLocal().toString().split('.').first;
                final statusLabel = post.isPublished
                    ? l10n.shareStatusPublished
                    : l10n.shareStatusCancelled;
                return Material(
                  color: TupicColors.card,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TupicColors.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'v${post.version} · $statusLabel · ${l10n.videoCount(post.videoCount)}',
                                  style: const TextStyle(
                                    color: TupicColors.mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: TupicColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (post.isPublished)
                            IconButton(
                              tooltip: l10n.shareCancelAction,
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: () => _cancel(post),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
