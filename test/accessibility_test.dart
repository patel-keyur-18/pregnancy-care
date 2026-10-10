import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/birth_prep/data/bag_repository.dart';
import 'package:navmaas/features/birth_prep/data/birth_plan_repository.dart';
import 'package:navmaas/features/birth_prep/presentation/bag_screen.dart';
import 'package:navmaas/features/care/data/vitals_repository.dart';
import 'package:navmaas/features/nutrition/data/avoid_food_repository.dart';
import 'package:navmaas/features/sessions/data/letter_repository.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/media_link_repository.dart';
import 'package:navmaas/features/third_trimester/data/third_trimester_repository.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';

import 'helpers.dart';

/// Small phone, so 2.0× text has the least room.
const _small = Size(360, 640);

/// The iPhone build expires tomorrow: Today's banner and Me's card show.
final _expiry = DateTime(2026, 10, 6, 14);

/// The file picker hands over a backup (for Restore).
Future<PickedFile?> _pickBackup(List<String> _) async =>
    (name: 'navmaas-backup.navmaas', bytes: Stream.value([1]));

/// Library files for the seeded screens (a book and an audio file).
final Directory _library = Directory.systemTemp.createTempSync('navmaas_a11y');

Future<void> _seed(AppDatabase db) async {
  await SettingsRepository(db).put(SettingKeys.firstName, 'Meera');
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  final library = LibraryRepository(db, directory: () async => _library);
  await library.import(
    'evening_stories.txt',
    Stream.value(utf8.encode('# The little lamp\n\nIn a quiet village.')),
  );
  // Two audio files, so Meditation offers the "Your audio" sheet
  // (om chanting, added last, stays first in the library).
  await library.import('rain_sounds.mp3', Stream.value([0]));
  final om = await library.import('om_chanting.mp3', Stream.value([0]));
  // Played once, so Listen shows it rather than the saved link below.
  await library.markOpened(om!.id);
  // A letter with a voice note, so the list chip and player are checked.
  await LetterRepository(db).save(
    (await db.select(db.pregnancies).getSingle()).id,
    'Today you kicked right on the beat.',
    voiceFile: 'note.bin',
    voiceSec: 48,
  );
  // A saved link, so its row and sheet are checked (E2).
  await MediaLinkRepository(db).add(
    title: 'Lullaby playlist',
    url: Uri.parse('https://open.spotify.com/playlist/abc'),
  );
  // Routines unlocked, so the exercise screen is reachable.
  final pregnancy = await db.select(db.pregnancies).getSingle();
  await PregnancyRepository(db).setFlags(pregnancy.id, exerciseCleared: true);
  // Logs, so the kick counter and contraction timer show their lists.
  final third = ThirdTrimesterRepository(db);
  for (var day = 1; day <= 4; day++) {
    final start = DateTime(2026, 10, day, 20, 15);
    await third.saveKicks(
      pregnancyId: pregnancy.id,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 18)),
      count: 10,
    );
  }
  // A few wellbeing logs, so the week and "Logged today" show.
  final wellbeing = WellbeingRepository(db);
  for (var ago = 0; ago < 3; ago++) {
    final day = testToday.subtract(Duration(days: ago));
    await wellbeing.setMood(pregnancyId: pregnancy.id, day: day, mood: .tired);
    await wellbeing.saveSleep(
      pregnancyId: pregnancy.id,
      day: day,
      bedAt: DateTime(day.year, day.month, day.day - 1, 22, 40),
      wokeAt: DateTime(day.year, day.month, day.day, 6, 25),
      napMinutes: 30,
    );
    await wellbeing.addWater(pregnancyId: pregnancy.id, day: day, delta: 5);
    for (final kind in [SymptomKind.troubleSleeping, SymptomKind.swollenFeet]) {
      await wellbeing.addSymptom(
        pregnancyId: pregnancy.id,
        kind: kind,
        severity: .moderate,
        note: 'After a long day on my feet.',
        at: DateTime(day.year, day.month, day.day, 8),
      );
    }
  }
  // Birth prep (M8a): a reading, a food, a packed item, her own item and
  // an answer, so each list shows rows.
  await VitalsRepository(db).add(
    pregnancyId: pregnancy.id,
    kind: VitalKind.bloodSugar,
    value1: 96,
    context: BloodSugarContext.fasting,
    note: 'Before breakfast',
    at: DateTime(2026, 10, 5, 7, 40),
  );
  await AvoidFoodRepository(
    db,
  ).save(pregnancyId: pregnancy.id, name: 'Papaya', reason: "Doctor's advice");
  final bag = BagRepository(db);
  await bag.addOwn(
    pregnancyId: pregnancy.id,
    label: 'Phone charger for the car',
    section: BagSection.forMe,
  );
  await bag.setPacked(
    pregnancyId: pregnancy.id,
    row: (
      id: null,
      templateKey: 'bag-me-nightwear',
      label: '',
      section: BagSection.forMe,
      packed: false,
    ),
    packed: true,
  );
  await BirthPlanRepository(db).save(
    pregnancyId: pregnancy.id,
    promptKey: 'plan-calm',
    answer: 'Soft music and a hand to hold.',
  );
  for (final minute in [10, 18, 27]) {
    final start = DateTime(2026, 10, 5, 8, minute);
    await third.saveContraction(
      pregnancyId: pregnancy.id,
      startedAt: start,
      endedAt: start.add(const Duration(seconds: 48)),
    );
  }
}

/// Lets real file reads finish (they run outside fake time).
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Types into the [index]th text field, scrolling it into view first
/// (lists build lazily: scroll to [below], a unique text under the fields).
Future<void> _type(
  WidgetTester tester,
  int index,
  String text, {
  String below = 'Include books & audio',
}) async {
  await tester.scrollUntilVisible(
    find.text(below),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  final field = find.byType(TextField).at(index);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pump();
}

/// Opens [path] the way a tile would (Getting ready shows from week 32; the
/// seeded pregnancy is at week 24).
Future<void> _go(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(NavmaasTabBar))).go(path);
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Scrolls [text] into view (screens are long at 2.0×), then taps it.
/// [last]: the text appears more than once; take the last.
/// Long-presses [text] (a library row, below any path tile showing the
/// same title): scrolls past the library first, so every row is built.
Future<void> _longPressText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text('Move & breathe'),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  final finder = last ? find.text(text).last : find.text(text);
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The Android app-usage stand-in for the screen under test.
late FakeAppUsage _usage;

/// What Nourishly shares in each test: nothing until an entry says so.
late FakeNourishly _nourishly;

/// Navmaas comes back to the foreground (from Settings).
Future<void> _comeBack(WidgetTester t) async {
  [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ].forEach(t.binding.handleAppLifecycleStateChanged);
  await t.pumpAndSettle();
}

/// Screen Rest → Set up limits, with Usage access, YouTube at 30 minutes;
/// or stopped at the app list ([choose]) or the minutes sheet ([minutes]).
Future<void> _appLimits(
  WidgetTester t, {
  bool choose = false,
  bool minutes = false,
}) async {
  _usage.access = true;
  await _tapText(t, 'Screen-free from 9:30 pm');
  await _tapText(t, 'Set up limits');
  await _tapText(t, 'Add an app');
  if (choose) return;
  await t.tap(find.text('YouTube'));
  await t.pumpAndSettle();
  if (minutes) return;
  await t.tap(find.text('Save'));
  await t.pumpAndSettle();
}

/// Me → Your data → App lock on.
Future<void> _appLockOn(WidgetTester t) async {
  await _tab(t, 'Me');
  await t.scrollUntilVisible(
    find.text('App lock'),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  final row = find.ancestor(
    of: find.text('App lock'),
    matching: find.byType(Row),
  );
  final toggle = find.descendant(of: row.first, matching: find.byType(Switch));
  await t.ensureVisible(toggle);
  await t.pumpAndSettle();
  await t.tap(toggle);
  await t.pumpAndSettle();
}

/// Each screen the app has, reached the way a user would.
final _screens = <String, (bool, Future<void> Function(WidgetTester))>{
  'onboarding 1': (false, (_) async {}),
  'onboarding 2': (
    false,
    (t) async {
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await pickDate(t, '04/15/2026');
    },
  ),
  'onboarding 3': (
    false,
    (t) async {
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await pickDate(t, '04/15/2026');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
    },
  ),
  'onboarding 4': (
    false,
    (t) async {
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await pickDate(t, '04/15/2026');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await t.tap(find.text('Skip'));
      await t.pumpAndSettle();
    },
  ),
  'today': (true, (_) async {}),
  'journey': (true, (t) => _tab(t, 'Journey')),
  'sessions': (true, (t) => _tab(t, 'Sessions')),
  'care': (true, (t) => _tab(t, 'Care')),
  'me': (true, (t) => _tab(t, 'Me')),
  'me, app lock on': (true, _appLockOn),
  'app lock': (
    true,
    (t) async {
      await _appLockOn(t);
      // Away for two minutes; the fake never unlocks.
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ].forEach(t.binding.handleAppLifecycleStateChanged);
      await t.pump(const Duration(minutes: 2));
      [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(t.binding.handleAppLifecycleStateChanged);
      await t.pumpAndSettle();
      expect(find.text('Navmaas is locked'), findsOneWidget);
    },
  ),
  'supplements': (
    true,
    (t) async {
      await _tab(t, 'Care');
      // Below the kick counter tiles at 2.0×.
      await t.scrollUntilVisible(find.text('Supplements today'), 200);
      final seeAll = find.text('See all').first;
      await t.ensureVisible(seeAll);
      await t.pumpAndSettle();
      await t.tap(seeAll);
      await t.pumpAndSettle();
    },
  ),
  'add supplement': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Add');
    },
  ),
  'tests and vaccines': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await t.scrollUntilVisible(
        find.text('Coming up'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('See all').last);
      await t.pumpAndSettle();
    },
  ),
  'add visit': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Add a visit');
    },
  ),
  'visit': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Add a visit');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
    },
  ),
  'reader': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'evening stories');
      await _settleIo(t);
    },
  ),
  'reader with an eye rest': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'evening stories');
      await _settleIo(t);
      await t.pump(const Duration(minutes: 20));
    },
  ),
  'delete all data': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, 'Delete all data');
    },
  ),
  'screen rest': (
    true,
    (t) async {
      await _tapText(t, 'Screen-free from 9:30 pm');
    },
  ),
  // Android: limits for other apps (M11a).
  'app limits, usage access': (
    true,
    (t) async {
      await _tapText(t, 'Screen-free from 9:30 pm');
      await _tapText(t, 'Set up limits');
    },
  ),
  'app limits, choose an app': (true, (t) => _appLimits(t, choose: true)),
  'app limits, daily limit': (true, (t) => _appLimits(t, minutes: true)),
  'app limits': (true, _appLimits),
  'app limits, paused': (
    true,
    (t) async {
      await _appLimits(t);
      _usage.access = false;
      await _comeBack(t);
    },
  ),
  'listen': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'om chanting', last: true); // library row
      await _settleIo(t);
    },
  ),
  'listen, screen off': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'om chanting', last: true); // library row
      await _settleIo(t);
      await _tapText(t, 'Screen off — keep listening');
    },
  ),
  'walk': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Walk');
    },
  ),
  'exercise': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Gentle flow');
    },
  ),
  'slow breathing': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Slow breathing');
    },
  ),
  'letters': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Talk to baby');
    },
  ),
  'write a letter': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Talk to baby');
      await t.tap(find.text('Write'));
      await t.pumpAndSettle();
    },
  ),
  'letters with a voice note': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Talk to baby');
    },
  ),
  'letter, voice note': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Talk to baby');
      await _tapText(t, 'Today you kicked right on the beat.');
    },
  ),
  'letter, recording': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Talk to baby');
      await t.tap(find.text('Speak'));
      await t.pumpAndSettle();
      await t.tap(find.text('Record'));
      await _settleIo(t);
    },
  ),
  'add to library': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Add');
    },
  ),
  'add a link': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Add');
      await t.tap(find.text('A link'));
      await t.pumpAndSettle();
    },
  ),
  'audio, rename / replace / remove': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _longPressText(t, 'om chanting');
    },
  ),
  'link, edit / remove': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _longPressText(t, 'Lullaby playlist');
    },
  ),
  'activity': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Activity');
    },
  ),
  'doctor': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, "Add your doctor's details");
    },
  ),
  'edit dates': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
    },
  ),
  'kick counter': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Kick counter');
      await t.tap(find.bySemanticsLabel(RegExp('^Log a movement')));
      await t.pump();
    },
  ),
  'wellbeing': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Wellbeing');
    },
  ),
  'mood check-in': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Wellbeing');
      await _tapText(t, 'Mood');
    },
  ),
  'symptom log, all chips and her own': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Wellbeing');
      await _tapText(t, 'Symptoms');
      await t.tap(find.textContaining('More · '));
      await t.pumpAndSettle();
      await _tapText(t, 'Add your own');
    },
  ),
  'sleep entry': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Wellbeing');
      await _tapText(t, 'Sleep');
      await _tapText(t, 'A bit tired');
    },
  ),
  'water, reminders on': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Wellbeing');
      await _tapText(t, 'Water');
      final toggle = find.byType(Switch);
      await t.scrollUntilVisible(
        toggle,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await t.ensureVisible(toggle);
      await t.pumpAndSettle();
      await t.tap(toggle);
      await t.pumpAndSettle();
    },
  ),
  'meditation': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Meditation');
    },
  ),
  'meditation, your audio': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Meditation');
      await _tapText(t, 'Or use your own audio');
    },
  ),
  'meditation, running': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Meditation');
      await _tapText(t, 'Start');
    },
  ),
  'meditation, screen off': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Meditation');
      await _tapText(t, 'Start');
      await _tapText(t, 'Screen off — keep meditating');
    },
  ),
  'contraction timer': (
    true,
    (t) async {
      // The seeded pregnancy is at week 24; the tile shows from week 28.
      unawaited(
        GoRouter.of(t.element(find.byType(NavmaasTabBar)))
            .push('/contractions'),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Contraction started'));
      await t.pump(const Duration(seconds: 3));
    },
  ),
  // Care from week 32: the contraction timer and Getting ready tiles (the
  // seeded pregnancy is re-dated from week 24).
  'care, week 33': (
    true,
    (t) async {
      final db = ProviderScope.containerOf(
        t.element(find.byType(NavmaasTabBar)),
      ).read(appDatabaseProvider);
      await t.runAsync(
        () =>
            PregnancyRepository(db)
                .saveDating(method: .lmp, date: DateTime.utc(2026, 2, 16)),
      );
      await _tab(t, 'Care');
      // Below the fold at 2.0×: bring the Getting ready tiles into view.
      await t.scrollUntilVisible(
        find.text('Hospital bag'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await t.pumpAndSettle();
    },
  ),
  // Today from week 32: the Hospital bag card under the week card.
  'today, week 33': (
    true,
    (t) async {
      final db = ProviderScope.containerOf(
        t.element(find.byType(NavmaasTabBar)),
      ).read(appDatabaseProvider);
      await t.runAsync(
        () =>
            PregnancyRepository(db)
                .saveDating(method: .lmp, date: DateTime.utc(2026, 2, 16)),
      );
      await t.pumpAndSettle();
      // Under the week card: below the fold on the small screen.
      await t.scrollUntilVisible(
        find.text('Hospital bag'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
    },
  ),
  'blood sugar': (true, (t) => _go(t, '/care/blood-sugar')),
  'log blood sugar': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Log blood sugar');
    },
  ),
  'nutrition': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Nutrition');
    },
  ),
  'nutrition, from Nourishly': (
    true,
    (t) async {
      _nourishly.text = nourishlyJson();
      await _go(t, '/care/nutrition');
    },
  ),
  'nutrition, another Nourishly day': (
    true,
    (t) async {
      _nourishly.text = nourishlyJson();
      await _go(t, '/care/nutrition');
      await t.tap(find.byKey(const ValueKey('nourishly-day-2026-10-04')));
      await t.pumpAndSettle();
    },
  ),
  'nutrition, Nourishly unreadable': (
    true,
    (t) async {
      _nourishly.text = nourishlyJson(version: 2);
      await _go(t, '/care/nutrition');
    },
  ),
  'edit food': (
    true,
    (t) async {
      await _go(t, '/care/nutrition');
      await _tapText(t, 'Papaya');
    },
  ),
  'hospital bag': (true, (t) => _go(t, '/care/bag')),
  'hospital bag, add your own': (
    true,
    (t) async {
      await _go(t, '/care/bag');
      // The bag is long at 2.0×: scroll its own list to the end.
      final add = find.text('Add your own');
      await t.scrollUntilVisible(
        add,
        400,
        scrollable: find
            .descendant(
              of: find.byType(BagScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.ensureVisible(add);
      await t.pumpAndSettle();
      await t.tap(add);
      await t.pumpAndSettle();
    },
  ),
  'birth plan': (true, (t) => _go(t, '/care/birth-plan')),
  'birth plan, answer': (
    true,
    (t) async {
      await _go(t, '/care/birth-plan');
      await _tapText(t, 'What helps you feel calm');
    },
  ),
  'pause or end': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, 'Pause or end pregnancy tracking');
    },
  ),
  'backup': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, 'Backup & restore');
      await _type(t, 0, 'correct horse');
      await _type(t, 1, 'correct hors');
    },
  ),
  'backup ready': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, 'Backup & restore');
      await _type(t, 0, 'correct horse');
      await _type(t, 1, 'correct horse');
      await _tapText(t, 'Create encrypted backup');
    },
  ),
  'restore': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, 'Backup & restore');
      await _tapText(t, 'Restore');
      await _tapText(t, 'Choose backup file');
      await _type(t, 0, 'wrong horse', below: 'Replace data and restore');
      await _tapText(t, 'Replace data and restore');
    },
  ),
  'restored': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, 'Backup & restore');
      await _tapText(t, 'Restore');
      await _tapText(t, 'Choose backup file');
      await _type(t, 0, 'correct horse', below: 'Replace data and restore');
      await _tapText(t, 'Replace data and restore');
    },
  ),
  'tracking ended': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, 'Pause or end pregnancy tracking');
      await t.tap(find.text('End tracking'));
      await t.pumpAndSettle();
    },
  ),
};

void main() {
  for (final MapEntry(key: name, value: (seeded, open)) in _screens.entries) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('$name at ${scale}x: no overflow, 48 dp labelled targets', (
        tester,
      ) async {
        await pumpApp(
          tester,
          seed: seeded ? _seed : null,
          library: _library,
          buildExpiry: _expiry,
          pickFile: _pickBackup,
          appUsage: _usage = FakeAppUsage(),
          nourishly: _nourishly = FakeNourishly(),
          textScale: scale,
          size: _small,
        );
        await open(tester);
        // Lists build lazily: scroll to the end so every section is laid out.
        final lists = find.byType(ListView);
        if (lists.evaluate().isNotEmpty) {
          await tester.drag(lists.first, const Offset(0, -20000));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });
    }
    testWidgets(
      '$name has a heading for screen readers',
      // Screen off is one full-screen "wake" button.
      skip: name == 'listen, screen off' || name == 'meditation, screen off',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(
          tester,
          seed: seeded ? _seed : null,
          library: _library,
          buildExpiry: _expiry,
          pickFile: _pickBackup,
          appUsage: _usage = FakeAppUsage(),
          nourishly: _nourishly = FakeNourishly(),
        );
        await open(tester);
        expect(find.semantics.byFlag(SemanticsFlag.isHeader), findsAtLeast(1));
        semantics.dispose();
      },
    );
    for (final brightness in Brightness.values) {
      testWidgets('$name text contrast (${brightness.name})', (tester) async {
        await pumpApp(
          tester,
          seed: seeded ? _seed : null,
          library: _library,
          buildExpiry: _expiry,
          pickFile: _pickBackup,
          appUsage: _usage = FakeAppUsage(),
          nourishly: _nourishly = FakeNourishly(),
          platformBrightness: brightness,
        );
        await open(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    }
  }

  testWidgets('reduce motion: onboarding steps change without animating', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await pumpApp(tester);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Welcome to Navmaas'), findsNothing);
    expect(find.text('When did this journey begin?'), findsOneWidget);
  });
}
