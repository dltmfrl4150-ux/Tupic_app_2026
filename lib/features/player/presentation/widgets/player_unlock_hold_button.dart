import 'dart:async';

import 'package:flutter/material.dart';

/// Hold-to-unlock control that lives outside the YouTube PlatformView.
///
/// Icon-only visually (no on-screen hint text). Uses [Listener] so the 1s hold
/// is not stolen by competing recognizers or the WebView gesture arena.
class PlayerUnlockHoldButton extends StatefulWidget {
  const PlayerUnlockHoldButton({
    super.key,
    required this.semanticLabel,
    required this.semanticHint,
    required this.onUnlock,
    this.holdDuration = const Duration(seconds: 1),
  });

  final String semanticLabel;
  final String semanticHint;
  final Future<void> Function() onUnlock;
  final Duration holdDuration;

  @override
  State<PlayerUnlockHoldButton> createState() => _PlayerUnlockHoldButtonState();
}

class _PlayerUnlockHoldButtonState extends State<PlayerUnlockHoldButton> {
  static const _tickEvery = Duration(milliseconds: 40);

  Timer? _tick;
  int _elapsedMs = 0;
  double _progress = 0;
  bool _unlocking = false;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    if (_unlocking) return;
    _elapsedMs = 0;
    _tick?.cancel();
    _tick = Timer.periodic(_tickEvery, (_) {
      if (!mounted || _unlocking) return;
      _elapsedMs += _tickEvery.inMilliseconds;
      final total = widget.holdDuration.inMilliseconds;
      final ratio = total <= 0 ? 1.0 : (_elapsedMs / total).clamp(0.0, 1.0);
      setState(() => _progress = ratio);
      if (_elapsedMs >= total) {
        unawaited(_completeUnlock());
      }
    });
  }

  void _onPointerEnd(PointerEvent _) {
    if (_unlocking) return;
    _cancelHold();
  }

  void _cancelHold() {
    _tick?.cancel();
    _tick = null;
    _elapsedMs = 0;
    if (_progress != 0 && mounted) {
      setState(() => _progress = 0);
    } else {
      _progress = 0;
    }
  }

  Future<void> _completeUnlock() async {
    if (_unlocking) return;
    _unlocking = true;
    _tick?.cancel();
    _tick = null;
    _elapsedMs = 0;
    if (mounted) setState(() => _progress = 1);
    try {
      await widget.onUnlock();
    } finally {
      _unlocking = false;
      if (mounted) setState(() => _progress = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerEnd,
        onPointerCancel: _onPointerEnd,
        child: SizedBox(
          width: 56,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_progress > 0)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 2.5,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                const Icon(Icons.lock, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
