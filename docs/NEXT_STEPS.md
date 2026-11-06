# Next Steps

## STEP 3B completed

- Official YouTube IFrame playback (`youtube_player_iframe`)
- Landscape player with overlay, queue strip, TUPIC lock
- Sequential / shuffle via existing `PlaybackQueueBuilder`
- Orientation restore + empty/error/unavailable handling
- Home/drawer direct play vs channel detail separation
- First-video auto-start via `fromVideoId` (Ready-queued load)
- Per-channel resume (`tupic_playback_progress_v1`)
- Playlist sources remain `pendingFetch` with clearer UI (no invented videos)

## STEP 4A completed (local only)

- Loopback Node YouTube Data API v3 proxy (`server/`)
- Playlist `playlistItems.list` fetch + pagination
- Import into `ChannelVideo` with free 100 limit / dedupe
- Content manage **영상 가져오기** for existing `pendingFetch` playlists
- No Blaze / Functions / key-in-app

## STEP 4A补 completed (playable-only)

- `videos.list` validation (`public` + `embeddable`) in batches of 50
- Placeholder / private / deleted / missing / non-embeddable exclusion counters
- Refresh re-validates existing linked videos and prunes orphans (keeps multi-source)
- Import summary SnackBar + player auto-skip for unplayable runtime errors
- Free 100 limit counts playable videos only after prune

## STEP 4B+ candidates

1. **Creator uploads fetch** (same local proxy pattern, then later Functions)
2. **Production secure proxy** (only when ready — still no keys in the app)
3. **Auto sync job (Premium)**
   - Daily creator checks on server
   - Max 10 auto-sync creator sources

## Keep going forward

- No API keys in the Flutter client
- Keep `ContentRepository` / provider interfaces stable
- All new strings in `lib/l10n/app_*.arb`
