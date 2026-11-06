# TUPIC local YouTube API proxy (STEP 4A)

Loopback-only Node server that calls YouTube Data API v3 with a key kept on the host machine.

## Setup

```bash
cd server
cp .env.example .env
# Edit .env and set YOUTUBE_API_KEY yourself. Never commit .env.
npm install
npm start
```

Listens on `http://127.0.0.1:8787` by default.

## Android emulator

Use `http://10.0.2.2:8787` from the Flutter debug app (already configured in `DevApiConfig`).

## Endpoints

- `GET /health`
- `GET /api/youtube/playlists/:playlistId/videos?maxVideos=50`
- `GET /api/youtube/quota`
- `POST /api/youtube/cache/clear`

## Limits

- `MAX_DAILY_YOUTUBE_REQUESTS` (default 40) caps outbound YouTube HTTP calls for this process/day
- In-memory playlist cache (`CACHE_TTL_MS`, default 1 hour)
- Binds to `127.0.0.1` only — do not expose to the public internet

## Tests (no real API key required)

```bash
npm test
```
