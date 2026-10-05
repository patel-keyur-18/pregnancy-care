// Golden screenshots of the main screens (ARCHITECTURE §16), light and dark
// at 1.0× and 2.0× text, with Flutter's built-in test font (layout, colour
// and icons, not letter shapes). Text rounds slightly differently on macOS
// and Linux, so each platform has its own exact set: macos/ for local runs,
// linux/ for CI. After an intended visual change:
//   macOS:  flutter test test/goldens --update-goldens
//   Linux:  push to the PR; the failing CI run uploads `linux-goldens`,
//           download it into linux/.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';

import '../helpers.dart';

final Directory _library = Directory.systemTemp.createTempSync('navmaas_gold');

Future<void> _seed(AppDatabase db) async {
  await SettingsRepository(db).put(SettingKeys.firstName, 'Meera');
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  final library = LibraryRepository(db, directory: () async => _library);
  final book = await library.import(
    'evening_stories.txt',
    Stream.value(utf8.encode('Once upon a time.')),
  );
  await library.setProgress(book!.id, position: 420, total: 1000);
  final audio = await library.import('om_chanting.mp3', Stream.value([0]));
  await library.setDuration(audio!.id, 600);
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Golden folder for this platform; other platforms skip the goldens.
final String? _dir = Platform.isMacOS
    ? 'macos'
    : Platform.isLinux
    ? 'linux'
    : null;

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      final name = '${brightness.name}_${scale}x';

      testWidgets('onboarding $name', skip: _dir == null, (tester) async {
        await pumpApp(tester, platformBrightness: brightness, textScale: scale);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await pickDate(tester, '04/15/2026');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/onboarding_$name.png'),
        );
      });

      testWidgets('tabs $name', skip: _dir == null, (tester) async {
        await pumpApp(
          tester,
          seed: _seed,
          library: _library,
          platformBrightness: brightness,
          textScale: scale,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/today_$name.png'),
        );
        for (final tab in ['Journey', 'Sessions', 'Me']) {
          await _tab(tester, tab);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('$_dir/${tab.toLowerCase()}_$name.png'),
          );
        }
      });
    }
  }
}
