// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TUPIC';

  @override
  String helloUser(String name) {
    return 'Hello, $name!';
  }

  @override
  String get menuOpen => 'Open menu';

  @override
  String get menuClose => 'Close menu';

  @override
  String get menuChannels => 'Channels';

  @override
  String get menuCreateChannel => 'Create channel';

  @override
  String get menuManageChannels => 'Manage channels';

  @override
  String get menuImportSharedChannel => 'Import shared channel';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuMyAccount => 'My account';

  @override
  String get menuPremiumHint => 'Premium plans arrive in a later update.';

  @override
  String get myChannels => 'My Channels';

  @override
  String get recommended => 'Recommended';

  @override
  String get exploreMyContent => 'Explore My Content';

  @override
  String get createChannelCard => 'Create channel';

  @override
  String get kidsBadge => 'Kids';

  @override
  String get generalBadge => 'General';

  @override
  String videoCount(int count) {
    return '$count videos';
  }

  @override
  String get playChannel => 'Play';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryEnglish => 'English';

  @override
  String get categoryMusic => 'Music';

  @override
  String get categoryScience => 'Science';

  @override
  String get categoryArt => 'Art';

  @override
  String get categoryAnimals => 'Animals';

  @override
  String get categoryOther => 'Other';

  @override
  String get loading => 'Loading…';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorRetry => 'Try again';

  @override
  String get emptyChannelsTitle => 'No channels yet';

  @override
  String get emptyChannelsBody =>
      'Create your first TUPIC channel to start curating YouTube content.';

  @override
  String get emptyRecommendedTitle => 'No recommendations yet';

  @override
  String get emptyRecommendedBody =>
      'Recommendations appear after channels have popular videos.';

  @override
  String get emptyExploreTitle => 'No videos in this category';

  @override
  String get emptyExploreBody =>
      'Try another category or add more videos to your channels.';

  @override
  String get mockDataBanner => 'Demo data — not linked to a live account';

  @override
  String get demoContentBanner =>
      'Recommended & Explore show demo content — not your saved videos';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonBody =>
      'This feature will be available in a later update.';

  @override
  String get comingSoonOk => 'OK';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get accountTitle => 'My account';

  @override
  String get accountPlaceholder =>
      'Sign-in will be available when Firebase Authentication is connected.';

  @override
  String get helloGuest => 'Hello!';

  @override
  String get accountGuestTitle => 'Account';

  @override
  String get accountGuestBody =>
      'Sign in with Google to see your account details. You can keep using local channels without signing in.';

  @override
  String get accountContinueWithGoogle => 'Continue with Google';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignedOut =>
      'Signed out. Local channel data is kept on this device.';

  @override
  String get accountSignInSuccess => 'Signed in with Google.';

  @override
  String get accountSignInFailed => 'Sign-in failed. Please try again.';

  @override
  String get accountSignInBusy => 'Sign-in is already in progress.';

  @override
  String get accountSignInNetworkError =>
      'Network error. Check your connection and try again.';

  @override
  String get accountSignInUnavailable =>
      'Google sign-in is unavailable in this build. Use the Android Firebase build.';

  @override
  String get accountConsentRequired =>
      'Please accept the required terms to continue.';

  @override
  String get accountAnonymousName => 'Google user';

  @override
  String get accountLocalDataNote =>
      'Local channels, videos, and resume data are not shown as owned by this Google account and are not uploaded automatically.';

  @override
  String get accountUnder14Policy =>
      'Independent accounts for users under 14 are not allowed until a lawful parental-consent process is ready. A Google account alone is not age verification, and this build does not provide reliable age verification.';

  @override
  String get createChannelDialogTitle => 'Create channel';

  @override
  String get createChannelNameHint => 'Channel name';

  @override
  String get createChannelKidsCheckbox => 'Kids channel';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get channelNameRequired => 'Enter a channel name.';

  @override
  String get selectAudienceTitle => 'What would you like to explore?';

  @override
  String get selectAudienceKids => 'Kids content';

  @override
  String get selectAudienceGeneral => 'General content';

  @override
  String get back => 'Back';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumBody =>
      'More channels, higher limits, and auto-sync. Billing is not enabled yet.';

  @override
  String get premiumLimitTitle => 'Free plan channel limit';

  @override
  String premiumLimitBody(int count) {
    return 'The free plan allows up to $count channel. Upgrade to Premium for more channels.';
  }

  @override
  String get premiumBillingDisabled =>
      'Payments are not enabled in this version.';

  @override
  String get channelDetailTitle => 'Channel';

  @override
  String get channelNotFound => 'This channel is no longer available.';

  @override
  String get manageThisChannel => 'Manage channel';

  @override
  String get channelVideosComingSoon =>
      'Adding YouTube videos will be available in the next step.';

  @override
  String get playOrderLabel => 'Playback order';

  @override
  String get playOrderSequential => 'Sequential';

  @override
  String get playOrderShuffle => 'Shuffle';

  @override
  String get channelTypeLabel => 'Channel type';

  @override
  String get registeredVideosLabel => 'Registered videos';

  @override
  String get channelRenamed => 'Channel name updated.';

  @override
  String get deleteChannel => 'Delete channel';

  @override
  String get deleteChannelTitle => 'Delete channel?';

  @override
  String deleteChannelBody(String name) {
    return 'Delete \"$name\"? Only this channel’s local data will be removed.';
  }

  @override
  String get parentalGateTitle => 'Parent check';

  @override
  String get parentalGateBody =>
      'Enter your birth year to continue to kids channel management.';

  @override
  String get parentalGateHint => 'YYYY';

  @override
  String get parentalGateContinue => 'Continue';

  @override
  String get parentalGateInvalidYear => 'Enter a valid 4-digit birth year.';

  @override
  String get parentalGateDenied => 'Access is limited to ages 18 and over.';

  @override
  String get parentalGateDisclaimer =>
      'This is a simple access check, not legal age verification.';

  @override
  String get importSharedPlaceholder =>
      'Importing a shared TUPIC channel will be available in a later update.';

  @override
  String get addContentTitle => 'Add content';

  @override
  String get manageContentTitle => 'Manage content';

  @override
  String get addContentUrlHint => 'Paste a YouTube link';

  @override
  String get paste => 'Paste';

  @override
  String get analyzeUrl => 'Analyze';

  @override
  String get registerContent => 'Register';

  @override
  String get displayNameHint => 'Display name';

  @override
  String get contentTypeVideo => 'Video';

  @override
  String get contentTypePlaylist => 'Playlist';

  @override
  String get contentTypeCreator => 'Creator';

  @override
  String get contentUrlEmpty => 'Enter a YouTube URL.';

  @override
  String get contentUrlInvalid => 'This YouTube link is not supported.';

  @override
  String get contentUrlUnsupportedHost =>
      'Only official YouTube links are allowed.';

  @override
  String get contentUrlRedirectBlocked => 'Redirect links are not followed.';

  @override
  String get contentDuplicateVideo =>
      'This video is already registered in this channel.';

  @override
  String contentVideoLimit(int count) {
    return 'Free plan allows up to $count videos per channel.';
  }

  @override
  String get contentAmbiguousTitle =>
      'This link includes a video and a playlist';

  @override
  String get contentAmbiguousVideo => 'Add this video only';

  @override
  String get contentAmbiguousPlaylist => 'Add the whole playlist';

  @override
  String get playlistPendingFetch =>
      'Playlist source saved. Video list fetch waits for YouTube API.';

  @override
  String get creatorPendingFetch =>
      'Creator source saved. Video list fetch waits for YouTube API.';

  @override
  String get creatorImportModeLabel => 'Import range';

  @override
  String get creatorImportRecent30 => 'Latest 30';

  @override
  String get creatorImportAll => 'All videos';

  @override
  String get creatorImportManual => 'Pick manually';

  @override
  String get creatorManualNeedsApi =>
      'Manual selection will be available after YouTube API is connected.';

  @override
  String get creatorSortLabel => 'Sort order';

  @override
  String get creatorSortNewest => 'Newest';

  @override
  String get creatorSortOldest => 'Oldest';

  @override
  String get creatorSortShuffle => 'Shuffle';

  @override
  String get autoSyncLabel => 'Auto sync (Premium)';

  @override
  String get autoSyncFreeLocked =>
      'Auto sync is Premium-only and is not running yet.';

  @override
  String get autoSyncPremiumHint =>
      'Premium can auto-check once per day (not enabled in this build).';

  @override
  String get contentSourcesSection => 'Content sources';

  @override
  String get contentVideosSection => 'Videos';

  @override
  String get emptySourcesBody =>
      'No content sources yet. Add a YouTube link to get started.';

  @override
  String get emptyVideosBody =>
      'No confirmed videos yet. Individual video links appear here immediately.';

  @override
  String get apiNotConnectedBanner =>
      'Playlist and creator videos are not fetched until YouTube API is connected.';

  @override
  String get importStatusReady => 'Ready';

  @override
  String get importStatusPending => 'Waiting to fetch';

  @override
  String get importStatusFetching => 'Fetching';

  @override
  String get importStatusFetched => 'Fetched';

  @override
  String get importStatusPartial => 'Partially fetched';

  @override
  String get importStatusFailed => 'Failed';

  @override
  String get fetchPlaylistVideos => 'Fetch videos';

  @override
  String get retryFetchPlaylist => 'Retry';

  @override
  String playlistFetchedCount(int count) {
    return 'Fetched $count videos';
  }

  @override
  String playlistFetchReport(
    int imported,
    int privateDeleted,
    int notEmbeddable,
    int duplicates,
  ) {
    return 'Imported: $imported · Private/deleted excluded: $privateDeleted · Not embeddable excluded: $notEmbeddable · Duplicates: $duplicates';
  }

  @override
  String playlistFetchReportPruned(int pruned) {
    return 'Cleaned $pruned previously saved unplayable videos';
  }

  @override
  String get localServerRequired =>
      'Local YouTube server required. Run npm start in the server folder.';

  @override
  String get localApiKeyRequired =>
      'YOUTUBE_API_KEY is not set on the local server. Check server/.env.';

  @override
  String get quotaExceededMessage =>
      'YouTube API quota exceeded. Try again later.';

  @override
  String get dailyLocalLimitMessage => 'Local daily API request limit reached.';

  @override
  String get playlistFetchUnexpectedError =>
      'Could not fetch the playlist. Fully restart the app, confirm the local server (npm start), then try again.';

  @override
  String lastFetchedAtLabel(String time) {
    return 'Last fetched: $time';
  }

  @override
  String videoLimitLabel(int current, int max) {
    return '$current / $max';
  }

  @override
  String queuePreviewCount(int count) {
    return 'Playback queue: $count';
  }

  @override
  String get deleteSourceTitle => 'Delete content source?';

  @override
  String deleteSourceBody(String name) {
    return 'Delete \"$name\"? Videos only linked to this source will be removed. Videos linked to other sources stay.';
  }

  @override
  String deleteSourceResult(int removed, int kept) {
    return 'Removed $removed video(s). Kept $kept shared video(s).';
  }

  @override
  String get deleteVideoTitle => 'Delete video?';

  @override
  String deleteVideoBody(String title) {
    return 'Delete \"$title\" from this channel?';
  }

  @override
  String get excludeVideo => 'Exclude from playback';

  @override
  String get restoreVideo => 'Restore to playback';

  @override
  String get videoExcluded => 'Excluded';

  @override
  String get reorderHint => 'Long-press and drag to change video order.';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerVideoList => 'Video list';

  @override
  String get playerSwitchChannel => 'Switch channel';

  @override
  String get playerChannelListTitle => 'TUPICK channels';

  @override
  String get playerLock => 'Screen lock';

  @override
  String get playerUnlock => 'Unlock';

  @override
  String get playerUnlockHint => 'Long press to unlock';

  @override
  String get playerNextVideo => 'Next video';

  @override
  String get playerRetry => 'Retry';

  @override
  String get playerEmptyQueue => 'No videos to play';

  @override
  String get playerVideoUnavailable => 'This video cannot be played';

  @override
  String get playerAllVideosUnavailable =>
      'No playable videos remain in this queue';

  @override
  String get playerPlaybackError => 'A playback error occurred';

  @override
  String get playerLastVideo => 'That was the last video';

  @override
  String get playerReplayQueue => 'Play again from start';

  @override
  String get playerWebOrientationHint =>
      'Browsers cannot lock orientation. Use landscape layout to watch.';

  @override
  String get playNow => 'Play now';

  @override
  String get playerResume => 'Resume';

  @override
  String get playerLastPosition => 'Last watched position';

  @override
  String get playerPreparing => 'Preparing playback…';

  @override
  String get playlistFetchPending => 'Waiting to fetch videos';

  @override
  String get playlistVideosNotFetchedYet =>
      'Playlist videos have not been fetched yet. Tap Fetch videos in content management.';

  @override
  String get playableVideosOnlyHint =>
      'Only confirmed playable videos are listed.';

  @override
  String sourceVsPlayableCount(int sources, int playable) {
    return '$sources sources · $playable playable';
  }

  @override
  String get settingsLegalSection => 'Terms & privacy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get legalView => 'View more';

  @override
  String legalVersionLabel(String version) {
    return 'Document version $version';
  }

  @override
  String get legalDraftNotice =>
      'This text is a draft. Unconfirmed business details are marked TODO in the document.';

  @override
  String get legalKoreanDraftNotice =>
      'This text is a draft. Unconfirmed business details are marked TODO in the document.';

  @override
  String get consentTitle => 'TUPICK service notice';

  @override
  String get consentSubtitle =>
      'Accept required items to continue. Opening a document alone does not count as consent.';

  @override
  String get consentTermsRequired => '[Required] Agree to the Terms of Service';

  @override
  String get consentPrivacyCollectionRequired =>
      '[Required] Agree to personal information collection & use';

  @override
  String get privacyPolicyViewAlways => 'View Privacy Policy';

  @override
  String get consentContinue => 'Agree and continue';
}
