'use strict';

/**
 * Local-dev CORS for Flutter Web → loopback YouTube proxy.
 * Only http://localhost:<port> and http://127.0.0.1:<port> are allowed.
 */

const ALLOWED_METHODS = 'GET,POST,OPTIONS';
const ALLOWED_HEADERS = 'Content-Type';

function isAllowedLocalDevOrigin(origin) {
  if (typeof origin !== 'string' || !origin) return false;
  let url;
  try {
    url = new URL(origin);
  } catch {
    return false;
  }
  if (url.protocol !== 'http:') return false;
  if (url.hostname !== 'localhost' && url.hostname !== '127.0.0.1') {
    return false;
  }
  // Reject spoofed hosts like "localhost.evil.com" (URL.hostname already
  // normalizes; still require empty pathname/search for Origin form).
  if (url.username || url.password) return false;
  if (url.pathname !== '/' && url.pathname !== '') return false;
  if (url.search || url.hash) return false;

  const port = url.port ? Number(url.port) : 80;
  if (!Number.isInteger(port) || port < 1 || port > 65535) return false;
  return true;
}

function applyLocalDevCors(req, res, next) {
  const origin = req.headers.origin;
  res.setHeader('Vary', 'Origin');

  if (isAllowedLocalDevOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', ALLOWED_METHODS);
    res.setHeader('Access-Control-Allow-Headers', ALLOWED_HEADERS);
  }

  if (req.method === 'OPTIONS') {
    // Preflight: echo allow headers only when Origin was accepted.
    if (isAllowedLocalDevOrigin(origin)) {
      res.status(204).end();
      return;
    }
    res.status(403).end();
    return;
  }

  next();
}

module.exports = {
  isAllowedLocalDevOrigin,
  applyLocalDevCors,
  ALLOWED_METHODS,
  ALLOWED_HEADERS,
};
