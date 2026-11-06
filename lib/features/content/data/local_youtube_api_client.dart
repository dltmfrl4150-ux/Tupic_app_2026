import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/dev_api_config.dart';
import '../../../shared/models/playlist_fetch_models.dart';

typedef HttpGet = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
});

typedef HttpPost = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

/// Talks to the local STEP 4A YouTube proxy (no API key in the Flutter app).
class LocalYoutubeApiClient {
  LocalYoutubeApiClient({
    String? baseUrl,
    HttpGet? httpGet,
    HttpPost? httpPost,
    this.timeout = const Duration(seconds: 25),
  }) : baseUrl = baseUrl ?? DevApiConfig.youtubeProxyBaseUrl,
       _httpGet = httpGet ?? http.get,
       _httpPost = httpPost ?? http.post;

  final String baseUrl;
  final HttpGet _httpGet;
  final HttpPost _httpPost;
  final Duration timeout;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<PlaylistFetchResult> fetchPlaylistVideos({
    required String playlistId,
    required int maxVideos,
    bool forceRefresh = false,
  }) async {
    if (!isConfigured) {
      throw const YoutubeApiException(
        code: 'proxy_disabled',
        message:
            'Local YouTube proxy is disabled in this build. Use a debug build with the local server running.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/api/youtube/playlists/${Uri.encodeComponent(playlistId)}/videos',
    ).replace(
      queryParameters: {
        'maxVideos': '$maxVideos',
        if (forceRefresh) 'refresh': '1',
      },
    );

    final response = await _get(uri);
    final body = _decodeBody(response);

    if (response.statusCode >= 400) {
      throw _exceptionFromBody(body, response.statusCode);
    }

    return PlaylistFetchResult.fromJson(body);
  }

  Future<VideoValidationResult> validateVideos(List<String> youtubeVideoIds) async {
    if (!isConfigured) {
      throw const YoutubeApiException(
        code: 'proxy_disabled',
        message:
            'Local YouTube proxy is disabled in this build. Use a debug build with the local server running.',
      );
    }

    final ids = youtubeVideoIds
        .where((id) => RegExp(r'^[\w-]{11}$').hasMatch(id))
        .toSet()
        .take(100)
        .toList(growable: false);
    if (ids.isEmpty) {
      return const VideoValidationResult(
        playableIds: [],
        unplayableIds: [],
      );
    }

    final uri = Uri.parse('$baseUrl/api/youtube/videos/validate');
    late final http.Response response;
    try {
      response = await _httpPost(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'ids': ids}),
      ).timeout(timeout);
    } on TimeoutException {
      throw const YoutubeApiException(
        code: 'timeout',
        message: 'Local YouTube proxy timed out. Is the server running?',
      );
    } catch (_) {
      throw const YoutubeApiException(
        code: 'connection_failed',
        message:
            'Cannot reach the local YouTube proxy. Start server/ (npm start) and use the emulator address 10.0.2.2.',
      );
    }

    final body = _decodeBody(response);
    if (response.statusCode >= 400) {
      throw _exceptionFromBody(body, response.statusCode);
    }
    return VideoValidationResult.fromJson(body);
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _httpGet(uri).timeout(timeout);
    } on TimeoutException {
      throw const YoutubeApiException(
        code: 'timeout',
        message: 'Local YouTube proxy timed out. Is the server running?',
      );
    } catch (error) {
      if (error is YoutubeApiException) rethrow;
      throw const YoutubeApiException(
        code: 'connection_failed',
        message:
            'Cannot reach the local YouTube proxy. Start server/ (npm start) and use the emulator address 10.0.2.2.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  YoutubeApiException _exceptionFromBody(
    Map<String, dynamic> body,
    int statusCode,
  ) {
    final error = body['error'];
    final code = error is Map && error['code'] is String
        ? error['code'] as String
        : 'http_$statusCode';
    final message = error is Map && error['message'] is String
        ? error['message'] as String
        : 'Local YouTube proxy returned $statusCode';
    return YoutubeApiException(code: code, message: message);
  }
}
