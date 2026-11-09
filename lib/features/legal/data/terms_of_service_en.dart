import '../domain/legal_document.dart';

/// English Terms of Service draft (translation of the Korean source).
/// Not a substitute for counsel review. Versions match the Korean document.
class TermsOfServiceEn {
  TermsOfServiceEn._();

  static const version = LegalDocumentVersions.termsOfService;

  static const title = 'TUPICK Terms of Service';

  static const body = '''
Effective date: 2026-11-06
Document version: $version

These Terms govern the use of TUPICK (the "Service") between the service provider (the "Company"; business details to be confirmed before launch) and users.

Article 1 (Purpose and Definitions)
1. These Terms set the basic conditions for using the Service.
2. Key definitions:
  ① "User" means a person who uses the Service under these Terms.
  ② "TUPICK Channel" means a personal channel created in the Service so the User can collect, manage, and play selected YouTube videos. It is not the same as a creator channel on YouTube.
  ③ "Kids Channel" means a TUPICK Channel that the User marked as kids-oriented when creating it.
  ④ "Content" means videos and related information provided by external services such as YouTube.

Article 2 (Service Description)
1. TUPICK is a curation and playback-support service that helps Users select and organize YouTube content and play it through YouTube’s official embed player.
2. The Service may include:
  ① Creating, editing, deleting, and locally managing TUPICK Channels
  ② Registering and organizing videos from YouTube URLs or playlists (where available)
  ③ Playback helpers such as channel playback, resume, and screen lock
  ④ Distinguishing general channels and kids channels
3. Copyright and provision of each YouTube video belong to the relevant rights holder or YouTube, separately from TUPICK.
4. Features not described in these Terms (for example Google sign-in, cloud sync, paid Premium billing, ads, AI classification) may be unavailable or in preparation and may be announced separately when offered.

Article 3 (User Agreement and Use of the Service)
1. The Service may currently be used without sign-in through on-device local storage.
2. If account features such as Google sign-in are introduced later, contract formation, consent procedures, and age-related policies will follow those feature notices and any amended Terms.
3. The Company may reasonably restrict or guide use to keep the Service running smoothly.
4. Independent account registration for users under 14 is designed not to be allowed until a lawful parental-consent verification process is ready. Current guest local use is not treated as account registration.

Article 4 (User Obligations)
Users must:
1. Comply with applicable law, these Terms, and YouTube/Google terms and policies
2. Not use the Service to infringe others’ rights or for unlawful or harmful purposes
3. Not interfere with normal operation of the Service
4. Exercise reasonable care when selecting and managing their TUPICK Channels and Content

Article 5 (YouTube Content and External Services)
1. The Service does not host YouTube content on TUPICK’s own servers. Playback and lookups are supported through YouTube’s official embed player and, in development/debug environments, external integrations such as the YouTube Data API.
2. Titles, public status, embeddability, age restrictions, region restrictions, and similar attributes may change at any time on YouTube’s side, which may make playback or registration unavailable.
3. The Service may restrict registration or playback of private, deleted, or non-embeddable videos and (within future implementation scope) age-restricted YouTube videos under its policies.
4. For outages, policy changes, or playback failures caused by accounts or network conditions of external services, the Company will try to provide reasonable guidance and improvements, but does not fully control whether those external services remain available.

Article 6 (Channel Creation and Content Management)
1. Users may create and manage TUPICK Channels based on YouTube videos they select.
2. Local data such as channel names, video lists, play order, and resume positions is stored primarily on the User’s device.
3. The Company does not guarantee recovery of channels or content deleted by the User (separate notice will be given if backup or cloud sync is introduced).

Article 7 (Kids Channel Feature)
1. A Kids Channel is a management label chosen by the User (for example via a checkbox) when creating a channel.
2. The Kids Channel feature helps Users separate and manage selected videos; it does not guarantee that every video in that channel is suitable for children.
3. Some Kids Channel management screens may include a simple parent check (for example birth-year entry). That is not a legal adult verification or parental-consent verification.
4. Guardians and Users remain responsible for carefully selecting and supervising content for children.

Article 8 (Prohibited Conduct)
Users must not:
1. Violate law or infringe others’ rights
2. Bypass, abuse, or abnormally call the Service or external APIs/players without authorization
3. Place excessive load on the Service through automation or similar means
4. Defame the Company or third parties or interfere with their business
5. Use content in violation of these Terms or YouTube/Google policies

Article 9 (Changes and Suspension of the Service)
1. The Company may change or suspend all or part of the Service for operational or technical reasons.
2. For material changes or suspensions, the Company will try to give reasonable notice in the app or by similar means.
3. For losses arising from changes or suspension of free features, liability may be limited to the extent permitted by law where the Company has no willful misconduct or gross negligence. Rights under mandatory consumer-protection and similar laws are not reduced.

Article 10 (Accounts and Data Management)
1. The default mode of use is currently on-device local storage; account-based cloud storage may not yet be available.
2. Local data may be lost when the device changes, the app is deleted, or storage is reset.
3. If accounts are linked later, data transfer, deletion, and retention will follow the Privacy Policy and separate notices.

Article 11 (Scope of Liability)
1. The Company will make reasonable efforts to provide the Service stably.
2. If the User suffers damage due to the Company’s willful misconduct or gross negligence, the Company is liable under applicable law.
3. The Company does not warrant the legality, completeness, or continued playability of content provided, changed, or removed by third parties such as YouTube.
4. For damage caused by force majeure, user device/network issues, third-party service outages, or other causes beyond the Company’s reasonable control, liability may be limited to the extent permitted by law.
5. This Article is not intended to improperly exempt the Company from liability recognized by law or to exclude Users’ rights under mandatory statutes.

Article 12 (Dispute Resolution and Governing Law)
1. Parties will try in good faith to resolve disputes related to use of the Service.
2. If agreement is not reached, applicable law and competent court procedures apply.
3. These Terms are governed by the laws of the Republic of Korea. (Business location, venue, and related details to be confirmed before launch)

Article 13 (Effective Date and Amendments)
1. These Terms apply from the effective date stated above.
2. The Company may amend these Terms within the limits of applicable law and will announce the effective date and material changes in the app or by similar means.
3. Users who do not agree to amended Terms may stop using the Service.

Contact: To be confirmed before launch (contact TODO)
''';
}
