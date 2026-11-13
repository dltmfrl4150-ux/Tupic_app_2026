# Implementation Status

Legend: **완료** / **Mock** / **미구현** / **검증 필요**

| Area | Status | Notes |
| --- | --- | --- |
| Flutter project bootstrap | 완료 | `tupic`, android/ios/web |
| Design tokens / dark theme | 완료 | Confirmed palette |
| Space hero illustration | 완료 | STEP 5A-2: 2D `SpacePatternPainter` (cell 320px, seed); no 3D banner |
| Home responsive layout | 완료 | Mobile/tablet/web widths |
| Right hamburger + end drawer | 완료 | Channel list expandable |
| Menu navigation | 완료 | Detail hub / create / import placeholder / settings |
| My channel cards | 완료 | Local user channels |
| Channel create / manage / delete | 완료 | Free 1-channel limit; settings via detail AppBar |
| Parental gate | 완료 | STEP 6A: kids→general playback switch only |
| Locale ko/en | 완료 | ARB + SharedPreferences |
| YouTube URL parser | 완료 | Video / playlist / creator / ambiguous |
| ContentSource + ChannelVideo models | 완료 | Source ≠ playback list |
| Local content persistence | 완료 | `tupic_content_sources_v1`, `tupic_channel_videos_v1` |
| Add content UI | 완료 | Paste / analyze / register |
| Individual video register | 완료 | STEP 5D: proxy validate before save |
| Age-restricted video block | 완료 | STEP 5D-2: kids only; general may register |
| Playlist / creator source register | 완료 | pendingFetch; playlist age filter via proxy |
| Content manage (exclude/reorder/delete) | 완료 | Multi-source safe delete |
| Playback queue builder | 완료 | Pure logic + unit tests |
| Free video limit 100 | 완료 | Unique active IDs |
| YouTube IFrame player | 완료 | `youtube_player_iframe` 6.0.2 |
| Landscape player UI | 완료 | Overlay / queue strip / lock |
| Orientation lock (player only) | 완료 | Portrait app chrome, landscape player |
| Sequential / shuffle playback | 완료 | Via `PlaybackQueueBuilder` + session |
| Home/drawer direct play | 완료 | Card/drawer play vs open separated |
| First-video auto start | 완료 | `fromVideoId` + Ready-queued load |
| Per-channel resume progress | 완료 | `tupic_playback_progress_v1` |
| Auto sync toggle | Mock | Premium-locked, not scheduled |
| Recommended / Explore | Mock | Demo only; not auto-added |
| YouTube Data API (playlist fetch) | 완료(로컬) | Loopback Node proxy + pendingFetch import |
| Creator upload fetch | 미구현 | Still stub / pendingFetch |
| Terms of Service / Privacy Policy | 완료 | STEP 5B: KO drafts + settings links; TODO business fields |
| Consent UI + local records | 완료 | `ConsentPanel` / `ConsentFlow` for STEP 5C; no forced popup |
| Firebase Auth + Google sign-in (Android) | 완료 | STEP 5C-2: `tupic-project`, no Firestore/Functions |
| Firebase Auth + Google sign-in (Web) | 완료 | STEP 6W: `signInWithPopup`; same project |
| Firebase | Auth only | Spark; no cloud channel sync |
| Premium billing | 미구현 | Upsell only |
| Developer Premium test (debug) | 완료 | STEP 5D-3: UID allow-list via dart-define; release off |
| Share import / ads / AI classify | 미구현 | — |

## STEP 3B notes

- Package: `youtube_player_iframe: ^6.0.2` (official IFrame Player API)
- Android: `INTERNET` permission added; portrait default, landscape on player enter
- Web: IFrame playback supported; forced orientation not available — landscape layout + hint
- Titles remain provisional until STEP 4 metadata API
- Playlist/creator sources still contribute no videos until API fetch
