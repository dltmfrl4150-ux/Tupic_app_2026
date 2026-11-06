import 'content_enums.dart';

sealed class YoutubeUrlParseResult {
  const YoutubeUrlParseResult();
}

class YoutubeUrlParseFailure extends YoutubeUrlParseResult {
  const YoutubeUrlParseFailure(this.reason);

  final YoutubeUrlParseFailureReason reason;
}

enum YoutubeUrlParseFailureReason {
  empty,
  invalidUri,
  unsupportedHost,
  unsupportedPath,
  missingId,
  redirectNotFollowed,
}

class YoutubeParsedVideo extends YoutubeUrlParseResult {
  const YoutubeParsedVideo({
    required this.videoId,
    required this.originalUrl,
  });

  final String videoId;
  final String originalUrl;
}

class YoutubeParsedPlaylist extends YoutubeUrlParseResult {
  const YoutubeParsedPlaylist({
    required this.playlistId,
    required this.originalUrl,
    this.videoId,
  });

  final String playlistId;
  final String originalUrl;
  final String? videoId;
}

/// Link contains both a video id and a playlist id — user must choose.
class YoutubeParsedAmbiguousWatchPlaylist extends YoutubeUrlParseResult {
  const YoutubeParsedAmbiguousWatchPlaylist({
    required this.videoId,
    required this.playlistId,
    required this.originalUrl,
  });

  final String videoId;
  final String playlistId;
  final String originalUrl;
}

class YoutubeParsedCreator extends YoutubeUrlParseResult {
  const YoutubeParsedCreator({
    required this.originalUrl,
    this.channelId,
    this.handle,
    this.username,
    this.customName,
  });

  final String originalUrl;
  final String? channelId;
  final String? handle;
  final String? username;
  final String? customName;

  ContentSourceType get sourceType => ContentSourceType.creator;
}
