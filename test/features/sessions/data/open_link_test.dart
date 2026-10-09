import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/sessions/data/media_link_repository.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  final uri = Uri.parse('https://www.youtube.com/watch?v=abc');

  test('the app first; the browser only when no app takes the link', () async {
    final tried = <LaunchMode>[];
    Future<bool> Function(Uri, LaunchMode) launcher(Set<LaunchMode> works) =>
        (u, mode) async {
          expect(u, uri);
          tried.add(mode);
          return works.contains(mode);
        };

    expect(
      await openPreferringApp(uri, launcher({.externalNonBrowserApplication})),
      isTrue,
    );
    expect(tried, [LaunchMode.externalNonBrowserApplication]);

    tried.clear();
    expect(
      await openPreferringApp(uri, launcher({.externalApplication})),
      isTrue,
    );
    expect(tried, [
      LaunchMode.externalNonBrowserApplication,
      LaunchMode.externalApplication,
    ]);

    tried.clear();
    expect(await openPreferringApp(uri, launcher({})), isFalse);
    expect(tried, hasLength(2));
  });

  test('an error from the app attempt falls back to the browser', () async {
    final tried = <LaunchMode>[];
    final opened = await openPreferringApp(uri, (_, mode) async {
      tried.add(mode);
      if (mode == LaunchMode.externalNonBrowserApplication) {
        throw StateError('no app');
      }
      return true;
    });
    expect(opened, isTrue);
    expect(tried.last, LaunchMode.externalApplication);
    expect(
      await openPreferringApp(uri, (_, _) async => throw StateError('x')),
      isFalse,
    );
  });
}
