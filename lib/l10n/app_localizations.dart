import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'TUPIC'**
  String get appName;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloUser(String name);

  /// No description provided for @menuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get menuOpen;

  /// No description provided for @menuClose.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get menuClose;

  /// No description provided for @menuChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get menuChannels;

  /// No description provided for @menuCreateChannel.
  ///
  /// In en, this message translates to:
  /// **'Create channel'**
  String get menuCreateChannel;

  /// No description provided for @menuManageChannels.
  ///
  /// In en, this message translates to:
  /// **'Manage channels'**
  String get menuManageChannels;

  /// No description provided for @menuImportSharedChannel.
  ///
  /// In en, this message translates to:
  /// **'Explore channels'**
  String get menuImportSharedChannel;

  /// No description provided for @exploreChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore channels'**
  String get exploreChannelsTitle;

  /// No description provided for @exploreBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore channels'**
  String get exploreBannerTitle;

  /// No description provided for @exploreBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Discover channels made by other people.'**
  String get exploreBannerBody;

  /// No description provided for @exploreBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Browse channels'**
  String get exploreBannerCta;

  /// No description provided for @homeExploreViewAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeExploreViewAll;

  /// No description provided for @homeExploreSearchEntry.
  ///
  /// In en, this message translates to:
  /// **'Search channels or content'**
  String get homeExploreSearchEntry;

  /// No description provided for @homeExploreCategoryPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get homeExploreCategoryPopular;

  /// No description provided for @homeExploreCategoryLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get homeExploreCategoryLatest;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'What channel are you looking for?'**
  String get exploreSearchHint;

  /// No description provided for @exploreSearchPrefixHint.
  ///
  /// In en, this message translates to:
  /// **'Prefix search on channel title (case-sensitive).'**
  String get exploreSearchPrefixHint;

  /// No description provided for @exploreSearchComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Search is coming soon.'**
  String get exploreSearchComingSoon;

  /// No description provided for @exploreCategoryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Category filters are coming soon.'**
  String get exploreCategoryComingSoon;

  /// No description provided for @exploreRecommendedSection.
  ///
  /// In en, this message translates to:
  /// **'Recommended channels'**
  String get exploreRecommendedSection;

  /// No description provided for @exploreLatestSection.
  ///
  /// In en, this message translates to:
  /// **'Latest channels'**
  String get exploreLatestSection;

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No shared channels yet.'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share a channel!'**
  String get exploreEmptyBody;

  /// No description provided for @exploreLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load shared channels.'**
  String get exploreLoadFailedTitle;

  /// No description provided for @exploreLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get exploreLoadFailedBody;

  /// No description provided for @exploreLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get exploreLoadMore;

  /// No description provided for @exploreShareMyChannel.
  ///
  /// In en, this message translates to:
  /// **'Share my channel'**
  String get exploreShareMyChannel;

  /// No description provided for @exploreShareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Channel sharing is on the way.'**
  String get exploreShareComingSoon;

  /// No description provided for @exploreNoLocalChannelsToShare.
  ///
  /// In en, this message translates to:
  /// **'You have no channels to share yet. Create a channel first.'**
  String get exploreNoLocalChannelsToShare;

  /// No description provided for @sharePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared channel'**
  String get sharePreviewTitle;

  /// No description provided for @sharePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This shared channel is unavailable.'**
  String get sharePreviewUnavailable;

  /// No description provided for @sharePreviewVideosSection.
  ///
  /// In en, this message translates to:
  /// **'Shared videos'**
  String get sharePreviewVideosSection;

  /// No description provided for @sharePreviewAddChannel.
  ///
  /// In en, this message translates to:
  /// **'Add channel'**
  String get sharePreviewAddChannel;

  /// No description provided for @sharePreviewAddVideos.
  ///
  /// In en, this message translates to:
  /// **'Add videos to my channel'**
  String get sharePreviewAddVideos;

  /// No description provided for @shareVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String shareVersionLabel(int version);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @exploreCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exploreCategoryAll;

  /// No description provided for @exploreCategoryKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get exploreCategoryKids;

  /// No description provided for @exploreCategoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get exploreCategoryEducation;

  /// No description provided for @exploreCategoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get exploreCategoryMusic;

  /// No description provided for @exploreCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get exploreCategoryEntertainment;

  /// No description provided for @exploreCategoryGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get exploreCategoryGames;

  /// No description provided for @exploreCategorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get exploreCategorySports;

  /// No description provided for @exploreCategoryLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get exploreCategoryLifestyle;

  /// No description provided for @exploreCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get exploreCategoryOther;

  /// No description provided for @accountNicknameSuggestGoogle.
  ///
  /// In en, this message translates to:
  /// **'We suggested your Google name. You can edit it to any public nickname you prefer.'**
  String get accountNicknameSuggestGoogle;

  /// No description provided for @shareChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Share channel'**
  String get shareChannelTitle;

  /// No description provided for @shareChannelAction.
  ///
  /// In en, this message translates to:
  /// **'Share channel'**
  String get shareChannelAction;

  /// No description provided for @shareAsNewVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Share as new version'**
  String get shareAsNewVersionTitle;

  /// No description provided for @shareAsNewVersionAction.
  ///
  /// In en, this message translates to:
  /// **'Share as new version'**
  String get shareAsNewVersionAction;

  /// No description provided for @shareNewVersionHint.
  ///
  /// In en, this message translates to:
  /// **'Existing v{version} stays available, and the current channel will be shared as v{next}.'**
  String shareNewVersionHint(int version, int next);

  /// No description provided for @shareConfirmNewVersionCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I confirm sharing as a new version'**
  String get shareConfirmNewVersionCheckbox;

  /// No description provided for @shareConfirmNewVersionRequired.
  ///
  /// In en, this message translates to:
  /// **'Check the box to confirm sharing a new version.'**
  String get shareConfirmNewVersionRequired;

  /// No description provided for @shareCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get shareCategoryLabel;

  /// No description provided for @shareDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get shareDescriptionLabel;

  /// No description provided for @shareDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short description for this channel'**
  String get shareDescriptionHint;

  /// No description provided for @sharePublicNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Public nickname: {nickname}'**
  String sharePublicNicknameLabel(String nickname);

  /// No description provided for @shareNeedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share a channel.'**
  String get shareNeedSignIn;

  /// No description provided for @shareNeedNickname.
  ///
  /// In en, this message translates to:
  /// **'Set a public nickname before sharing.'**
  String get shareNeedNickname;

  /// No description provided for @shareNoVideos.
  ///
  /// In en, this message translates to:
  /// **'There are no videos to share. Add videos and try again.'**
  String get shareNoVideos;

  /// No description provided for @shareTooManyVideos.
  ///
  /// In en, this message translates to:
  /// **'This channel has too many videos to share.'**
  String get shareTooManyVideos;

  /// No description provided for @shareNonShareableSource.
  ///
  /// In en, this message translates to:
  /// **'This channel includes content that cannot be shared publicly.'**
  String get shareNonShareableSource;

  /// No description provided for @shareInvalidCategory.
  ///
  /// In en, this message translates to:
  /// **'Please choose a category.'**
  String get shareInvalidCategory;

  /// No description provided for @shareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing is unavailable right now. Try again later.'**
  String get shareUnavailable;

  /// No description provided for @sharePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to share this channel.'**
  String get sharePermissionDenied;

  /// No description provided for @sharePublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the channel. Please try again.'**
  String get sharePublishFailed;

  /// No description provided for @sharePublishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Channel shared as v{version}.'**
  String sharePublishSuccess(int version);

  /// No description provided for @mySharedChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'My shared channels'**
  String get mySharedChannelsTitle;

  /// No description provided for @mySharedChannelsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not shared any channels yet.'**
  String get mySharedChannelsEmpty;

  /// No description provided for @shareStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get shareStatusPublished;

  /// No description provided for @shareStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get shareStatusCancelled;

  /// No description provided for @shareCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel share'**
  String get shareCancelAction;

  /// No description provided for @shareCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this version?'**
  String get shareCancelTitle;

  /// No description provided for @shareCancelBody.
  ///
  /// In en, this message translates to:
  /// **'「{title}」 v{version} will be hidden from discovery. Channels others already imported are not affected.'**
  String shareCancelBody(String title, int version);

  /// No description provided for @shareCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel share'**
  String get shareCancelConfirm;

  /// No description provided for @shareCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer shared.'**
  String get shareCancelSuccess;

  /// No description provided for @shareCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel sharing.'**
  String get shareCancelFailed;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get menuMyAccount;

  /// No description provided for @menuPremiumHint.
  ///
  /// In en, this message translates to:
  /// **'Premium plans arrive in a later update.'**
  String get menuPremiumHint;

  /// No description provided for @myChannels.
  ///
  /// In en, this message translates to:
  /// **'My Channels'**
  String get myChannels;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @exploreMyContent.
  ///
  /// In en, this message translates to:
  /// **'Explore My Content'**
  String get exploreMyContent;

  /// No description provided for @createChannelCard.
  ///
  /// In en, this message translates to:
  /// **'Create channel'**
  String get createChannelCard;

  /// No description provided for @kidsBadge.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get kidsBadge;

  /// No description provided for @generalBadge.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalBadge;

  /// No description provided for @videoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} videos'**
  String videoCount(int count);

  /// No description provided for @playChannel.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playChannel;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get categoryEnglish;

  /// No description provided for @categoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryMusic;

  /// No description provided for @categoryScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get categoryScience;

  /// No description provided for @categoryArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get categoryArt;

  /// No description provided for @categoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get categoryAnimals;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errorRetry;

  /// No description provided for @emptyChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'No channels yet'**
  String get emptyChannelsTitle;

  /// No description provided for @emptyChannelsBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first TUPIC channel to start curating YouTube content.'**
  String get emptyChannelsBody;

  /// No description provided for @emptyRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get emptyRecommendedTitle;

  /// No description provided for @emptyRecommendedBody.
  ///
  /// In en, this message translates to:
  /// **'Recommendations appear after channels have popular videos.'**
  String get emptyRecommendedBody;

  /// No description provided for @emptyExploreTitle.
  ///
  /// In en, this message translates to:
  /// **'No videos in this category'**
  String get emptyExploreTitle;

  /// No description provided for @emptyExploreBody.
  ///
  /// In en, this message translates to:
  /// **'Try another category or add more videos to your channels.'**
  String get emptyExploreBody;

  /// No description provided for @mockDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo data — not linked to a live account'**
  String get mockDataBanner;

  /// No description provided for @demoContentBanner.
  ///
  /// In en, this message translates to:
  /// **'Recommended & Explore show demo content — not your saved videos'**
  String get demoContentBanner;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in a later update.'**
  String get comingSoonBody;

  /// No description provided for @comingSoonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get comingSoonOk;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get accountTitle;

  /// No description provided for @accountPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Sign-in will be available when Firebase Authentication is connected.'**
  String get accountPlaceholder;

  /// No description provided for @helloGuest.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get helloGuest;

  /// No description provided for @accountGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountGuestTitle;

  /// No description provided for @accountGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to see your account details. You can keep using local channels without signing in.'**
  String get accountGuestBody;

  /// No description provided for @accountContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get accountContinueWithGoogle;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out. Local channel data is kept on this device.'**
  String get accountSignedOut;

  /// No description provided for @accountSignInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google.'**
  String get accountSignInSuccess;

  /// No description provided for @accountSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get accountSignInFailed;

  /// No description provided for @accountSignInBusy.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is already in progress.'**
  String get accountSignInBusy;

  /// No description provided for @accountSignInNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get accountSignInNetworkError;

  /// No description provided for @accountSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is unavailable here. Use the Android or Chrome (web) Firebase build.'**
  String get accountSignInUnavailable;

  /// No description provided for @accountSignInPopupBlocked.
  ///
  /// In en, this message translates to:
  /// **'The sign-in popup was blocked. Allow popups for this site and try again.'**
  String get accountSignInPopupBlocked;

  /// No description provided for @accountSignInUnauthorizedDomain.
  ///
  /// In en, this message translates to:
  /// **'This web domain is not authorized in Firebase Authentication.'**
  String get accountSignInUnauthorizedDomain;

  /// No description provided for @accountConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the required terms to continue.'**
  String get accountConsentRequired;

  /// No description provided for @accountAnonymousName.
  ///
  /// In en, this message translates to:
  /// **'Google user'**
  String get accountAnonymousName;

  /// No description provided for @accountLocalDataNote.
  ///
  /// In en, this message translates to:
  /// **'Local channels, videos, and resume data are not shown as owned by this Google account and are not uploaded automatically.'**
  String get accountLocalDataNote;

  /// No description provided for @accountGoogleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get accountGoogleSectionTitle;

  /// No description provided for @accountPublicNicknameSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Public nickname'**
  String get accountPublicNicknameSectionTitle;

  /// No description provided for @accountPublicNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on shared channels. Separate from your Google name and email.'**
  String get accountPublicNicknameHint;

  /// No description provided for @accountPublicNicknameEmpty.
  ///
  /// In en, this message translates to:
  /// **'No public nickname yet.'**
  String get accountPublicNicknameEmpty;

  /// No description provided for @accountPublicNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Public nickname'**
  String get accountPublicNicknameLabel;

  /// No description provided for @accountSetNickname.
  ///
  /// In en, this message translates to:
  /// **'Set nickname'**
  String get accountSetNickname;

  /// No description provided for @accountChangeNickname.
  ///
  /// In en, this message translates to:
  /// **'Change nickname'**
  String get accountChangeNickname;

  /// No description provided for @accountNicknameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Public nickname'**
  String get accountNicknameDialogTitle;

  /// No description provided for @accountNicknameSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Public nickname saved.'**
  String get accountNicknameSaveSuccess;

  /// No description provided for @accountNicknameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Public profiles are unavailable. Enable Cloud Firestore in the Firebase Console, then try again.'**
  String get accountNicknameUnavailable;

  /// No description provided for @accountNicknameNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save a public nickname.'**
  String get accountNicknameNotSignedIn;

  /// No description provided for @accountNicknamePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit this profile.'**
  String get accountNicknamePermissionDenied;

  /// No description provided for @accountNicknameSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the nickname. Please try again.'**
  String get accountNicknameSaveFailed;

  /// No description provided for @accountNicknameInvalidEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname.'**
  String get accountNicknameInvalidEmpty;

  /// No description provided for @accountNicknameInvalidLength.
  ///
  /// In en, this message translates to:
  /// **'Nicknames must be 2–20 characters.'**
  String get accountNicknameInvalidLength;

  /// No description provided for @accountNicknameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Invalid characters. Email-style names (@) are not allowed.'**
  String get accountNicknameInvalidChars;

  /// No description provided for @accountNicknameInappropriate.
  ///
  /// In en, this message translates to:
  /// **'This nickname is not allowed.'**
  String get accountNicknameInappropriate;

  /// No description provided for @accountUnder14Policy.
  ///
  /// In en, this message translates to:
  /// **'Independent accounts for users under 14 are not allowed until a lawful parental-consent process is ready. A Google account alone is not age verification, and this build does not provide reliable age verification.'**
  String get accountUnder14Policy;

  /// No description provided for @createChannelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create channel'**
  String get createChannelDialogTitle;

  /// No description provided for @createChannelNameHint.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get createChannelNameHint;

  /// No description provided for @createChannelKidsCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Kids channel'**
  String get createChannelKidsCheckbox;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @channelNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a channel name.'**
  String get channelNameRequired;

  /// No description provided for @selectAudienceTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to explore?'**
  String get selectAudienceTitle;

  /// No description provided for @selectAudienceKids.
  ///
  /// In en, this message translates to:
  /// **'Kids content'**
  String get selectAudienceKids;

  /// No description provided for @selectAudienceGeneral.
  ///
  /// In en, this message translates to:
  /// **'General content'**
  String get selectAudienceGeneral;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumTitle;

  /// No description provided for @premiumDeveloperTestBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium (Developer Test)'**
  String get premiumDeveloperTestBadge;

  /// No description provided for @premiumBody.
  ///
  /// In en, this message translates to:
  /// **'More channels, higher limits, and auto-sync. Billing is not enabled yet.'**
  String get premiumBody;

  /// No description provided for @premiumLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Free plan channel limit'**
  String get premiumLimitTitle;

  /// No description provided for @premiumLimitBody.
  ///
  /// In en, this message translates to:
  /// **'The free plan allows up to {count} channel. Upgrade to Premium for more channels.'**
  String premiumLimitBody(int count);

  /// No description provided for @premiumBillingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Payments are not enabled in this version.'**
  String get premiumBillingDisabled;

  /// No description provided for @channelDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channelDetailTitle;

  /// No description provided for @channelNotFound.
  ///
  /// In en, this message translates to:
  /// **'This channel is no longer available.'**
  String get channelNotFound;

  /// No description provided for @manageThisChannel.
  ///
  /// In en, this message translates to:
  /// **'Manage channel'**
  String get manageThisChannel;

  /// No description provided for @channelSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Channel settings'**
  String get channelSettingsTooltip;

  /// No description provided for @channelVideosComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Adding YouTube videos will be available in the next step.'**
  String get channelVideosComingSoon;

  /// No description provided for @playOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Playback order'**
  String get playOrderLabel;

  /// No description provided for @playOrderTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get playOrderTitleAsc;

  /// No description provided for @playOrderTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Z–A'**
  String get playOrderTitleDesc;

  /// No description provided for @playOrderNewestAdded.
  ///
  /// In en, this message translates to:
  /// **'Newest added'**
  String get playOrderNewestAdded;

  /// No description provided for @playOrderOldestAdded.
  ///
  /// In en, this message translates to:
  /// **'Oldest added'**
  String get playOrderOldestAdded;

  /// No description provided for @playOrderShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playOrderShuffle;

  /// No description provided for @channelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel type'**
  String get channelTypeLabel;

  /// No description provided for @registeredVideosLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered videos'**
  String get registeredVideosLabel;

  /// No description provided for @channelRenamed.
  ///
  /// In en, this message translates to:
  /// **'Channel name updated.'**
  String get channelRenamed;

  /// No description provided for @deleteChannel.
  ///
  /// In en, this message translates to:
  /// **'Delete channel'**
  String get deleteChannel;

  /// No description provided for @deleteChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete channel?'**
  String get deleteChannelTitle;

  /// No description provided for @deleteChannelBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Only this channel’s local data will be removed.'**
  String deleteChannelBody(String name);

  /// No description provided for @parentalGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent check'**
  String get parentalGateTitle;

  /// No description provided for @parentalGateBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your birth year to switch from a kids channel to a general channel during playback.'**
  String get parentalGateBody;

  /// No description provided for @parentalGateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY'**
  String get parentalGateHint;

  /// No description provided for @parentalGateContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get parentalGateContinue;

  /// No description provided for @parentalGateInvalidYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 4-digit birth year.'**
  String get parentalGateInvalidYear;

  /// No description provided for @parentalGateDenied.
  ///
  /// In en, this message translates to:
  /// **'Access is limited to ages 18 and over.'**
  String get parentalGateDenied;

  /// No description provided for @parentalGateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a simple access check, not legal age verification. Birth year is not stored.'**
  String get parentalGateDisclaimer;

  /// No description provided for @importSharedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Importing a shared TUPIC channel will be available in a later update.'**
  String get importSharedPlaceholder;

  /// No description provided for @addContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add content'**
  String get addContentTitle;

  /// No description provided for @manageContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage content'**
  String get manageContentTitle;

  /// No description provided for @addContentUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a YouTube link'**
  String get addContentUrlHint;

  /// No description provided for @openYoutubeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open YouTube'**
  String get openYoutubeTooltip;

  /// No description provided for @openYoutubeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open YouTube.'**
  String get openYoutubeFailed;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @analyzeUrl.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyzeUrl;

  /// No description provided for @confirmContent.
  ///
  /// In en, this message translates to:
  /// **'Check content'**
  String get confirmContent;

  /// No description provided for @addSingleVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addSingleVideo;

  /// No description provided for @addSelectedVideos.
  ///
  /// In en, this message translates to:
  /// **'Add selected videos'**
  String get addSelectedVideos;

  /// No description provided for @checkNewVideos.
  ///
  /// In en, this message translates to:
  /// **'Check for new videos'**
  String get checkNewVideos;

  /// No description provided for @contentNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one video to add.'**
  String get contentNothingSelected;

  /// No description provided for @contentImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added {count} video(s).'**
  String contentImportSuccess(int count);

  /// No description provided for @contentImportPartial.
  ///
  /// In en, this message translates to:
  /// **'Added {imported} video(s). {omitted} were skipped due to the limit.'**
  String contentImportPartial(int imported, int omitted);

  /// No description provided for @contentCreatorResolveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not find this creator channel. Check the link.'**
  String get contentCreatorResolveFailed;

  /// No description provided for @previewSortTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title A–Z'**
  String get previewSortTitleAsc;

  /// No description provided for @previewSortTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Title Z–A'**
  String get previewSortTitleDesc;

  /// No description provided for @previewSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest uploads'**
  String get previewSortNewest;

  /// No description provided for @previewSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest uploads'**
  String get previewSortOldest;

  /// No description provided for @selectAllVideos.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAllVideos;

  /// No description provided for @clearVideoSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearVideoSelection;

  /// No description provided for @loadMoreVideos.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMoreVideos;

  /// No description provided for @noNewCreatorVideos.
  ///
  /// In en, this message translates to:
  /// **'No new videos to add.'**
  String get noNewCreatorVideos;

  /// No description provided for @registerContent.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerContent;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameHint;

  /// No description provided for @contentTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get contentTypeVideo;

  /// No description provided for @contentTypePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get contentTypePlaylist;

  /// No description provided for @contentTypeCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get contentTypeCreator;

  /// No description provided for @contentUrlEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a YouTube URL.'**
  String get contentUrlEmpty;

  /// No description provided for @contentUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'This YouTube link is not supported.'**
  String get contentUrlInvalid;

  /// No description provided for @contentUrlUnsupportedHost.
  ///
  /// In en, this message translates to:
  /// **'Only official YouTube links are allowed.'**
  String get contentUrlUnsupportedHost;

  /// No description provided for @contentUrlRedirectBlocked.
  ///
  /// In en, this message translates to:
  /// **'Redirect links are not followed.'**
  String get contentUrlRedirectBlocked;

  /// No description provided for @contentDuplicateVideo.
  ///
  /// In en, this message translates to:
  /// **'This video is already registered in this channel.'**
  String get contentDuplicateVideo;

  /// No description provided for @contentVideoLimit.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows up to {count} videos per channel.'**
  String contentVideoLimit(int count);

  /// No description provided for @contentAmbiguousTitle.
  ///
  /// In en, this message translates to:
  /// **'This link includes a video and a playlist'**
  String get contentAmbiguousTitle;

  /// No description provided for @contentAmbiguousVideo.
  ///
  /// In en, this message translates to:
  /// **'Add this video only'**
  String get contentAmbiguousVideo;

  /// No description provided for @contentAmbiguousPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add the whole playlist'**
  String get contentAmbiguousPlaylist;

  /// No description provided for @playlistPendingFetch.
  ///
  /// In en, this message translates to:
  /// **'Playlist source saved. Video list fetch waits for YouTube API.'**
  String get playlistPendingFetch;

  /// No description provided for @creatorPendingFetch.
  ///
  /// In en, this message translates to:
  /// **'Creator source saved. Video list fetch waits for YouTube API.'**
  String get creatorPendingFetch;

  /// No description provided for @creatorImportModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Import range'**
  String get creatorImportModeLabel;

  /// No description provided for @creatorImportRecent30.
  ///
  /// In en, this message translates to:
  /// **'Latest 30'**
  String get creatorImportRecent30;

  /// No description provided for @creatorImportAll.
  ///
  /// In en, this message translates to:
  /// **'All videos'**
  String get creatorImportAll;

  /// No description provided for @creatorImportManual.
  ///
  /// In en, this message translates to:
  /// **'Pick manually'**
  String get creatorImportManual;

  /// No description provided for @creatorManualNeedsApi.
  ///
  /// In en, this message translates to:
  /// **'Manual selection will be available after YouTube API is connected.'**
  String get creatorManualNeedsApi;

  /// No description provided for @creatorSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get creatorSortLabel;

  /// No description provided for @creatorSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get creatorSortNewest;

  /// No description provided for @creatorSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get creatorSortOldest;

  /// No description provided for @creatorSortShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get creatorSortShuffle;

  /// No description provided for @autoSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto sync (Premium)'**
  String get autoSyncLabel;

  /// No description provided for @autoSyncFreeLocked.
  ///
  /// In en, this message translates to:
  /// **'Auto sync is Premium-only and is not running yet.'**
  String get autoSyncFreeLocked;

  /// No description provided for @autoSyncPremiumHint.
  ///
  /// In en, this message translates to:
  /// **'Premium can auto-check once per day (not enabled in this build).'**
  String get autoSyncPremiumHint;

  /// No description provided for @contentSourcesSection.
  ///
  /// In en, this message translates to:
  /// **'Content sources'**
  String get contentSourcesSection;

  /// No description provided for @contentVideosSection.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get contentVideosSection;

  /// No description provided for @emptySourcesBody.
  ///
  /// In en, this message translates to:
  /// **'No content sources yet. Add a YouTube link to get started.'**
  String get emptySourcesBody;

  /// No description provided for @emptyVideosBody.
  ///
  /// In en, this message translates to:
  /// **'No confirmed videos yet. Individual video links appear here immediately.'**
  String get emptyVideosBody;

  /// No description provided for @apiNotConnectedBanner.
  ///
  /// In en, this message translates to:
  /// **'Playlist and creator videos are not fetched until YouTube API is connected.'**
  String get apiNotConnectedBanner;

  /// No description provided for @importStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get importStatusReady;

  /// No description provided for @importStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to fetch'**
  String get importStatusPending;

  /// No description provided for @importStatusFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching'**
  String get importStatusFetching;

  /// No description provided for @importStatusFetched.
  ///
  /// In en, this message translates to:
  /// **'Fetched'**
  String get importStatusFetched;

  /// No description provided for @importStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partially fetched'**
  String get importStatusPartial;

  /// No description provided for @importStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get importStatusFailed;

  /// No description provided for @fetchPlaylistVideos.
  ///
  /// In en, this message translates to:
  /// **'Fetch videos'**
  String get fetchPlaylistVideos;

  /// No description provided for @retryFetchPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryFetchPlaylist;

  /// No description provided for @playlistFetchedCount.
  ///
  /// In en, this message translates to:
  /// **'Fetched {count} videos'**
  String playlistFetchedCount(int count);

  /// No description provided for @playlistFetchReport.
  ///
  /// In en, this message translates to:
  /// **'Imported: {imported} · Private/deleted excluded: {privateDeleted} · Not embeddable excluded: {notEmbeddable} · Duplicates: {duplicates}'**
  String playlistFetchReport(
    int imported,
    int privateDeleted,
    int notEmbeddable,
    int duplicates,
  );

  /// No description provided for @playlistFetchReportPruned.
  ///
  /// In en, this message translates to:
  /// **'Cleaned {pruned} previously saved unplayable videos'**
  String playlistFetchReportPruned(int pruned);

  /// No description provided for @contentAgeRestrictedBlocked.
  ///
  /// In en, this message translates to:
  /// **'Age-restricted YouTube videos cannot be added.'**
  String get contentAgeRestrictedBlocked;

  /// No description provided for @contentVideoVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify this video. Please try again later.'**
  String get contentVideoVerificationFailed;

  /// No description provided for @contentProxyConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the video verification server. Please try again later.'**
  String get contentProxyConnectionFailed;

  /// No description provided for @contentProxyQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'The video verification request limit has been reached.'**
  String get contentProxyQuotaExceeded;

  /// No description provided for @contentProxyVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify this video.'**
  String get contentProxyVerifyFailed;

  /// No description provided for @playlistAgeRestrictedExcluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded {count} age-restricted videos.'**
  String playlistAgeRestrictedExcluded(int count);

  /// No description provided for @localServerRequired.
  ///
  /// In en, this message translates to:
  /// **'Local YouTube server required. Run npm start in the server folder.'**
  String get localServerRequired;

  /// No description provided for @localApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'YOUTUBE_API_KEY is not set on the local server. Check server/.env.'**
  String get localApiKeyRequired;

  /// No description provided for @quotaExceededMessage.
  ///
  /// In en, this message translates to:
  /// **'YouTube API quota exceeded. Try again later.'**
  String get quotaExceededMessage;

  /// No description provided for @dailyLocalLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Local daily API request limit reached.'**
  String get dailyLocalLimitMessage;

  /// No description provided for @playlistFetchUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch the playlist. Fully restart the app, confirm the local server (npm start), then try again.'**
  String get playlistFetchUnexpectedError;

  /// No description provided for @lastFetchedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Last fetched: {time}'**
  String lastFetchedAtLabel(String time);

  /// No description provided for @videoLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max}'**
  String videoLimitLabel(int current, int max);

  /// No description provided for @queuePreviewCount.
  ///
  /// In en, this message translates to:
  /// **'Playback queue: {count}'**
  String queuePreviewCount(int count);

  /// No description provided for @deleteSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete content source?'**
  String get deleteSourceTitle;

  /// No description provided for @deleteSourceBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Videos only linked to this source will be removed. Videos linked to other sources stay.'**
  String deleteSourceBody(String name);

  /// No description provided for @deleteSourceResult.
  ///
  /// In en, this message translates to:
  /// **'Removed {removed} video(s). Kept {kept} shared video(s).'**
  String deleteSourceResult(int removed, int kept);

  /// No description provided for @deleteVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete video?'**
  String get deleteVideoTitle;

  /// No description provided for @deleteVideoBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from this channel?'**
  String deleteVideoBody(String title);

  /// No description provided for @excludeVideo.
  ///
  /// In en, this message translates to:
  /// **'Exclude from playback'**
  String get excludeVideo;

  /// No description provided for @restoreVideo.
  ///
  /// In en, this message translates to:
  /// **'Restore to playback'**
  String get restoreVideo;

  /// No description provided for @editVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit title'**
  String get editVideoTitle;

  /// No description provided for @editVideoTitleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit video title'**
  String get editVideoTitleTitle;

  /// No description provided for @editVideoTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Display title'**
  String get editVideoTitleLabel;

  /// No description provided for @restoreOriginalTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore original title'**
  String get restoreOriginalTitle;

  /// No description provided for @originalVideoTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Original: {title}'**
  String originalVideoTitleHint(String title);

  /// No description provided for @videoExcluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded'**
  String get videoExcluded;

  /// No description provided for @reorderHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag to change video order.'**
  String get reorderHint;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerVideoList.
  ///
  /// In en, this message translates to:
  /// **'Video list'**
  String get playerVideoList;

  /// No description provided for @playerSwitchChannel.
  ///
  /// In en, this message translates to:
  /// **'Switch channel'**
  String get playerSwitchChannel;

  /// No description provided for @playerChannelListTitle.
  ///
  /// In en, this message translates to:
  /// **'TUPICK channels'**
  String get playerChannelListTitle;

  /// No description provided for @playerLock.
  ///
  /// In en, this message translates to:
  /// **'Screen lock'**
  String get playerLock;

  /// No description provided for @playerUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get playerUnlock;

  /// No description provided for @playerUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Long press to unlock'**
  String get playerUnlockHint;

  /// No description provided for @playerNextVideo.
  ///
  /// In en, this message translates to:
  /// **'Next video'**
  String get playerNextVideo;

  /// No description provided for @playerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get playerRetry;

  /// No description provided for @playerEmptyQueue.
  ///
  /// In en, this message translates to:
  /// **'No videos to play'**
  String get playerEmptyQueue;

  /// No description provided for @playerVideoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This video cannot be played'**
  String get playerVideoUnavailable;

  /// No description provided for @playerAllVideosUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No playable videos remain in this queue'**
  String get playerAllVideosUnavailable;

  /// No description provided for @playerPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'A playback error occurred'**
  String get playerPlaybackError;

  /// No description provided for @playerLastVideo.
  ///
  /// In en, this message translates to:
  /// **'That was the last video'**
  String get playerLastVideo;

  /// No description provided for @playerReplayQueue.
  ///
  /// In en, this message translates to:
  /// **'Play again from start'**
  String get playerReplayQueue;

  /// No description provided for @playerWebOrientationHint.
  ///
  /// In en, this message translates to:
  /// **'Browsers cannot lock orientation. Use landscape layout to watch.'**
  String get playerWebOrientationHint;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @playerResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get playerResume;

  /// No description provided for @playerLastPosition.
  ///
  /// In en, this message translates to:
  /// **'Last watched position'**
  String get playerLastPosition;

  /// No description provided for @playerPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing playback…'**
  String get playerPreparing;

  /// No description provided for @playlistFetchPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to fetch videos'**
  String get playlistFetchPending;

  /// No description provided for @playlistVideosNotFetchedYet.
  ///
  /// In en, this message translates to:
  /// **'Playlist videos have not been fetched yet. Tap Fetch videos in content management.'**
  String get playlistVideosNotFetchedYet;

  /// No description provided for @playableVideosOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Only confirmed playable videos are listed.'**
  String get playableVideosOnlyHint;

  /// No description provided for @sourceVsPlayableCount.
  ///
  /// In en, this message translates to:
  /// **'{sources} sources · {playable} playable'**
  String sourceVsPlayableCount(int sources, int playable);

  /// No description provided for @settingsLegalSection.
  ///
  /// In en, this message translates to:
  /// **'Terms & privacy'**
  String get settingsLegalSection;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @legalView.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get legalView;

  /// No description provided for @legalVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Document version {version}'**
  String legalVersionLabel(String version);

  /// No description provided for @legalDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'This text is a draft. Unconfirmed business details are marked TODO in the document.'**
  String get legalDraftNotice;

  /// No description provided for @legalKoreanDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'This text is a draft. Unconfirmed business details are marked TODO in the document.'**
  String get legalKoreanDraftNotice;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'TUPICK service notice'**
  String get consentTitle;

  /// No description provided for @consentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept required items to continue. Opening a document alone does not count as consent.'**
  String get consentSubtitle;

  /// No description provided for @consentTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'[Required] Agree to the Terms of Service'**
  String get consentTermsRequired;

  /// No description provided for @consentPrivacyCollectionRequired.
  ///
  /// In en, this message translates to:
  /// **'[Required] Agree to personal information collection & use'**
  String get consentPrivacyCollectionRequired;

  /// No description provided for @privacyPolicyViewAlways.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get privacyPolicyViewAlways;

  /// No description provided for @consentContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get consentContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
