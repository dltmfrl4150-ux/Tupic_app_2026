# STEP 4A — Local YouTube Data API proxy

## What this is

A **loopback-only** Node server under `server/` that calls YouTube Data API v3.
The Flutter app never embeds an API key. Debug builds call:

| Runtime | Base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:8787` |
| Web / desktop | `http://127.0.0.1:8787` |
| Release | disabled |

## Safe key setup

1. `cd server`
2. Prefer `cp .env.example .env` and set `YOUTUBE_API_KEY=...`
3. Or keep a local file like `youtubeapi_YYYYMMDD.env` in `server/` (also gitignored)
4. Never commit `.env` / `youtubeapi_*.env`
5. Do not paste the key into chat, logs, or source files

## Run server

```bash
cd server
npm install
npm start
```

Health check: `http://127.0.0.1:8787/health`

## Fetch existing pending playlists in the app

1. Start the local server with a key configured
2. Open the TUPIC channel → **콘텐츠 관리**
3. On a playlist source, tap **영상 가져오기** / refresh
4. Playable videos appear in the queue and player list

## Playable-only filter (STEP 4A补)

1. `playlistItems.list` collects candidates (skips `Private video` / `Deleted video` titles defensively)
2. `videos.list?part=status,snippet` validates in batches of ≤50
3. Keep only `privacyStatus=public` **and** `embeddable=true`
4. Refresh also `POST /api/youtube/videos/validate` for existing local IDs not confirmed playable
5. Orphan unplayable rows are removed; videos still linked to other sources are kept

## Limits & caching

- Server `MAX_DAILY_YOUTUBE_REQUESTS` (default 40) caps outbound YouTube HTTP calls per process/day
- In-memory playlist cache (`CACHE_TTL_MS`, default 1 hour; cache key includes filter version)
- Free plan still max **100 unique active videos** per TUPIC channel (playable only after prune)
- User must explicitly fetch/refresh — no background polling
- Check Google Cloud Console for real project quota usage

## Not included

- Firebase Blaze / Cloud Functions / Cloud Run
- Creator upload auto-import
- Production cloud proxy
- Perfect detection of region / age / account-only restrictions (player still auto-skips runtime failures)
