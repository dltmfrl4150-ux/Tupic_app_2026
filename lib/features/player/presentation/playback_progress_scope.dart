import 'package:flutter/material.dart';

import '../../../shared/repositories/playback_progress_repository.dart';

class PlaybackProgressScope extends InheritedWidget {
  const PlaybackProgressScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final PlaybackProgressRepository repository;

  static PlaybackProgressRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlaybackProgressScope>();
    assert(scope != null, 'PlaybackProgressScope not found');
    return scope!.repository;
  }

  static PlaybackProgressRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PlaybackProgressScope>()
        ?.repository;
  }

  @override
  bool updateShouldNotify(PlaybackProgressScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
