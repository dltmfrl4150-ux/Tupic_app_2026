# TUPIC Architecture (STEP 1)

## Stack

- Flutter / Dart (`sdk: ^3.13.1`, Flutter 3.47.x)
- Android, iOS, Web targets created
- State: `ChangeNotifier` + `ListenableBuilder` / `InheritedNotifier` (no Provider yet)
- Routing: Navigator 1.0 (`MaterialPageRoute`) — sufficient for home / settings / account
- i18n: `flutter_localizations` + `gen_l10n` ARB files
- Persistence (locale only): `shared_preferences`
- Data: `HomeRepository` abstraction + `MockHomeRepository`

## Package layout

```text
lib/
  main.dart
  app/
    app.dart
    locale_controller.dart
    theme/
  core/
    widgets/
    utils/
  features/
    home/
      data/mock_home_repository.dart
      presentation/
    settings/presentation/
    account/presentation/
    content/
    player/
      domain/
      presentation/
  l10n/
  shared/
    models/
    repositories/
```

Feature folders keep presentation/data separated so Firebase/YouTube implementations can replace mocks without rewriting UI.

## Data flow

1. `main()` initializes bindings, orientation, `LocaleController.load()`.
2. `TupicApp` builds `ChannelsScope` + `MaterialApp` with theme and localization.
3. `ChannelsController` loads user channels from `ChannelRepository` (local JSON).
4. `HomeController` merges **user channels** with **demo** recommended/explore from `HomeRepository`.
5. UI maps `HomeFeedState` (loading / ready / empty / error).
6. Category chips filter `HomeFeed.exploreByCategory` locally (mock demo content).

## Channel persistence

- Interface: `ChannelRepository`
- STEP 2 implementation: `LocalChannelRepository` via SharedPreferences
  - key `tupic_user_channels_v1` (JSON array)
  - key `tupic_last_selected_channel_id`
- Corrupt JSON is treated as empty list (app does not crash)
- Free plan max channels: `PlanLimits.freeMaxChannels` (1)
- Future: Firestore-backed repository behind the same interface

## Content persistence (STEP 3A)

- Interface: `ContentRepository`
- Implementation: `LocalContentRepository`
  - `tupic_content_sources_v1` (+ backup key)
  - `tupic_channel_videos_v1` (+ backup key)
- Corrupt reads do **not** silently wipe storage on the next write
- `YoutubeUrlParser` (URI-based) + stub metadata/playlist/creator providers
- `PlaybackQueueBuilder` builds deduped queues without mutating source order
- Free max videos/channel: `PlanLimits.freeMaxVideosPerChannel` (100 unique active IDs)

## Playback (STEP 3B)

- Package: `youtube_player_iframe` (official YouTube IFrame Player API)
- `PlaybackSession` — pure queue/index/lock/ended-defense state (unit-tested)
- `PlayerSessionController` — owns one `YoutubePlayerController` per viewing session
- `PlayerPage` — landscape UI; restores portrait on exit / dispose / back
- `OrientationHelper` — portrait for app chrome, landscape for player only (`!kIsWeb`)
- Queue strip opens below a shrunk 16:9 player when height allows ≥200×200; otherwise a separate list overlay (session preserved)
- TUPIC screen lock blocks app chrome only; YouTube IFrame controls stay usable
- Kids unlock uses existing parental gate; watching does not require per-video approval

## Future YouTube API surface

| Client interface | Server responsibility |
| --- | --- |
| `YoutubeMetadataProvider` | video title/duration/availability |
| `YoutubePlaylistProvider` | playlist items pagination |
| `YoutubeCreatorProvider` | uploads list + handle→channelId resolve |
| `ContentRepository` | persist resolved ChannelVideo rows |

API keys / OAuth tokens must stay on the server (e.g. Firebase Functions), never in the Flutter app.

## Localization resolution

- `LocaleController.localeOverride == null` → follow device/browser via `localeResolutionCallback`
- Unsupported language codes resolve to `en`
- Settings writes preference to SharedPreferences key `tupic_locale_preference`

## Design tokens

`TupicColors` + `TupicTheme.dark()` centralize palette and Material 3 theming.

## Space hero

`SpaceHeroIllustration` is an isolated `CustomPainter` widget so future illustration assets can replace it without touching home layout.

## Future swap points

| Concern | Current | Later |
| --- | --- | --- |
| Home feed | `MockHomeRepository` | Firestore + Functions |
| Auth | Placeholder account page | Firebase Auth (Google) |
| Playback | `youtube_player_iframe` + local queue | Metadata/playlist fetch via Functions |
| Premium | Copy only | Billing + entitlement service |
| Sync | Not implemented | Server-side scheduler + quota monitoring |
