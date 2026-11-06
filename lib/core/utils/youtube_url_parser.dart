import '../../shared/models/youtube_url_parse_result.dart';

/// URI-based YouTube URL parser. Does not follow redirects.
class YoutubeUrlParser {
  const YoutubeUrlParser();

  static const _allowedHosts = <String>{
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtu.be',
    'www.youtu.be',
  };

  static final _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final _playlistIdPattern = RegExp(r'^[A-Za-z0-9_-]{2,}$');
  static final _channelIdPattern = RegExp(r'^UC[A-Za-z0-9_-]{22}$');

  YoutubeUrlParseResult parse(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const YoutubeUrlParseFailure(YoutubeUrlParseFailureReason.empty);
    }

    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) {
      return const YoutubeUrlParseFailure(
        YoutubeUrlParseFailureReason.invalidUri,
      );
    }

    final host = uri.host.toLowerCase();
    if (!_allowedHosts.contains(host)) {
      return const YoutubeUrlParseFailure(
        YoutubeUrlParseFailureReason.unsupportedHost,
      );
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (segments.isNotEmpty && segments.first.toLowerCase() == 'redirect') {
      return const YoutubeUrlParseFailure(
        YoutubeUrlParseFailureReason.redirectNotFollowed,
      );
    }

    final canonical = uri.replace(fragment: '').toString();

    // youtu.be/VIDEO_ID
    if (host == 'youtu.be' || host == 'www.youtu.be') {
      if (segments.isEmpty) {
        return const YoutubeUrlParseFailure(
          YoutubeUrlParseFailureReason.missingId,
        );
      }
      final videoId = segments.first;
      if (!_videoIdPattern.hasMatch(videoId)) {
        return const YoutubeUrlParseFailure(
          YoutubeUrlParseFailureReason.missingId,
        );
      }
      final list = uri.queryParameters['list'];
      if (list != null && _playlistIdPattern.hasMatch(list)) {
        return YoutubeParsedAmbiguousWatchPlaylist(
          videoId: videoId,
          playlistId: list,
          originalUrl: canonical,
        );
      }
      return YoutubeParsedVideo(videoId: videoId, originalUrl: canonical);
    }

    // /watch?v=
    if (segments.isNotEmpty && segments.first == 'watch') {
      final videoId = uri.queryParameters['v'];
      final list = uri.queryParameters['list'];
      if (videoId != null &&
          _videoIdPattern.hasMatch(videoId) &&
          list != null &&
          _playlistIdPattern.hasMatch(list)) {
        return YoutubeParsedAmbiguousWatchPlaylist(
          videoId: videoId,
          playlistId: list,
          originalUrl: canonical,
        );
      }
      if (videoId != null && _videoIdPattern.hasMatch(videoId)) {
        return YoutubeParsedVideo(videoId: videoId, originalUrl: canonical);
      }
      if (list != null && _playlistIdPattern.hasMatch(list)) {
        return YoutubeParsedPlaylist(
          playlistId: list,
          originalUrl: canonical,
        );
      }
      return const YoutubeUrlParseFailure(
        YoutubeUrlParseFailureReason.missingId,
      );
    }

    // /playlist?list=
    if (segments.isNotEmpty && segments.first == 'playlist') {
      final list = uri.queryParameters['list'];
      if (list == null || !_playlistIdPattern.hasMatch(list)) {
        return const YoutubeUrlParseFailure(
          YoutubeUrlParseFailureReason.missingId,
        );
      }
      return YoutubeParsedPlaylist(playlistId: list, originalUrl: canonical);
    }

    // /shorts/ID /live/ID /embed/ID
    if (segments.length >= 2 &&
        (segments.first == 'shorts' ||
            segments.first == 'live' ||
            segments.first == 'embed')) {
      final videoId = segments[1];
      if (!_videoIdPattern.hasMatch(videoId)) {
        return const YoutubeUrlParseFailure(
          YoutubeUrlParseFailureReason.missingId,
        );
      }
      return YoutubeParsedVideo(videoId: videoId, originalUrl: canonical);
    }

    // /channel/CHANNEL_ID
    if (segments.length >= 2 && segments.first == 'channel') {
      final channelId = segments[1];
      if (!_channelIdPattern.hasMatch(channelId) &&
          !RegExp(r'^UC[A-Za-z0-9_-]+$').hasMatch(channelId)) {
        // Still preserve if it looks like a channel id starting with UC.
        if (!channelId.startsWith('UC')) {
          return const YoutubeUrlParseFailure(
            YoutubeUrlParseFailureReason.missingId,
          );
        }
      }
      return YoutubeParsedCreator(
        originalUrl: canonical,
        channelId: channelId,
      );
    }

    // /@handle
    if (segments.isNotEmpty && segments.first.startsWith('@')) {
      final handle = segments.first.substring(1);
      if (handle.isEmpty) {
        return const YoutubeUrlParseFailure(
          YoutubeUrlParseFailureReason.missingId,
        );
      }
      return YoutubeParsedCreator(originalUrl: canonical, handle: handle);
    }

    // /user/USERNAME
    if (segments.length >= 2 && segments.first == 'user') {
      final username = segments[1];
      if (username.isEmpty) {
        return const YoutubeUrlParseFailure(
          YoutubeUrlParseFailureReason.missingId,
        );
      }
      return YoutubeParsedCreator(originalUrl: canonical, username: username);
    }

    // /c/CUSTOM_NAME
    if (segments.length >= 2 && segments.first == 'c') {
      final custom = segments[1];
      if (custom.isEmpty) {
        return const YoutubeUrlParseFailure(
          YoutubeUrlParseFailureReason.missingId,
        );
      }
      return YoutubeParsedCreator(originalUrl: canonical, customName: custom);
    }

    // Bare path like /CUSTOM (legacy) — unsupported without guessing.
    return const YoutubeUrlParseFailure(
      YoutubeUrlParseFailureReason.unsupportedPath,
    );
  }
}
