'use strict';

const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { DailyQuotaGuard } = require('../src/quota');
const {
  fetchPlaylistVideos,
  validatePlayableVideos,
  isPlaceholderTitle,
  clearCache,
} = require('../src/youtube');

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

describe('validatePlayableVideos', () => {
  it('keeps public embeddable only', async () => {
    const fetchImpl = async () =>
      jsonOk({
        items: [
          {
            id: 'abcdefghijk',
            status: { privacyStatus: 'public', embeddable: true },
            snippet: { title: 'Public OK' },
          },
          {
            id: 'private00001',
            status: { privacyStatus: 'private', embeddable: true },
            snippet: { title: 'Hidden' },
          },
          {
            id: 'unlisted0001',
            status: { privacyStatus: 'unlisted', embeddable: true },
            snippet: { title: 'Unlisted' },
          },
          {
            id: 'noembed00001',
            status: { privacyStatus: 'public', embeddable: false },
            snippet: { title: 'No embed' },
          },
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
      ],
      quotaGuard: new DailyQuotaGuard({ maxRequests: 10 }),
      fetchImpl,
    });

    assert.equal(result.playable.length, 1);
    assert.equal(result.playable[0].youtubeVideoId, 'abcdefghijk');
    assert.equal(result.excludedPrivateDeleted, 2); // private + unlisted
    assert.equal(result.excludedNotEmbeddable, 1);
    assert.equal(result.excludedMissing, 1);
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
                id: 'abcdefghijk',
                status: { privacyStatus: 'public', embeddable: true },
                snippet: {
                  title: 'Good Public',
                  thumbnails: { medium: { url: 'https://i.ytimg.com/a.jpg' } },
                },
              },
              {
                id: 'lllllllllll',
                status: { privacyStatus: 'private', embeddable: true },
                snippet: { title: 'Secret' },
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
            items: ids.map((id) => ({
              id,
              status: { privacyStatus: 'public', embeddable: true },
              snippet: { title: id },
            })),
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
