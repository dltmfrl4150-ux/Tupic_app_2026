enum PlaybackPhase {
  initializing,
  loading,
  playing,
  paused,
  ended,
  error,
  unavailable,
  empty,
  queueComplete,
  /// Every queued video failed playback in this session.
  allUnavailable,
}
