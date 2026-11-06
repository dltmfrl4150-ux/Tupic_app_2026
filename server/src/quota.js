'use strict';

/**
 * Conservative local daily request limiter (not Google's quota).
 * Counts outbound YouTube Data API HTTP calls from this process.
 */
class DailyQuotaGuard {
  constructor({ maxRequests = 40 } = {}) {
    this.maxRequests = maxRequests;
    this._dayKey = this._todayKey();
    this._count = 0;
  }

  _todayKey() {
    return new Date().toISOString().slice(0, 10);
  }

  _rollIfNeeded() {
    const key = this._todayKey();
    if (key !== this._dayKey) {
      this._dayKey = key;
      this._count = 0;
    }
  }

  get used() {
    this._rollIfNeeded();
    return this._count;
  }

  get remaining() {
    this._rollIfNeeded();
    return Math.max(0, this.maxRequests - this._count);
  }

  assertCanRequest() {
    this._rollIfNeeded();
    if (this._count >= this.maxRequests) {
      const err = new Error(
        'Local daily YouTube request limit reached. Try again tomorrow or raise MAX_DAILY_YOUTUBE_REQUESTS for this machine only.',
      );
      err.code = 'daily_limit';
      err.status = 429;
      throw err;
    }
  }

  record() {
    this._rollIfNeeded();
    this._count += 1;
  }

  snapshot() {
    this._rollIfNeeded();
    return {
      day: this._dayKey,
      used: this._count,
      max: this.maxRequests,
      remaining: this.remaining,
    };
  }
}

module.exports = { DailyQuotaGuard };
