'use strict';

const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { DailyQuotaGuard } = require('../src/quota');
const {
  fetchPlaylistVideos,
  validatePlayableVideos,
  resolveChannel,
  classifyVideoItem,
  isPlaceholderTitle,
  clearCache,
} = require('../src/youtube');

function publicEmbeddable(id, title, { ytRating } = {}) {
  return {
    id,
    status: { privacyStatus: 'public', embeddable: true },
    snippet: { title },
    contentDetails: {
      contentRating: ytRating ? { ytRating } : {},
    },
  };
}

function jsonOk(payload) {
  return {
    ok: true,
    status: 200,
    json: async () => payload,
  };
}

function makeFetchRouter(handlers) {
  return async (url) => {
    const u = new URL(url);
    const path = u.pathname;
    for (const handler of handlers) {
      if (handler.match(u)) return handler.respond(u);
    }
    throw new Error(`Unexpected URL: ${path}`);
  };
}

describe('isPlaceholderTitle', () => {
  it('detects private/deleted placeholders', () => {
    assert.equal(isPlaceholderTitle('Private video'), true);
    assert.equal(isPlaceholderTitle('Deleted video'), true);
    assert.equal(isPlaceholderTitle('Normal Title'), false);
  });
});

describe('classifyVideoItem', () => {
  it('allows public embeddable without ytRating', () => {
    const result = classifyVideoItem(
      publicEmbeddable('abcdefghijk', 'OK'),
      'fallback',
    );
    assert.equal(result.verdict, 'allowed');
  });

  it('flags ytAgeRestricted separately from unavailable', () => {
    const result = classifyVideoItem(
      publicEmbeddable('abcdefghijk', 'Adult', {
        ytRating: 'ytAgeRestricted',
      }),
      'fallback',
    );
    assert.equal(result.verdict, 'ageRestricted');
  });

  it('treats missing contentDetails as verificationFailed', () => {
    const result = classifyVideoItem(
      {
        id: 'abcdefghijk',
        status: { privacyStatus: 'public', embeddable: true },
        snippet: { title: 'Incomplete' },
      },
      'fallback',
    );
    assert.equal(result.verdict, 'verificationFailed');
  });
});

describe('validatePlayableVideos', () => {
  it('keeps public embeddable only and excludes age-restricted', async () => {
    const fetchImpl = async () =>
      jsonOk({
        items: [
          publicEmbeddable('abcdefghijk', 'Public OK'),
          {
            id: 'private00001',
            status: { privacyStatus: 'private', embeddable: true },
            snippet: { title: 'Hidden' },
            contentDetails: { contentRating: {} },
          },
          {
            id: 'unlisted0001',
            status: { privacyStatus: 'unlisted', embeddable: true },
            snippet: { title: 'Unlisted' },
            contentDetails: { contentRating: {} },
          },
          {
            id: 'noembed00001',
            status: { privacyStatus: 'public', embeddable: false },
            snippet: { title: 'No embed' },
            contentDetails: { contentRating: {} },
          },
          publicEmbeddable('agerestrict', 'Restricted', {
            ytRating: 'ytAgeRestricted',
          }),
        ],
      });

    const result = await validatePlayableVideos({
      apiKey: 'test-key',
      candidates: [
        { youtubeVideoId: 'abcdefghijk', title: 'A', position: 0 },
        { youtubeVideoId: 'private00001', title: 'B', position: 1 },
        { youtubeVideoId: 'unlisted0001', title: 'C', position: 2 },
        { youtubeVideoId: 'noembed00001', title: 'D', position: 3 },
        { youtubeVideoId: 'missing00001', title: 'E', position: 4 },
        { youtubeVideoId: 'agerestrict', title: 'F', position: 5 },
      ],
      quotaGuard: new DailyQuotaGuard({ maxRequests: 10 }),
      fetchImpl,
    });

    assert.equal(result.playable.length, 1);
    assert.equal(result.playable[0].youtubeVideoId, 'abcdefghijk');
    assert.equal(result.excludedPrivateDeleted, 2); // private + unlisted
    assert.equal(result.excludedNotEmbeddable, 1);
    assert.equal(result.excludedMissing, 1);
    assert.equal(result.excludedAgeRestricted, 1);
    assert.deepEqual(result.ageRestrictedIds, ['agerestrict']);
    assert.equal(result.ageRestricted.length, 1);
    assert.equal(result.ageRestricted[0].youtubeVideoId, 'agerestrict');
    assert.equal(result.playable.some((v) => v.youtubeVideoId === 'agerestrict'), false);
  });
});

describe('fetchPlaylistVideos', () => {
  beforeEach(() => clearCache());

  it('filters private placeholder and validates via videos.list', async () => {
    const fetchImpl = makeFetchRouter([
      {
        match: (u) => u.pathname.endsWith('/playlistItems'),
        respond: () =>
          jsonOk({
            items: [
              {
                contentDetails: { videoId: 'abcdefghijk' },
                snippet: { title: 'Good', position: 0 },
              },
              {
                contentDetails: { videoId: 'privatevid1' },
                snippet: { title: 'Private video', position: 1 },
              },
              {
                contentDetails: { videoId: 'lllllllllll' },
                snippet: { title: 'Maybe', position: 2 },
              },
            ],
          }),
      },
      {
        match: (u) => u.pathname.endsWith('/videos'),
        respond: () =>
          jsonOk({
            items: [
              {
                ...publicEmbeddable('abcdefghijk', 'Good Public'),
                snippet: {
                  title: 'Good Public',
                  thumbnails: { medium: { url: 'https://i.ytimg.com/a.jpg' } },
                },
              },
              {
                id: 'lllllllllll',
                status: { privacyStatus: 'private', embeddable: true },
                snippet: { title: 'Secret' },
                contentDetails: { contentRating: {} },
              },
            ],
          }),
      },
    ]);

    const result = await fetchPlaylistVideos({
      apiKey: 'test-key',
      playlistId: 'PLtest',
      maxVideos: 10,
      quotaGuard: new DailyQuotaGuard({ maxRequests: 20 }),
      ttlMs: 60_000,
      fetchImpl,
    });

    assert.equal(result.videos.length, 1);
    assert.equal(result.videos[0].title, 'Good Public');
    assert.ok(result.excludedPrivateDeleted >= 2);
    assert.equal(result.excludedNotEmbeddable, 0);
  });

  it('paginates until enough playable videos', async () => {
    let playlistCalls = 0;
    const fetchImpl = makeFetchRouter([
      {
        match: (u) => u.pathname.endsWith('/playlistItems'),
        respond: (u) => {
          playlistCalls += 1;
          if (!u.searchParams.get('pageToken')) {
            return jsonOk({
              nextPageToken: 'p2',
              items: Array.from({ length: 50 }, (_, i) => ({
                contentDetails: {
                  videoId: `id${String(i).padStart(9, '0')}`,
                },
                snippet: { title: `V${i}`, position: i },
              })),
            });
          }
          return jsonOk({
            items: Array.from({ length: 10 }, (_, i) => ({
              contentDetails: {
                videoId: `id${String(i + 50).padStart(9, '0')}`,
              },
              snippet: { title: `V${i + 50}`, position: i + 50 },
            })),
          });
        },
      },
      {
        match: (u) => u.pathname.endsWith('/videos'),
        respond: (u) => {
          const ids = u.searchParams.get('id').split(',');
          return jsonOk({
            items: ids.map((id) => publicEmbeddable(id, id)),
          });
        },
      },
    ]);

    const result = await fetchPlaylistVideos({
      apiKey: 'test-key',
      playlistId: 'PLbig',
      maxVideos: 55,
      quotaGuard: new DailyQuotaGuard({ maxRequests: 20 }),
      ttlMs: 60_000,
      fetchImpl,
    });

    assert.equal(result.videos.length, 55);
    assert.equal(result.truncatedByLimit, true);
    assert.equal(playlistCalls, 2);
  });

  it('maps quotaExceeded from videos.list', async () => {
    const fetchImpl = makeFetchRouter([
      {
        match: (u) => u.pathname.endsWith('/playlistItems'),
        respond: () =>
          jsonOk({
            items: [
              {
                contentDetails: { videoId: 'abcdefghijk' },
                snippet: { title: 'A', position: 0 },
              },
            ],
          }),
      },
      {
        match: (u) => u.pathname.endsWith('/videos'),
        respond: () => ({
          ok: false,
          status: 403,
          json: async () => ({
            error: {
              message: 'quota',
              errors: [{ reason: 'quotaExceeded' }],
            },
          }),
        }),
      },
    ]);

    await assert.rejects(
      () =>
        fetchPlaylistVideos({
          apiKey: 'test-key',
          playlistId: 'PLq',
          maxVideos: 10,
          quotaGuard: new DailyQuotaGuard({ maxRequests: 10 }),
          ttlMs: 60_000,
          fetchImpl,
        }),
      (err) => err.code === 'quota_exceeded',
    );
  });
});

describe('resolveChannel', () => {
  it('resolves uploads playlist via channels.list forHandle', async () => {
    const fetchImpl = makeFetchRouter([
      {
        match: (u) => u.pathname.endsWith('/channels'),
        respond: () =>
          jsonOk({
            items: [
              {
                id: 'UCabcdefghijklmnopqrsuvw',
                snippet: {
                  title: 'Demo Channel',
                  thumbnails: { medium: { url: 'https://img/demo' } },
                  customUrl: '@demo',
                },
                contentDetails: {
                  relatedPlaylists: { uploads: 'UUabcdefghijklmnopqrsuvw' },
                },
              },
            ],
          }),
      },
    ]);

    const resolved = await resolveChannel({
      apiKey: 'test-key',
      handle: 'demo',
      quotaGuard: new DailyQuotaGuard({ maxRequests: 10 }),
      fetchImpl,
    });
    assert.equal(resolved.channelId, 'UCabcdefghijklmnopqrsuvw');
    assert.equal(resolved.uploadsPlaylistId, 'UUabcdefghijklmnopqrsuvw');
    assert.equal(resolved.title, 'Demo Channel');
  });

  it('maps missing channel to channel_not_found', async () => {
    const fetchImpl = makeFetchRouter([
      {
        match: (u) => u.pathname.endsWith('/channels'),
        respond: () => jsonOk({ items: [] }),
      },
    ]);
    await assert.rejects(
      () =>
        resolveChannel({
          apiKey: 'test-key',
          channelId: 'UCabcdefghijklmnopqrsuvw',
          quotaGuard: new DailyQuotaGuard({ maxRequests: 10 }),
          fetchImpl,
        }),
      (err) => err.code === 'channel_not_found',
    );
  });
});
