import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/today/mood_scene_card.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';

import '../../helpers.dart';

/// A pregnancy, and [mood] on [day] (today by default).
Future<void> Function(AppDatabase) _seed(MoodWord? mood, {DateTime? day}) =>
    (db) async {
      await PregnancyRepository(db)
          .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
      if (mood == null) return;
      final id = (await db.select(db.pregnancies).getSingle()).id;
      await WellbeingRepository(db)
          .setMood(pregnancyId: id, day: day ?? testToday, mood: mood);
    };

Future<void> _cycle(WidgetTester tester, List<AppLifecycleState> states) async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
}

/// Where the scene's motion is, 0 → 1.
double _t(WidgetTester tester) =>
    (tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is MoodScenePainter,
                  ),
                )
                .painter!
            as MoodScenePainter)
        .t;

void main() {
  testWidgets('no mood today (or only yesterday): no scene', (tester) async {
    await pumpApp(
      tester,
      seed: _seed(
        MoodWord.low,
        day: testToday.subtract(const Duration(days: 1)),
      ),
    );
    expect(find.textContaining('TODAY'), findsNothing);
    expect(find.text('You and baby, together today.'), findsNothing);
  });

  testWidgets('every mood has its own scene and line', (tester) async {
    for (final (mood, line) in [
      (MoodWord.calm, 'A calm day, shared with baby.'),
      (MoodWord.happy, 'Baby is along for your happy day.'),
      (MoodWord.okay, 'One gentle day at a time, together.'),
      (MoodWord.tired, 'You and baby, resting together today.'),
      (MoodWord.low, 'You and baby, together today.'),
    ]) {
      final db = await pumpApp(tester, seed: _seed(mood));
      await tester.pumpAndSettle();
      expect(find.text(line), findsOneWidget, reason: mood.name);
      expect(
        find.text(
          '${mood.name[0].toUpperCase()}${mood.name.substring(1)} '
                  'today'
              .toUpperCase(),
        ),
        findsOneWidget,
      );
      // Unmount before the next app (its database stays open).
      await tester.pumpWidget(const SizedBox());
      expect(db, isNotNull);
    }
  });

  testWidgets('moves for 12 s when Today opens, on tap, and on coming back', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: _seed(MoodWord.tired));
    // Opening Today played it through (pumpApp settles) and it rests; 1
    // looks the same as 0.
    await tester.pumpAndSettle();
    expect(_t(tester), 1, reason: 'played when Today opened');

    await tester.tap(find.text('You and baby, resting together today.'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(_t(tester), closeTo(0.5, 0.05), reason: 'a tap plays it again');
    await tester.pumpAndSettle();
    expect(_t(tester), 1, reason: 'then it rests');

    await _cycle(tester, [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    await tester.pump(const Duration(seconds: 3));
    expect(_t(tester), closeTo(0.25, 0.05), reason: 'opening the app again');
    await tester.pumpAndSettle();

    // Changing today's mood changes the scene.
    final id = (await tester.runAsync(
      () => db.select(db.pregnancies).getSingle(),
    ))!.id;
    await tester.runAsync(
      () =>
          WellbeingRepository(db)
              .setMood(pregnancyId: id, day: testToday, mood: MoodWord.happy),
    );
    await tester.pumpAndSettle();
    expect(find.text('Baby is along for your happy day.'), findsOneWidget);
  });

  testWidgets('with reduce motion it is a still picture', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, seed: _seed(MoodWord.low));
    await tester.pumpAndSettle();
    expect(find.text('You and baby, together today.'), findsOneWidget);
    expect(_t(tester), 0);
    await tester.tap(find.text('You and baby, together today.'));
    await tester.pump(const Duration(seconds: 3));
    expect(_t(tester), 0, reason: 'a tap does not move it either');
  });

  testWidgets('screen readers hear the scene and its line', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, seed: _seed(MoodWord.calm));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'A lotus on still water, with slow ripples. '
        'A calm day, shared with baby.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
