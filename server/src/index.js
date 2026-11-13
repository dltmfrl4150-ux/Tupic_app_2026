'use strict';

const path = require('path');
const express = require('express');
const dotenv = require('dotenv');
const { DailyQuotaGuard } = require('./quota');
const { applyLocalDevCors } = require('./cors');
const {
  fetchPlaylistVideos,
  validatePlayableVideos,
  resolveChannel,
  isValidVideoId,
  clearCache,
} = require('./youtube');

// Prefer server/.env; also accept a local youtubeapi_*.env drop-in (never commit).
const serverDir = path.join(__dirname, '..');
dotenv.config({ path: path.join(serverDir, '.env') });
if (!process.env.YOUTUBE_API_KEY) {
  const fs = require('fs');
  const match = fs
    .readdirSync(serverDir)
    .find((name) => /^youtubeapi_.*\.env$/i.test(name));
  if (match) {
    dotenv.config({ path: path.join(serverDir, match) });
  }
}

const PORT = Number(process.env.PORT || 8787);
const HOST = process.env.HOST || '127.0.0.1';
const MAX_DAILY = Number(process.env.MAX_DAILY_YOUTUBE_REQUESTS || 40);
const CACHE_TTL_MS = Number(process.env.CACHE_TTL_MS || 3600000);

const app = express();
const quotaGuard = new DailyQuotaGuard({ maxRequests: MAX_DAILY });

app.disable('x-powered-by');
app.use(applyLocalDevCors);
app.use(express.json({ limit: '64kb' }));

function publicError(err) {
  const code = err.code || 'server_error';
  const status = err.status || 500;
  // Never echo secrets / API keys.
  const message = String(err.message || 'Unexpected server error').replace(
    /AIza[0-9A-Za-z_-]{20,}/g,
    '[redacted]',
  );
  return { status, body: { error: { code, message } } };
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    bind: `${HOST}:${PORT}`,
    youtubeKeyConfigured: Boolean(process.env.YOUTUBE_API_KEY),
    quota: quotaGuard.snapshot(),
  });
});

app.get('/api/youtube/quota', (_req, res) => {
  res.json({ quota: quotaGuard.snapshot() });
});

app.post('/api/youtube/cache/clear', (_req, res) => {
  clearCache();
  res.json({ ok: true });
});

/**
 * Re-validates existing local video IDs (batches of 50 via videos.list).
 * Body: { ids: string[] }
 */
app.post('/api/youtube/videos/validate', async (req, res) => {
  const apiKey = process.env.YOUTUBE_API_KEY;
  if (!apiKey || !String(apiKey).trim()) {
    res.status(503).json({
      error: {
        code: 'missing_api_key',
        message:
          'YOUTUBE_API_KEY is not set. Copy server/.env.example to server/.env and set the key locally. Do not commit .env.',
      },
    });
    return;
  }

  const rawIds = Array.isArray(req.body?.ids) ? req.body.ids : [];
  const ids = [
    ...new Set(
      rawIds.filter((id) => typeof id === 'string' && isValidVideoId(id)),
    ),
  ].slice(0, 100);

  try {
    const validated = await validatePlayableVideos({
      apiKey: String(apiKey).trim(),
      candidates: ids.map((id) => ({
        youtubeVideoId: id,
        title: `YouTube video · ${id}`,
        position: 0,
      })),
      quotaGuard,
      fetchImpl: fetch,
    });
    const playableIds = validated.playable.map((v) => v.youtubeVideoId);
    const playableSet = new Set(playableIds);
    const unplayableIds = ids.filter((id) => !playableSet.has(id));
    // Expose titles already fetched via videos.list (no extra quota).
    const mapVideo = (v) => ({
      youtubeVideoId: v.youtubeVideoId,
      title: v.title,
      thumbnailUrl: v.thumbnailUrl || null,
      channelTitle: v.channelTitle || null,
    });
    res.json({
      playableIds,
      playableVideos: validated.playable.map(mapVideo),
      unplayableIds,
      ageRestrictedIds: validated.ageRestrictedIds,
      ageRestrictedVideos: validated.ageRestricted.map(mapVideo),
      verificationFailedIds: validated.verificationFailedIds,
      excludedPrivateDeleted: validated.excludedPrivateDeleted,
      excludedNotEmbeddable: validated.excludedNotEmbeddable,
      excludedMissing: validated.excludedMissing,
      excludedAgeRestricted: validated.excludedAgeRestricted,
      excludedVerificationFailed: validated.excludedVerificationFailed,
    });
  } catch (err) {
    const { status, body } = publicError(err);
    res.status(status).json(body);
  }
});

/**
 * Resolves a creator channel to uploads playlist (channels.list only).
 * Query: channelId | handle | username | customName
 */
app.get('/api/youtube/channels/resolve', async (req, res) => {
  const apiKey = process.env.YOUTUBE_API_KEY;
  if (!apiKey || !String(apiKey).trim()) {
    res.status(503).json({
      error: {
        code: 'missing_api_key',
        message:
          'YOUTUBE_API_KEY is not set. Copy server/.env.example to server/.env and set the key locally. Do not commit .env.',
      },
    });
    return;
  }

  try {
    const resolved = await resolveChannel({
      apiKey: String(apiKey).trim(),
      channelId: req.query.channelId,
      handle: req.query.handle,
      username: req.query.username,
      customName: req.query.customName,
      quotaGuard,
      fetchImpl: fetch,
    });
    res.json(resolved);
  } catch (err) {
    const { status, body } = publicError(err);
    res.status(status).json(body);
  }
});

app.get('/api/youtube/playlists/:playlistId/videos', async (req, res) => {
  const apiKey = process.env.YOUTUBE_API_KEY;
  if (!apiKey || !String(apiKey).trim()) {
    res.status(503).json({
      error: {
        code: 'missing_api_key',
        message:
          'YOUTUBE_API_KEY is not set. Copy server/.env.example to server/.env and set the key locally. Do not commit .env.',
      },
    });
    return;
  }

  const playlistId = req.params.playlistId;
  if (!playlistId || !/^[\w-]+$/.test(playlistId)) {
    res.status(400).json({
      error: { code: 'invalid_playlist_id', message: 'Invalid playlist id.' },
    });
    return;
  }

  const maxVideos = Math.min(
    100,
    Math.max(1, Number(req.query.maxVideos || 50)),
  );
  const forceRefresh = req.query.refresh === '1' || req.query.refresh === 'true';

  try {
    const result = await fetchPlaylistVideos({
      apiKey: String(apiKey).trim(),
      playlistId,
      maxVideos,
      quotaGuard,
      ttlMs: CACHE_TTL_MS,
      forceRefresh,
    });
    res.json(result);
  } catch (err) {
    const { status, body } = publicError(err);
    res.status(status).json(body);
  }
});

app.use((err, _req, res, _next) => {
  const { status, body } = publicError(err);
  res.status(status).json(body);
});

if (require.main === module) {
  app.listen(PORT, HOST, () => {
    // eslint-disable-next-line no-console
    console.log(
      `TUPIC local YouTube proxy listening on http://${HOST}:${PORT} (loopback only)`,
    );
    // eslint-disable-next-line no-console
    console.log(
      `YOUTUBE_API_KEY configured: ${Boolean(process.env.YOUTUBE_API_KEY)}`,
    );
  });
}

module.exports = { app, quotaGuard, applyLocalDevCors };
