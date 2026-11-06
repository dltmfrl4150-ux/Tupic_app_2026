'use strict';

const CACHE = new Map();
const FILTER_VERSION = 2;

function cacheKey(playlistId, maxVideos) {
  return `${playlistId}::${maxVideos}::v${FILTER_VERSION}`;
}

function getCached(playlistId, maxVideos, ttlMs) {
  const entry = CACHE.get(cacheKey(playlistId, maxVideos));
  if (!entry) return null;
  if (Date.now() - entry.at > ttlMs) {
    CACHE.delete(cacheKey(playlistId, maxVideos));
    return null;
  }
  return { ...entry.payload, fromCache: true };
}

function setCache(playlistId, maxVideos, payload) {
  CACHE.set(cacheKey(playlistId, maxVideos), {
    at: Date.now(),
    payload,
  });
}

function clearCache() {
  CACHE.clear();
}

function pickThumbnail(snippet) {
  const thumbs = snippet?.thumbnails || {};
  return (
    thumbs.medium?.url ||
    thumbs.high?.url ||
    thumbs.default?.url ||
    null
  );
}

function isValidVideoId(id) {
  return typeof id === 'string' && /^[\w-]{11}$/.test(id);
}

function isPlaceholderTitle(title) {
  if (typeof title !== 'string') return false;
  const t = title.trim().toLowerCase();
  return t === 'private video' || t === 'deleted video';
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

async function youtubeGet({ apiKey, path, params, quotaGuard, fetchImpl }) {
  quotaGuard.assertCanRequest();
  const url = new URL(`https://www.googleapis.com/youtube/v3/${path}`);
  for (const [key, value] of Object.entries(params)) {
    if (value != null && value !== '') url.searchParams.set(key, String(value));
  }
  url.searchParams.set('key', apiKey);

  quotaGuard.record();
  const response = await fetchImpl(url.toString());
  const body = await response.json().catch(() => ({}));

  if (!response.ok) {
    const reason =
      body?.error?.errors?.[0]?.reason ||
      body?.error?.status ||
      `http_${response.status}`;
    const message =
      body?.error?.message ||
      `YouTube API request failed (${response.status})`;
    const err = new Error(message);
    err.status = response.status;
    if (reason === 'quotaExceeded' || response.status === 403) {
      err.code = reason === 'quotaExceeded' ? 'quota_exceeded' : 'forbidden';
    } else if (response.status === 404) {
      err.code = 'not_found';
    } else {
      err.code = 'youtube_error';
    }
    err.reason = reason;
    throw err;
  }
  return body;
}

/**
 * Validates candidates with videos.list (batches of 50).
 * Keeps only privacyStatus=public AND embeddable=true.
 */
async function validatePlayableVideos({
  apiKey,
  candidates,
  quotaGuard,
  fetchImpl,
}) {
  const playable = [];
  let excludedPrivateDeleted = 0;
  let excludedNotEmbeddable = 0;
  let excludedMissing = 0;

  const byId = new Map(candidates.map((c) => [c.youtubeVideoId, c]));
  const ids = [...byId.keys()];

  for (const batch of chunk(ids, 50)) {
    const body = await youtubeGet({
      apiKey,
      path: 'videos',
      params: {
        part: 'status,snippet',
        id: batch.join(','),
      },
      quotaGuard,
      fetchImpl,
    });

    const found = new Map();
    for (const item of Array.isArray(body.items) ? body.items : []) {
      if (item?.id) found.set(item.id, item);
    }

    for (const id of batch) {
      const candidate = byId.get(id);
      const item = found.get(id);
      if (!item) {
        excludedMissing += 1;
        continue;
      }
      const status = item.status || {};
      const privacy = status.privacyStatus;
      const embeddable = status.embeddable === true;
      const title =
        typeof item.snippet?.title === 'string' && item.snippet.title
          ? item.snippet.title
          : candidate.title;

      if (isPlaceholderTitle(title) || privacy !== 'public') {
        excludedPrivateDeleted += 1;
        continue;
      }
      if (!embeddable) {
        excludedNotEmbeddable += 1;
        continue;
      }

      playable.push({
        ...candidate,
        title,
        thumbnailUrl:
          pickThumbnail(item.snippet) || candidate.thumbnailUrl || null,
      });
    }
  }

  return {
    playable,
    excludedPrivateDeleted,
    excludedNotEmbeddable,
    excludedMissing,
  };
}

/**
 * Fetches playlist items, validates with videos.list, returns only playable videos.
 * Continues paging until maxVideos playable items or playlist ends.
 */
async function fetchPlaylistVideos({
  apiKey,
  playlistId,
  maxVideos,
  quotaGuard,
  ttlMs,
  forceRefresh = false,
  fetchImpl = fetch,
}) {
  if (!forceRefresh) {
    const cached = getCached(playlistId, maxVideos, ttlMs);
    if (cached) return cached;
  }

  const playable = [];
  const seen = new Set();
  const excludedVideoIds = new Set();
  let skippedInvalid = 0;
  let excludedPrivateDeleted = 0;
  let excludedNotEmbeddable = 0;
  let excludedMissing = 0;
  let pageToken;
  let hasMore = false;
  let truncatedByLimit = false;

  do {
    const body = await youtubeGet({
      apiKey,
      path: 'playlistItems',
      params: {
        part: 'snippet,contentDetails',
        playlistId,
        maxResults: 50,
        pageToken,
      },
      quotaGuard,
      fetchImpl,
    });

    const items = Array.isArray(body.items) ? body.items : [];
    const pageCandidates = [];

    for (const item of items) {
      const videoId =
        item?.contentDetails?.videoId || item?.snippet?.resourceId?.videoId;
      if (!isValidVideoId(videoId)) {
        skippedInvalid += 1;
        continue;
      }
      if (seen.has(videoId)) {
        skippedInvalid += 1;
        continue;
      }
      seen.add(videoId);

      const snippet = item.snippet || {};
      const title =
        typeof snippet.title === 'string' && snippet.title
          ? snippet.title
          : `YouTube video · ${videoId}`;

      // Defensive skip for playlist placeholder rows (still counted).
      if (isPlaceholderTitle(title)) {
        excludedPrivateDeleted += 1;
        excludedVideoIds.add(videoId);
        continue;
      }

      pageCandidates.push({
        youtubeVideoId: videoId,
        title,
        thumbnailUrl: pickThumbnail(snippet),
        position:
          typeof snippet.position === 'number' ? snippet.position : seen.size - 1,
        publishedAt: snippet.publishedAt || null,
        playlistId,
      });
    }

    if (pageCandidates.length > 0) {
      const validated = await validatePlayableVideos({
        apiKey,
        candidates: pageCandidates,
        quotaGuard,
        fetchImpl,
      });
      excludedPrivateDeleted += validated.excludedPrivateDeleted;
      excludedNotEmbeddable += validated.excludedNotEmbeddable;
      excludedMissing += validated.excludedMissing;

      const playableIds = new Set(
        validated.playable.map((v) => v.youtubeVideoId),
      );
      for (const candidate of pageCandidates) {
        if (!playableIds.has(candidate.youtubeVideoId)) {
          excludedVideoIds.add(candidate.youtubeVideoId);
        }
      }

      for (const video of validated.playable) {
        if (playable.length >= maxVideos) {
          truncatedByLimit = true;
          break;
        }
        playable.push(video);
      }
    }

    pageToken = body.nextPageToken || null;
    if (playable.length >= maxVideos) {
      truncatedByLimit = truncatedByLimit || Boolean(pageToken);
      hasMore = Boolean(pageToken);
      break;
    }
    hasMore = Boolean(pageToken);
  } while (pageToken);

  const payload = {
    playlistId,
    videos: playable,
    fetchedCount: playable.length,
    hasMore,
    truncatedByLimit,
    skippedInvalid,
    excludedPrivateDeleted,
    excludedNotEmbeddable,
    excludedMissing,
    excludedVideoIds: [...excludedVideoIds],
    fromCache: false,
  };
  setCache(playlistId, maxVideos, payload);
  return payload;
}

module.exports = {
  fetchPlaylistVideos,
  validatePlayableVideos,
  isPlaceholderTitle,
  isValidVideoId,
  clearCache,
  getCached,
};
