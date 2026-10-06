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
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/screen_rest/data/app_limits.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';

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

/// A week of wellbeing logs, like the prototype's Wellbeing board.
Future<void> _seedWellbeing(AppDatabase db) async {
  await _seed(db);
  final id = (await db.select(db.pregnancies).getSingle()).id;
  final repo = WellbeingRepository(db);
  final days = [
    (0, MoodWord.calm, 7 * 60 + 45, 5),
    (1, MoodWord.happy, 8 * 60 + 10, 8),
    (2, MoodWord.tired, 6 * 60 + 20, 6),
    (3, MoodWord.okay, 7 * 60 + 30, 7),
    (5, MoodWord.low, 6 * 60 + 50, 4),
    (6, MoodWord.calm, 7 * 60 + 55, 8),
  ];
  for (final (ago, mood, minutes, glasses) in days) {
    final day = testToday.subtract(Duration(days: ago));
    final woke = DateTime(day.year, day.month, day.day, 6, 25);
    await repo.setMood(pregnancyId: id, day: day, mood: mood);
    await repo.saveSleep(
      pregnancyId: id,
      day: day,
      bedAt: woke.subtract(Duration(minutes: minutes)),
      wokeAt: woke,
    );
    await repo.addWater(pregnancyId: id, day: day, delta: glasses);
  }
  await repo.addSymptom(
    pregnancyId: id,
    kind: .backache,
    severity: .mild,
    note: 'After sitting at my desk all afternoon.',
    at: DateTime(2026, 10, 5, 8, 15),
  );
  for (final (kind, severity) in [
    (SymptomKind.heartburn, Severity.moderate),
    (SymptomKind.legCramps, Severity.mild),
  ]) {
    await repo.addSymptom(
      pregnancyId: id,
      kind: kind,
      severity: severity,
      at: DateTime(2026, 10, 3, 21),
    );
  }
  await repo.addSymptom(
    pregnancyId: id,
    kind: .tiredness,
    severity: .strong,
    at: DateTime(2026, 9, 30, 18),
  );
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
        await _tab(tester, 'Today');
        final rest = find.text('Screen-free from 9:30 pm');
        await tester.scrollUntilVisible(rest, 200);
        await tester.ensureVisible(rest);
        await tester.pumpAndSettle();
        await tester.tap(rest);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/screen_rest_$name.png'),
        );
      });

      testWidgets('app limits $name', skip: _dir == null, (tester) async {
        final usage = FakeAppUsage(access: true)
          ..minutes.addAll({
            'com.google.android.youtube': 18,
            'com.instagram.android': 32,
          });
        await pumpApp(
          tester,
          seed: (db) async {
            await _seed(db);
            final limits = AppLimitsRepository(db);
            await limits.save(
              package: 'com.google.android.youtube',
              label: 'YouTube',
              minutes: 30,
            );
            await limits.save(
              package: 'com.instagram.android',
              label: 'Instagram',
              minutes: 30,
            );
          },
          appUsage: usage,
          library: _library,
          platformBrightness: brightness,
          textScale: scale,
        );
        final rest = find.text('Screen-free from 9:30 pm');
        await tester.scrollUntilVisible(rest, 200);
        await tester.ensureVisible(rest);
        await tester.pumpAndSettle();
        await tester.tap(rest);
        await tester.pumpAndSettle();
        final manage = find.text('Manage limits');
        await tester.scrollUntilVisible(
          manage,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/screen_rest_limits_$name.png'),
        );
        await tester.tap(manage);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/app_limits_$name.png'),
        );
        usage.access = false;
        [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ].forEach(tester.binding.handleAppLifecycleStateChanged);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/app_limits_paused_$name.png'),
        );
      });

      testWidgets('app lock $name', skip: _dir == null, (tester) async {
        await pumpApp(
          tester,
          seed: (db) async {
            await _seed(db);
            await SettingsRepository(db).put(SettingKeys.appLock, 'true');
          },
          library: _library,
          platformBrightness: brightness,
          textScale: scale,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/app_lock_$name.png'),
        );
      });

      testWidgets('me, your data $name', skip: _dir == null, (tester) async {
        await pumpApp(
          tester,
          seed: (db) async {
            await _seed(db);
            await SettingsRepository(db).put(SettingKeys.appLock, 'true');
          },
          authenticator: FakeAuthenticator()..succeed = true,
          library: _library,
          platformBrightness: brightness,
          textScale: scale,
        );
        await _tab(tester, 'Me');
        final section = find.text('Your data');
        await tester.scrollUntilVisible(section, 200);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -60));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/me_your_data_$name.png'),
        );
      });

      testWidgets('meditation $name', skip: _dir == null, (tester) async {
        await pumpApp(
          tester,
          seed: _seed,
          library: _library,
          platformBrightness: brightness,
          textScale: scale,
        );
        await _tab(tester, 'Sessions');
        final tile = find.text('Meditation');
        await tester.scrollUntilVisible(tile, 200);
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/meditation_$name.png'),
        );
      });

      testWidgets('wellbeing $name', skip: _dir == null, (tester) async {
        await pumpApp(
          tester,
          seed: _seedWellbeing,
          library: _library,
          platformBrightness: brightness,
          textScale: scale,
        );
        Future<void> open(Finder f) async {
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          await tester.tap(f);
          await tester.pumpAndSettle();
        }

        Future<void> back() => open(find.byTooltip('Back'));

        await _tab(tester, 'Care');
        await open(find.text('Wellbeing'));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/wellbeing_$name.png'),
        );
        for (final (tile, file) in [
          ('Mood', 'mood'),
          ('Symptoms', 'symptoms'),
          ('Sleep', 'sleep'),
          ('Water', 'water'),
        ]) {
          await tester.scrollUntilVisible(
            find.text(tile).first,
            -200,
            scrollable: find.byType(Scrollable).first,
          );
          await open(find.text(tile).first);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('$_dir/${file}_$name.png'),
          );
          await back();
        }
      });
    }
  }
}
