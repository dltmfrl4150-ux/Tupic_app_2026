'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { isAllowedLocalDevOrigin } = require('../src/cors');
const { app } = require('../src/index');

describe('isAllowedLocalDevOrigin', () => {
  it('allows localhost and 127.0.0.1 with ports', () => {
    assert.equal(isAllowedLocalDevOrigin('http://localhost:50000'), true);
    assert.equal(isAllowedLocalDevOrigin('http://127.0.0.1:53149'), true);
    assert.equal(isAllowedLocalDevOrigin('http://localhost'), true);
    assert.equal(isAllowedLocalDevOrigin('http://127.0.0.1'), true);
  });

  it('rejects external or spoofed origins', () => {
    assert.equal(isAllowedLocalDevOrigin('https://localhost:50000'), false);
    assert.equal(isAllowedLocalDevOrigin('http://evil.com'), false);
    assert.equal(isAllowedLocalDevOrigin('http://localhost.evil.com'), false);
    assert.equal(isAllowedLocalDevOrigin('http://192.168.1.1:8787'), false);
    assert.equal(isAllowedLocalDevOrigin('http://[::1]:8080'), false);
    assert.equal(isAllowedLocalDevOrigin('not-a-url'), false);
    assert.equal(isAllowedLocalDevOrigin(''), false);
  });
});

function listen(server) {
  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => resolve(server.address().port));
  });
}

function request(port, { method, path, headers }) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        host: '127.0.0.1',
        port,
        method,
        path,
        headers,
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: Buffer.concat(chunks).toString('utf8'),
          });
        });
      },
    );
    req.on('error', reject);
    req.end();
  });
}

describe('applyLocalDevCors middleware', () => {
  it('allows localhost Origin on OPTIONS and GET', async () => {
    const server = http.createServer(app);
    const port = await listen(server);
    try {
      const options = await request(port, {
        method: 'OPTIONS',
        path: '/health',
        headers: {
          Origin: 'http://localhost:59547',
          'Access-Control-Request-Method': 'GET',
        },
      });
      assert.equal(options.status, 204);
      assert.equal(
        options.headers['access-control-allow-origin'],
        'http://localhost:59547',
      );
      assert.match(options.headers.vary || '', /Origin/i);
      assert.match(
        options.headers['access-control-allow-methods'] || '',
        /GET/,
      );

      const get = await request(port, {
        method: 'GET',
        path: '/health',
        headers: { Origin: 'http://127.0.0.1:4000' },
      });
      assert.equal(get.status, 200);
      assert.equal(
        get.headers['access-control-allow-origin'],
        'http://127.0.0.1:4000',
      );
      assert.equal(get.headers['access-control-allow-credentials'], undefined);
    } finally {
      server.close();
    }
  });

  it('does not emit Allow-Origin for external Origin', async () => {
    const server = http.createServer(app);
    const port = await listen(server);
    try {
      const options = await request(port, {
        method: 'OPTIONS',
        path: '/api/youtube/videos/validate',
        headers: {
          Origin: 'https://evil.example',
          'Access-Control-Request-Method': 'POST',
        },
      });
      assert.equal(options.status, 403);
      assert.equal(options.headers['access-control-allow-origin'], undefined);

      const get = await request(port, {
        method: 'GET',
        path: '/health',
        headers: { Origin: 'http://example.com' },
      });
      assert.equal(get.status, 200);
      assert.equal(get.headers['access-control-allow-origin'], undefined);
    } finally {
      server.close();
    }
  });
});
