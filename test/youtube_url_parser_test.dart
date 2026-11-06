import 'package:flutter_test/flutter_test.dart';
import 'package:tupic/core/utils/youtube_url_parser.dart';
import 'package:tupic/shared/models/youtube_url_parse_result.dart';

void main() {
  const parser = YoutubeUrlParser();

  test('parses common video URL forms', () {
    final cases = <String, String>{
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
      'https://youtu.be/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
      'https://www.youtube.com/shorts/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
      'https://www.youtube.com/live/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
      'https://www.youtube.com/embed/dQw4w9WgXcQ': 'dQw4w9WgXcQ',
      'https://m.youtube.com/watch?v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
      'youtube.com/watch?v=dQw4w9WgXcQ': 'dQw4w9WgXcQ',
    };
    for (final entry in cases.entries) {
      final result = parser.parse(entry.key);
      expect(result, isA<YoutubeParsedVideo>(), reason: entry.key);
      expect((result as YoutubeParsedVideo).videoId, entry.value);
    }
  });

  test('parses playlist and ambiguous watch+list', () {
    final playlist = parser.parse(
      'https://www.youtube.com/playlist?list=PLabcdefghij',
    );
    expect(playlist, isA<YoutubeParsedPlaylist>());
    expect((playlist as YoutubeParsedPlaylist).playlistId, 'PLabcdefghij');

    final ambiguous = parser.parse(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLabcdefghij',
    );
    expect(ambiguous, isA<YoutubeParsedAmbiguousWatchPlaylist>());
  });

  test('parses creator URLs and preserves identifiers', () {
    final handle = parser.parse('https://www.youtube.com/@veritasium');
    expect(handle, isA<YoutubeParsedCreator>());
    expect((handle as YoutubeParsedCreator).handle, 'veritasium');

    final channel = parser.parse(
      'https://www.youtube.com/channel/UCXuqSBlHAE6Xw-yeJA0Tunw',
    );
    expect(channel, isA<YoutubeParsedCreator>());
    expect(
      (channel as YoutubeParsedCreator).channelId,
      'UCXuqSBlHAE6Xw-yeJA0Tunw',
    );

    final user = parser.parse('https://www.youtube.com/user/Apple');
    expect((user as YoutubeParsedCreator).username, 'Apple');

    final custom = parser.parse('https://www.youtube.com/c/GoogleDevelopers');
    expect((custom as YoutubeParsedCreator).customName, 'GoogleDevelopers');
  });

  test('rejects invalid inputs', () {
    expect(
      (parser.parse('') as YoutubeUrlParseFailure).reason,
      YoutubeUrlParseFailureReason.empty,
    );
    expect(
      (parser.parse('https://example.com/watch?v=dQw4w9WgXcQ')
              as YoutubeUrlParseFailure)
          .reason,
      YoutubeUrlParseFailureReason.unsupportedHost,
    );
    expect(
      (parser.parse('https://www.youtube.com/redirect?q=1')
              as YoutubeUrlParseFailure)
          .reason,
      YoutubeUrlParseFailureReason.redirectNotFollowed,
    );
    expect(
      (parser.parse('https://www.youtube.com/feed/trending')
              as YoutubeUrlParseFailure)
          .reason,
      YoutubeUrlParseFailureReason.unsupportedPath,
    );
  });
}
