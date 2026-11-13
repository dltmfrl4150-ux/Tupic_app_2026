import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/channels/data/local_channel_repository.dart';
import '../features/channels/presentation/channels_controller.dart';
import '../features/content/data/http_youtube_playlist_provider.dart';
import '../features/content/data/local_content_repository.dart';
import '../features/content/data/playlist_video_fetcher.dart';
import '../features/content/presentation/content_controller.dart';
import '../features/explore/data/firestore_shared_channel_catalog_repository.dart';
import '../features/explore/presentation/shared_catalog_scope.dart';
import '../features/home/data/mock_home_repository.dart';
import '../features/home/presentation/home_controller.dart';
import '../features/home/presentation/home_page.dart';
import '../features/player/data/local_playback_progress_repository.dart';
import '../features/player/presentation/playback_progress_scope.dart';
import '../features/profile/data/firestore_public_profile_repository.dart';
import '../features/profile/data/unavailable_public_profile_repository.dart';
import '../features/profile/presentation/public_profile_controller.dart';
import '../features/share/data/firestore_channel_share_repository.dart';
import '../features/share/data/unavailable_channel_share_repository.dart';
import '../features/share/presentation/channel_share_controller.dart';
import '../l10n/app_localizations.dart';
import '../shared/repositories/channel_repository.dart';
import '../shared/repositories/channel_share_repository.dart';
import '../shared/repositories/content_repository.dart';
import '../shared/repositories/home_repository.dart';
import '../shared/repositories/playback_progress_repository.dart';
import '../shared/repositories/public_profile_repository.dart';
import '../shared/repositories/shared_channel_catalog_repository.dart';
import 'locale_controller.dart';
import 'theme/tupic_theme.dart';

class TupicApp extends StatefulWidget {
  const TupicApp({
    super.key,
    required this.localeController,
    this.firebaseReady = false,
    this.authController,
    this.homeRepository,
    this.channelRepository,
    this.contentRepository,
    this.playbackProgressRepository,
    this.publicProfileRepository,
    this.publicProfileController,
    this.channelShareRepository,
    this.channelShareController,
    this.sharedChannelCatalogRepository,
    this.playlistFetcher,
    this.channelsController,
    this.contentController,
  });

  final LocaleController localeController;

  /// True after successful Firebase.initializeApp (Android / Web).
  final bool firebaseReady;

  /// Optional override for tests.
  final AuthController? authController;
  final HomeRepository? homeRepository;
  final ChannelRepository? channelRepository;
  final ContentRepository? contentRepository;
  final PlaybackProgressRepository? playbackProgressRepository;
  final PublicProfileRepository? publicProfileRepository;
  final PublicProfileController? publicProfileController;
  final ChannelShareRepository? channelShareRepository;
  final ChannelShareController? channelShareController;
  final SharedChannelCatalogRepository? sharedChannelCatalogRepository;
  final PlaylistVideoFetcher? playlistFetcher;
  final ChannelsController? channelsController;
  final ContentController? contentController;

  @override
  State<TupicApp> createState() => _TupicAppState();
}

class _TupicAppState extends State<TupicApp> {
  late final ChannelRepository _channelRepository =
      widget.channelRepository ?? LocalChannelRepository();

  late final ContentRepository _contentRepository =
      widget.contentRepository ?? LocalContentRepository();

  late final PlaybackProgressRepository _progressRepository =
      widget.playbackProgressRepository ?? LocalPlaybackProgressRepository();

  late final ChannelsController _channelsController =
      widget.channelsController ??
          ChannelsController(
            repository: _channelRepository,
            contentRepository: _contentRepository,
            progressRepository: _progressRepository,
          );

  late final PlaylistVideoFetcher _playlistFetcher =
      widget.playlistFetcher ?? HttpYoutubePlaylistProvider.create();

  late final ContentController _contentController =
      widget.contentController ??
          ContentController(
            contentRepository: _contentRepository,
            channelRepository: _channelRepository,
            channelsController: _channelsController,
            playlistFetcher: _playlistFetcher,
          );

  late final HomeController _homeController = HomeController(
    repository: widget.homeRepository ?? MockHomeRepository(),
    channelsController: _channelsController,
  );

  late final AuthController _authController =
      widget.authController ??
      AuthController(firebaseReady: widget.firebaseReady);

  late final PublicProfileRepository _publicProfileRepository =
      widget.publicProfileRepository ??
      (widget.firebaseReady
          ? FirestorePublicProfileRepository()
          : const UnavailablePublicProfileRepository(
              'Firebase/Firestore is not ready on this build.',
            ));

  late final PublicProfileController _publicProfileController =
      widget.publicProfileController ??
      PublicProfileController(
        authController: _authController,
        repository: _publicProfileRepository,
      );

  late final ChannelShareRepository _channelShareRepository =
      widget.channelShareRepository ??
      (widget.firebaseReady
          ? FirestoreChannelShareRepository()
          : const UnavailableChannelShareRepository(
              'Firebase/Firestore is not ready on this build.',
            ));

  late final ChannelShareController _channelShareController =
      widget.channelShareController ??
      ChannelShareController(
        authController: _authController,
        profileController: _publicProfileController,
        repository: _channelShareRepository,
      );

  late final SharedChannelCatalogRepository _sharedCatalog =
      widget.sharedChannelCatalogRepository ??
      (widget.firebaseReady
          ? FirestoreSharedChannelCatalogRepository()
          : const EmptySharedChannelCatalogRepository());

  bool _ownsChannelsController = false;
  bool _ownsContentController = false;
  bool _ownsAuthController = false;
  bool _ownsPublicProfileController = false;
  bool _ownsChannelShareController = false;

  @override
  void initState() {
    super.initState();
    _ownsChannelsController = widget.channelsController == null;
    _ownsContentController = widget.contentController == null;
    _ownsAuthController = widget.authController == null;
    _ownsPublicProfileController = widget.publicProfileController == null;
    _ownsChannelShareController = widget.channelShareController == null;
    _channelsController.load().then((_) {
      final ids = _channelsController.channels.map((c) => c.id);
      return _contentController.refreshCounts(ids);
    });
  }

  @override
  void dispose() {
    _homeController.dispose();
    if (_ownsChannelShareController) {
      _channelShareController.dispose();
    }
    if (_ownsPublicProfileController) {
      _publicProfileController.dispose();
    }
    if (_ownsAuthController) {
      _authController.dispose();
    }
    if (_ownsContentController) {
      _contentController.dispose();
    }
    if (_ownsChannelsController) {
      _channelsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: widget.localeController,
      child: AuthScope(
        controller: _authController,
        child: PublicProfileScope(
          controller: _publicProfileController,
          child: ChannelShareScope(
            controller: _channelShareController,
            child: SharedCatalogScope(
              catalog: _sharedCatalog,
              child: ChannelsScope(
                controller: _channelsController,
                child: ContentScope(
                  controller: _contentController,
                  child: PlaybackProgressScope(
                    repository: _progressRepository,
                    child: ListenableBuilder(
                      listenable: widget.localeController,
                      builder: (context, _) {
                        return MaterialApp(
                          title: 'TUPIC',
                          debugShowCheckedModeBanner: false,
                          theme: TupicTheme.dark(),
                          locale: widget.localeController.localeOverride,
                          supportedLocales: AppLocalizations.supportedLocales,
                          localizationsDelegates: const [
                            AppLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                          ],
                          localeResolutionCallback: (locale, supported) {
                            if (locale == null) return const Locale('en');
                            for (final supportedLocale in supported) {
                              if (supportedLocale.languageCode ==
                                  locale.languageCode) {
                                return supportedLocale;
                              }
                            }
                            return const Locale('en');
                          },
                          home: HomePage(controller: _homeController),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
