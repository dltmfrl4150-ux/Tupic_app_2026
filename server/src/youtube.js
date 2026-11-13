'use strict';

const CACHE = new Map();
/** Bump when playability filter rules change (invalidates playlist cache). */
const FILTER_VERSION = 4;

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
 * Classifies a videos.list item for TUPICK registration.
 * - ageRestricted: contentDetails.contentRating.ytRating === ytAgeRestricted
 * - unavailable: private/deleted/unlisted/non-embeddable/placeholder
 * - verificationFailed: missing from response or required fields incomplete
 * - allowed: public + embeddable; absent ytRating means not age-restricted
 *
 * madeForKids is intentionally ignored (separate concept from age restriction).
 */
function classifyVideoItem(item, fallbackTitle) {
  if (!item || typeof item !== 'object') {
    return { verdict: 'verificationFailed' };
  }

  const status = item.status;
  if (!status || typeof status !== 'object') {
    return { verdict: 'verificationFailed' };
  }
  if (typeof status.privacyStatus !== 'string') {
    return { verdict: 'verificationFailed' };
  }
  if (typeof status.embeddable !== 'boolean') {
    return { verdict: 'verificationFailed' };
  }

  // contentDetails must be present when we request it; missing body is unreliable.
  if (!item.contentDetails || typeof item.contentDetails !== 'object') {
    return { verdict: 'verificationFailed' };
  }

  const title =
    typeof item.snippet?.title === 'string' && item.snippet.title
      ? item.snippet.title
      : fallbackTitle;

  if (isPlaceholderTitle(title) || status.privacyStatus !== 'public') {
    return { verdict: 'unavailable', reason: 'private_or_deleted', title };
  }
  if (status.embeddable !== true) {
    return { verdict: 'unavailable', reason: 'not_embeddable', title };
  }

  const ytRating = item.contentDetails.contentRating?.ytRating;
  const channelTitle =
    typeof item.snippet?.channelTitle === 'string' && item.snippet.channelTitle
      ? item.snippet.channelTitle
      : null;

  if (ytRating === 'ytAgeRestricted') {
    return {
      verdict: 'ageRestricted',
      title,
      thumbnailUrl: pickThumbnail(item.snippet) || null,
      channelTitle,
    };
  }

  return {
    verdict: 'allowed',
    title,
    thumbnailUrl: pickThumbnail(item.snippet) || null,
    channelTitle,
  };
}

/**
 * Resolves a YouTube channel to id + uploads playlist without search.list.
 * Prefers channels.list (id / forHandle / forUsername).
 */
async function resolveChannel({
  apiKey,
  channelId,
  handle,
  username,
  customName,
  quotaGuard,
  fetchImpl = fetch,
}) {
  const params = { part: 'snippet,contentDetails' };
  if (typeof channelId === 'string' && /^UC[\w-]{22}$/.test(channelId)) {
    params.id = channelId;
  } else if (typeof handle === 'string' && handle.trim()) {
    // forHandle accepts with or without leading @
    params.forHandle = handle.trim().replace(/^@/, '');
  } else if (typeof username === 'string' && username.trim()) {
    params.forUsername = username.trim();
  } else if (typeof customName === 'string' && customName.trim()) {
    // Best-effort: many /c/ slugs match a handle; no cheap dedicated API.
    params.forHandle = customName.trim().replace(/^@/, '');
  } else {
    const err = new Error('Channel identifier required.');
    err.status = 400;
    err.code = 'invalid_channel';
    throw err;
  }

  const body = await youtubeGet({
    apiKey,
    path: 'channels',
    params,
    quotaGuard,
    fetchImpl,
  });

  const item = Array.isArray(body.items) ? body.items[0] : null;
  if (!item?.id) {
    const err = new Error('Channel not found or not public.');
    err.status = 404;
    err.code = 'channel_not_found';
    throw err;
  }

  const uploads =
    item.contentDetails?.relatedPlaylists?.uploads || null;
  if (!uploads || typeof uploads !== 'string') {
    const err = new Error('Uploads playlist is unavailable for this channel.');
    err.status = 404;
    err.code = 'uploads_unavailable';
    throw err;
  }

  return {
    channelId: item.id,
    title:
      typeof item.snippet?.title === 'string' && item.snippet.title
        ? item.snippet.title
        : item.id,
    thumbnailUrl: pickThumbnail(item.snippet),
    uploadsPlaylistId: uploads,
    customUrl:
      typeof item.snippet?.customUrl === 'string' ? item.snippet.customUrl : null,
  };
}

/**
 * Validates candidates with videos.list (batches of 50).
 * Keeps only public + embeddable + not age-restricted.
 */
async function validatePlayableVideos({
  apiKey,
  candidates,
  quotaGuard,
  fetchImpl,
}) {
  const playable = [];
  const ageRestricted = [];
  const ageRestrictedIds = [];
  const verificationFailedIds = [];
  let excludedPrivateDeleted = 0;
  let excludedNotEmbeddable = 0;
  let excludedMissing = 0;
  let excludedAgeRestricted = 0;
  let excludedVerificationFailed = 0;

  const byId = new Map(candidates.map((c) => [c.youtubeVideoId, c]));
  const ids = [...byId.keys()];

  for (const batch of chunk(ids, 50)) {
    const body = await youtubeGet({
      apiKey,
      path: 'videos',
      params: {
        part: 'status,snippet,contentDetails',
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
        excludedVerificationFailed += 1;
        verificationFailedIds.push(id);
        continue;
      }

      const result = classifyVideoItem(item, candidate?.title);
      switch (result.verdict) {
        case 'allowed':
          playable.push({
            ...candidate,
            title: result.title,
            thumbnailUrl:
              result.thumbnailUrl || candidate.thumbnailUrl || null,
            channelTitle: result.channelTitle || candidate.channelTitle || null,
          });
          break;
        case 'ageRestricted':
          // Keep classified separately — never rewrite as allowed here.
          // Flutter decides registration by kids vs general channel.
          excludedAgeRestricted += 1;
          ageRestrictedIds.push(id);
          ageRestricted.push({
            ...candidate,
            title: result.title,
            thumbnailUrl:
              result.thumbnailUrl || candidate.thumbnailUrl || null,
            channelTitle: result.channelTitle || candidate.channelTitle || null,
          });
          break;
        case 'unavailable':
          if (result.reason === 'not_embeddable') {
            excludedNotEmbeddable += 1;
          } else {
            excludedPrivateDeleted += 1;
          }
          break;
        case 'verificationFailed':
        default:
          excludedVerificationFailed += 1;
          verificationFailedIds.push(id);
          break;
      }
    }
  }

  return {
    playable,
    ageRestricted,
    excludedPrivateDeleted,
    excludedNotEmbeddable,
    excludedMissing,
    excludedAgeRestricted,
    excludedVerificationFailed,
    ageRestrictedIds,
    verificationFailedIds,
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
  const ageRestrictedVideos = [];
  const seen = new Set();
  const seenAgeRestricted = new Set();
  const excludedVideoIds = new Set();
  let skippedInvalid = 0;
  let excludedPrivateDeleted = 0;
  let excludedNotEmbeddable = 0;
  let excludedMissing = 0;
  let excludedAgeRestricted = 0;
  let excludedVerificationFailed = 0;
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
      excludedAgeRestricted += validated.excludedAgeRestricted;
      excludedVerificationFailed += validated.excludedVerificationFailed;

      const playableIds = new Set(
        validated.playable.map((v) => v.youtubeVideoId),
      );
      for (const candidate of pageCandidates) {
        if (!playableIds.has(candidate.youtubeVideoId)) {
          excludedVideoIds.add(candidate.youtubeVideoId);
        }
      }

      for (const video of validated.ageRestricted || []) {
        if (seenAgeRestricted.has(video.youtubeVideoId)) continue;
        seenAgeRestricted.add(video.youtubeVideoId);
        ageRestrictedVideos.push(video);
      }

      // `videos` remains allowed-only; age-restricted stay in ageRestrictedVideos.
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
    ageRestrictedVideos,
    ageRestrictedIds: [...seenAgeRestricted],
    fetchedCount: playable.length,
    hasMore,
    truncatedByLimit,
    skippedInvalid,
    excludedPrivateDeleted,
    excludedNotEmbeddable,
    excludedMissing,
    excludedAgeRestricted,
    excludedVerificationFailed,
    excludedVideoIds: [...excludedVideoIds],
    fromCache: false,
  };
  setCache(playlistId, maxVideos, payload);
  return payload;
}

module.exports = {
  fetchPlaylistVideos,
  validatePlayableVideos,
  resolveChannel,
  classifyVideoItem,
  isPlaceholderTitle,
  isValidVideoId,
  clearCache,
  getCached,
};
