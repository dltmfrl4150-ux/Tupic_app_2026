import '../domain/legal_document.dart';

/// English Privacy Policy draft (translation of the Korean source).
/// Unconfirmed business facts remain TODO / to be confirmed before launch.
class PrivacyPolicyEn {
  PrivacyPolicyEn._();

  static const version = LegalDocumentVersions.privacyPolicy;

  static const title = 'TUPICK Privacy Policy';

  static const body = '''
Effective date: 2026-11-09
Document version: $version

TUPICK (the "Service") complies with the Personal Information Protection Act and other applicable laws of Korea and provides the following notice about processing of users’ personal information.

This Policy is based on processing confirmed in the current app, local storage, Firebase Authentication (Google sign-in), and the development-only local API proxy code. Unconfirmed business, server, and contact details are not treated as final and are marked "to be confirmed before launch" or TODO.

────────────────────────────────
1. Personal Information Controller
────────────────────────────────
- Business name: To be confirmed before launch (TODO)
- Representative: To be confirmed before launch (TODO)
- Address: To be confirmed before launch (TODO)
- Contact email/phone: To be confirmed before launch (TODO)
- Privacy officer or responsible team: To be confirmed before launch (TODO)

────────────────────────────────
2. Information Currently Collected and Processed (as verified in code)
────────────────────────────────

(1) On-device local storage (SharedPreferences, etc.)
To provide app features, the following may be stored on the user’s device:
- Language preference
- User-created TUPICK channel information (name, kids flag, created time, play-order settings, etc.)
- Content source and video metadata (YouTube video IDs, titles, and related registration/import/exclude/order state)
- Per-channel resume (playback progress) information
- Local consent records: consent item id, document version, accepted time
※ The local channel, video, and resume data above are not automatically merged with or uploaded to a Google account.

(2) Google sign-in (Firebase Authentication) — when the user chooses to sign in
The following may be provided and processed during Google account authentication:
- Firebase Auth UID
- Email address
- Display name
- Profile photo URL (if available)
- Authentication provider information (e.g. Google)
Auth sessions and tokens are managed by the Firebase Authentication SDK. The app does not store access tokens or passwords directly in SharedPreferences.
There is currently no feature that stores channel/video lists in a cloud database such as Firestore.

(3) Parent check (kids channel management)
- Birth-year entry is used only to check an on-screen age condition and is not separately stored or transmitted in the current implementation.
- This is not legal identity verification, adult verification, or parental-consent verification.

(4) Home display name
- Signed in: the Google display name may be used in the greeting.
- Signed out: a neutral default greeting is used; arbitrary demo names (e.g. Charlie) are not shown as a real account.

(5) Network communication (YouTube proxy in development/debug)
- Some features such as playlist import may send requests from the device to a local Node.js YouTube proxy (loopback), which may call the YouTube Data API.
- Content identifiers such as playlist IDs and video IDs may be transmitted in that process.
- YouTube Data API keys are designed not to be embedded in the Flutter app and are managed via proxy environment variables.
- Google sign-in is separate from YouTube subscription/channel data access and does not request those permissions.

(6) YouTube embed player
- Playback uses YouTube’s official embed player.
- During playback, Google/YouTube may process device or usage information under their own policies. Google/YouTube terms and privacy policies apply to that processing.
- TUPICK does not store or host YouTube video files on its own servers.

────────────────────────────────
3. Purposes of Processing
────────────────────────────────
- Optional Google sign-in and account status display
- Local channel/content management and playback (including resume)
- Maintaining app settings such as language
- Simple access restriction for kids-channel management screens
- Local retention of Terms-of-Service consent records
- Service improvement and error handling (no separate analytics SDK is confirmed in code)

────────────────────────────────
4. Provision to Third Parties
────────────────────────────────
The Company does not sell or provide users’ local channel/playback data to third parties.
However, the following may constitute provision to or processing by third parties:
- When Google sign-in is used, authentication-related information is transmitted to and processed by Google/Firebase (Google LLC affiliates)
- When the user requests playback or import, content identifiers may be transmitted to YouTube/Google services
- Where disclosure is required by law

────────────────────────────────
5. Entrustment and Cross-Border Transfer
────────────────────────────────
- When Firebase Authentication / Google sign-in is used, authentication data may be processed on Google’s infrastructure.
- According to Google’s publicly available materials, Google services may use global infrastructure; specific transfer countries, storage locations, and entrustment-contract details remain to be confirmed before launch (TODO). (See official Google/Firebase privacy and data-location documentation.)
- Use of YouTube/Google services may be subject to those providers’ processing policies.
- The development-only local YouTube proxy is configured to run primarily on the user’s PC/emulator loopback.
- Additional Firebase data-storage services such as Firestore, Cloud Functions, and Cloud Storage are not currently used.

────────────────────────────────
6. Retention Period
────────────────────────────────
- Local data: kept on the device until the user deletes the app or data, or uses in-app deletion features.
- Local consent records: keep the document version and accepted time from the consent moment; they may be removed when app data is deleted.
- Firebase Authentication account information: processed when the user signs out, when account deletion is offered later, or under Firebase policies. App sign-out does not delete local channel data.
- Detailed membership withdrawal / server retention rules: to be confirmed before launch (TODO)

────────────────────────────────
7. How to Delete Personal Information
────────────────────────────────
- Use in-app channel/content deletion
- Clear app data or uninstall via device/OS settings
- In-app sign-out (ends the Google session; local channel data is kept)
- Full account/auth deletion and data-download request channels: to be confirmed before launch (TODO)

────────────────────────────────
8. User Rights and How to Exercise Them
────────────────────────────────
Users may manage their local data through app and device features (view/delete, etc.).
Official channel for rights related to signed-in accounts: to be confirmed before launch (TODO)

────────────────────────────────
9. Security Measures
────────────────────────────────
- YouTube API keys are not hard-coded in the app
- Care is taken not to print auth tokens in app logs
- Firebase Auth SDK session management is used
- On-device local storage depends on device access controls and OS security; risks increase on rooted/jailbroken or shared devices

────────────────────────────────
10. Children’s Personal Information
────────────────────────────────
Independent accounts for users under 14 are not intended to be allowed until a lawful parental-consent verification process is ready.
However, no reliable age verification or parental-consent verification method is implemented at this stage. Holding a Google account or reading a notice alone is not treated as age verification, and this Policy alone is not claimed to legally guarantee blocked registration.
Simple birth date/year entry is not treated as completed verification.

────────────────────────────────
11. Changes to This Privacy Policy
────────────────────────────────
If this Policy changes, the effective date and material changes will be announced in the app or by similar means.
A changed document version (above) distinguishes it from prior versions.

────────────────────────────────
12. Effect of Notice
────────────────────────────────
This Policy applies from the effective date.

Contact: To be confirmed before launch (TODO)
''';
}
