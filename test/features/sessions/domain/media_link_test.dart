import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/sessions/domain/media_link.dart';

void main() {
  test('takes YouTube, YouTube Music and Spotify links only', () {
    for (final (text, service) in [
      ('https://www.youtube.com/watch?v=abc', LinkService.youtube),
      ('youtube.com/watch?v=abc', LinkService.youtube),
      ('https://m.youtube.com/watch?v=abc', LinkService.youtube),
      ('https://youtu.be/abc', LinkService.youtube),
      (
        '  https://music.youtube.com/playlist?list=x  ',
        LinkService.youtubeMusic,
      ),
      ('https://open.spotify.com/playlist/abc?si=1', LinkService.spotify),
      ('spotify.link/xyz', LinkService.spotify),
    ]) {
      final uri = parseMediaLink(text);
      expect(uri?.scheme, 'https', reason: text);
      expect(serviceOf(uri!), service, reason: text);
    }
    for (final text in [
      '',
      'not a link',
      'https://example.com/watch?v=abc',
      'https://youtube.com.evil.example/x',
      'ftp://youtube.com/x',
      'javascript:alert(1)',
    ]) {
      expect(parseMediaLink(text), isNull, reason: text);
    }
  });

  test('http becomes https', () {
    expect(
      parseMediaLink('http://youtu.be/abc').toString(),
      'https://youtu.be/abc',
    );
  });
}
