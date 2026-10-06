import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/domain/fold.dart';

import '../../helpers.dart';

/// Week 24 on the test day; a low mood and a night logged two days ago.
Future<void> _seed(AppDatabase db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  final id = (await db.select(db.pregnancies).getSingle()).id;
  final repo = WellbeingRepository(db);
  await repo.setMood(
    pregnancyId: id,
    day: DateTime.utc(2026, 10, 3),
    mood: .low,
  );
  await repo.saveSleep(
    pregnancyId: id,
    day: DateTime.utc(2026, 10, 3),
    bedAt: DateTime(2026, 10, 2, 23),
    wokeAt: DateTime(2026, 10, 3, 6),
    napMinutes: 30,
  );
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _openWellbeing(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavmaasTabBar),
      matching: find.text('Care'),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Wellbeing'));
}

void main() {
  test('symptom chips fold to what fits in two rows, then More', () {
    // 350 wide: 3 + 2 chips of 100 with a 90-wide More chip.
    final widths = List<double>.filled(10, 100);
    expect(chipsThatFit(widths, moreWidth: 90, maxWidth: 350), 5);
    expect(
      chipsThatFit(widths.take(6).toList(), moreWidth: 90, maxWidth: 350),
      6,
    );
    expect(chipsThatFit([400, 50], moreWidth: 50, maxWidth: 350), 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets('mood, symptom, sleep and water are saved and shown in the '
        'week (${brightness.name})', (tester) async {
      final db = await pumpApp(
        tester,
        seed: _seed,
        platformBrightness: brightness,
      );
      await _openWellbeing(tester);
      expect(find.text('Mood · symptoms · sleep · water'), findsOneWidget);
      expect(find.text('Not logged yet'), findsNWidgets(3));
      expect(find.text('0 of 8 glasses'), findsOneWidget);
      // The earlier night: 7 h + 30 min nap, the only one this week.
      expect(find.text('7 h 30 min a night'), findsOneWidget);
      expect(find.text('Average with naps · 1 night logged'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Nothing logged'), findsNWidgets(6));

      // Mood: a word and a note.
      await _tap(tester, find.text('Mood').first);
      expect(find.text('How are you today?'), findsOneWidget);
      await _tap(tester, find.text('Calm'));
      await tester.enterText(find.byType(TextField), 'Felt the baby move');
      await _tap(tester, find.text('Save'));
      expect(find.text('Calm'), findsNWidgets(2), reason: 'tile and week');

      // Symptoms: folded to two rows; More shows the rest.
      await _tap(tester, find.text('Symptoms').first);
      expect(find.textContaining('More · '), findsOneWidget);
      expect(find.text('Bloating'), findsNothing);
      await _tap(tester, find.textContaining('More · '));
      expect(find.text('Bloating'), findsOneWidget);
      expect(find.text('Fewer'), findsOneWidget);
      await _tap(tester, find.text('Heartburn'));
      await _tap(tester, find.text('Moderate'));
      await _tap(tester, find.text('Save'));
      expect(find.text('Heartburn · moderate'), findsOneWidget);
      expect(find.text('Heartburn (moderate)'), findsOneWidget);

      // Sleep: the last night's times are offered; add a nap.
      await _tap(tester, find.text('Sleep').first);
      expect(find.text('11:00 pm'), findsOneWidget);
      expect(find.text('6:00 am'), findsOneWidget);
      await _tap(tester, find.byTooltip('More nap time'));
      await _tap(tester, find.text('Rested'));
      await _tap(tester, find.text('Save'));
      expect(find.text('7 h 15 min'), findsOneWidget);

      // Water: two glasses, one taken back, and a higher goal.
      await _tap(tester, find.text('Water').first);
      await _tap(tester, find.text('Add a glass'));
      await _tap(tester, find.text('Add a glass'));
      await _tap(tester, find.byTooltip('Remove a glass'));
      await _tap(tester, find.byTooltip('Raise goal'));
      expect(find.text('1 of 9'), findsOneWidget);
      // Reminders are off until she turns them on.
      expect(find.text('Off'), findsOneWidget);
      await _tap(tester, find.byType(Switch));
      expect(find.text('Every 2 hours, 7:00 am – 9:30 pm'), findsOneWidget);
      await _tap(tester, find.byTooltip('Back'));

      expect(find.text('1 of 9 glasses'), findsOneWidget);
      expect(
        find.text('Sleep 7 h 15 min · Water 1 of 9'),
        findsOneWidget,
        reason: "today's row in the week",
      );
      expect(find.text('7 h 23 min a night'), findsOneWidget);
      expect(find.text('Average with naps · 2 nights logged'), findsOneWidget);

      final settings = await tester.runAsync(
        () => SettingsRepository(db).getAll(),
      );
      expect(settings![SettingKeys.waterGoal], '9');
      expect(settings[SettingKeys.waterRemind], 'true');
      final mood = await tester.runAsync(() => db.select(db.moodEntries).get());
      expect(
        mood!.map((m) => (m.mood, m.note)),
        containsAll([
          (MoodWord.calm, 'Felt the baby move'),
          (MoodWord.low, null),
        ]),
      );
    });
  }

  testWidgets("today's mood can be changed the same day", (tester) async {
    await pumpApp(tester, seed: _seed);
    await _openWellbeing(tester);
    await _tap(tester, find.text('Mood').first);
    await _tap(tester, find.text('Happy'));
    await _tap(tester, find.text('Save'));
    await _tap(tester, find.text('Mood').first);
    expect(
      tester.getSemantics(find.text('Happy')),
      isSemantics(isChecked: true),
    );
    await _tap(tester, find.text('Tired'));
    await _tap(tester, find.text('Save'));
    expect(find.text('Tired'), findsNWidgets(2));
    expect(find.text('Happy'), findsNothing);
  });

  testWidgets('her own symptom is saved and offered first next time', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await _openWellbeing(tester);
    await _tap(tester, find.text('Symptoms').first);
    expect(find.text('Save'), findsOneWidget);
    await _tap(tester, find.text('Add your own'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Your own'),
      'Itchy skin',
    );
    await _tap(tester, find.text('Strong'));
    await _tap(tester, find.text('Save'));
    expect(find.text('Itchy skin · strong'), findsOneWidget);

    await _tap(tester, find.text('Symptoms').first);
    expect(find.text('Itchy skin'), findsOneWidget, reason: 'a chip now');
    expect(find.text('Itchy skin · Strong'), findsOneWidget, reason: 'logged');
    await _tap(tester, find.byTooltip('Remove Itchy skin'));
    expect(find.text('Itchy skin · Strong'), findsNothing);
  });

  group("Today's card", () {
    Finder card() => find.text('How are you today?');

    testWidgets('a mood tap and water taps are saved', (tester) async {
      final db = await pumpApp(tester, seed: _seed);
      await tester.ensureVisible(card());
      await _tap(tester, find.text('Okay'));
      expect(
        tester.getSemantics(find.text('Okay')),
        isSemantics(isChecked: true),
      );
      await _tap(tester, find.byTooltip('Add a glass'));
      await _tap(tester, find.byTooltip('Add a glass'));
      await _tap(tester, find.byTooltip('Remove a glass'));
      expect(find.text('1 of 8 glasses'), findsOneWidget);
      final rows = await tester.runAsync(
        () async => (
          await db.select(db.moodEntries).get(),
          await db.select(db.waterLogs).get(),
        ),
      );
      expect(rows!.$1.map((m) => m.mood), contains(MoodWord.okay));
      expect(rows.$2.single.glasses, 1);
    });

    testWidgets('closing it hides it for the rest of the day', (tester) async {
      await pumpApp(
        tester,
        seed: (db) async {
          await _seed(db);
          // Closed yesterday: that doesn't hide it today.
          await SettingsRepository(db)
              .put(SettingKeys.wellbeingCardHidden, '2026-10-04');
        },
      );
      expect(card(), findsOneWidget);
      await _tap(tester, find.byTooltip('Hide for today'));
      expect(card(), findsNothing);
    });

    testWidgets('gone once today has a mood and the water goal', (
      tester,
    ) async {
      await pumpApp(
        tester,
        seed: (db) async {
          await _seed(db);
          final id = (await db.select(db.pregnancies).getSingle()).id;
          final repo = WellbeingRepository(db);
          await repo.setMood(pregnancyId: id, day: testToday, mood: .calm);
          await SettingsRepository(db).put(SettingKeys.waterGoal, '4');
          await repo.addWater(pregnancyId: id, day: testToday, delta: 3);
        },
      );
      expect(card(), findsOneWidget, reason: 'one glass to go');
      await _tap(tester, find.byTooltip('Add a glass'));
      expect(card(), findsNothing);
    });
  });
}
