import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/sessions/domain/walk_draft.dart';

import '../../helpers.dart';

/// Week 24 (second trimester) on the test day.
Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Finder get _list => find.byType(Scrollable).first;

Future<void> _show(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: _list);
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

Future<List<Session>> _sessions(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.sessions).get()))!;

/// The switch on the row titled [title] (Me).
Finder _switch(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
  matching: find.byType(Switch),
);

void main() {
  testWidgets('a walk: Start, pause, leave, carry on, Finish logs it', (
    tester,
  ) async {
    final steps = FakeSteps();
    final db = await pumpApp(tester, seed: _seed, steps: steps);
    // Today's plan: reading and walking are always there.
    await _show(tester, 'Gentle walk');
    expect(find.text('0 of 2 done'), findsOneWidget);
    await tester.tap(find.text('Gentle walk'));
    await tester.pumpAndSettle();

    // Nothing runs until Start.
    expect(steps.asked, 1);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('4,820'), findsOneWidget);
    expect(find.text('of 6,000 steps'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('WALKING'), findsOneWidget);
    expect(find.text('1,420'), findsOneWidget);
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('2:00'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);

    // Back while walking pauses; the walk waits on the Sessions tile.
    await tester.tap(find.text('Resume'));
    await tester.pump(const Duration(minutes: 1));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 5));
    await _tab(tester, 'Sessions');
    await _show(tester, 'Paused · 3:00');

    await tester.tap(find.text('Paused · 3:00'));
    await tester.pumpAndSettle();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('3:00'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump(const Duration(minutes: 17));
    expect(find.text('20:00'), findsOneWidget);
    expect(await _sessions(tester, db), isEmpty, reason: 'only Finish logs');

    await tester.tap(find.text('Finish walk'));
    await tester.pumpAndSettle();
    final walk = (await _sessions(tester, db)).single;
    expect(walk.type, SessionType.walk);
    expect(walk.durationSec, 20 * 60);
    expect(walk.steps, 3 * 1420, reason: 'three stretches, no paused steps');
    final draft = await tester.runAsync(
      () => SettingsRepository(db).watch(SettingKeys.walkDraft).first,
    );
    expect(draft, isNull);

    await _show(tester, '4,820 of 6,000 steps');
    await _tab(tester, 'Today');
    await _show(tester, 'Gentle walk');
    expect(find.text('1 of 2 done'), findsOneWidget);
    await _tab(tester, 'Journey');
    await tester.scrollUntilVisible(
      find.text('walk logged'),
      300,
      scrollable: _list,
    );
    expect(find.text('walk logged'), findsOneWidget);
  });

  testWidgets("a walk left from yesterday goes to yesterday's log", (
    tester,
  ) async {
    final yesterday = DateTime(2026, 10, 4, 23, 40);
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await _seed(db);
        await SettingsRepository(db)
            .put(SettingKeys.walkDraft, WalkDraft.start(yesterday).encode());
      },
    );
    await _tab(tester, 'Sessions');
    await _show(tester, 'Walk');
    await tester.tap(find.text('Walk'));
    await tester.pumpAndSettle();
    expect(find.text('READY'), findsOneWidget);
    final walk = (await _sessions(tester, db)).single;
    expect((walk.startedAt, walk.durationSec), (yesterday, 20 * 60));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  });

  testWidgets('walk without Health access: no steps, a way to allow', (
    tester,
  ) async {
    final steps = FakeSteps()..access = false;
    await pumpApp(tester, seed: _seed, steps: steps);
    await _tab(tester, 'Sessions');
    await _show(tester, '20 min · easy pace');
    await tester.tap(find.text('Walk'));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(2));
    expect(find.textContaining('To see steps here'), findsOneWidget);

    steps.access = true;
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget, reason: 'not started yet');
    expect(find.text('4,820'), findsOneWidget);
    expect(
      find.text('Steps from Health Connect / Apple Health'),
      findsOneWidget,
    );

    // The daily goal is hers to set.
    await tester.tap(find.text('of 6,000 steps'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('of 8,000 steps'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  });

  testWidgets('routines wait for "doctor cleared me"; high risk hides some', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Sessions');
    await _show(tester, 'Gentle flow');
    expect(find.text('Needs “Doctor cleared me” in Me'), findsNWidgets(3));
    expect(find.text('Slow breathing'), findsOneWidget);

    // A locked routine leads to Me, where she can switch it on.
    await tester.tap(find.text('Gentle flow'));
    await tester.pumpAndSettle();
    await _show(tester, 'Doctor cleared me for exercise');
    await tester.tap(_switch('Doctor cleared me for exercise'));
    await tester.pumpAndSettle();

    await _tab(tester, 'Sessions');
    await _show(tester, '2nd trimester · 9 min');
    expect(find.text('Pelvic floor'), findsOneWidget);
    expect(find.text('Seated stretches'), findsOneWidget);

    await tester.tap(find.text('Gentle flow'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 7'), findsOneWidget);
    expect(find.text('Seated breathing'), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);
    // The timer waits for Start; Finish comes with it.
    expect(find.text('Finish'), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('1:00'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('is on in Me'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Go gently. Stop and rest'), findsOne);

    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Step 2 of 7'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 2000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Cat–cow stretch'), findsWidgets);
    await tester.tap(find.byTooltip('Previous move'));
    await tester.pump();
    expect(find.text('Step 1 of 7'), findsOneWidget);
    await tester.tap(find.byTooltip('Next move'));
    await tester.pump();
    expect(find.text('Step 2 of 7'), findsOneWidget);

    // Through to the end.
    await tester.pump(const Duration(minutes: 9));
    expect(find.text('Done. Rest a moment.'), findsOneWidget);
    await tester.ensureVisible(find.text('Finish'));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    final logged = (await _sessions(tester, db)).single;
    expect(
      (logged.type, logged.routineKey),
      (SessionType.exercise, 'gentle-flow-2'),
    );
    expect(logged.durationSec, greaterThan(8 * 60));

    // High risk hides the cautious routines.
    await _tab(tester, 'Me');
    await _show(tester, 'High-risk pregnancy');
    await tester.tap(_switch('High-risk pregnancy'));
    await tester.pumpAndSettle();
    await _tab(tester, 'Sessions');
    await _show(tester, 'Pelvic floor');
    expect(find.text('Gentle flow'), findsNothing);
    final pregnancy = await tester.runAsync(
      () => db.select(db.pregnancies).getSingle(),
    );
    expect((pregnancy!.exerciseCleared, pregnancy.highRisk), (true, true));
  });

  testWidgets('slow breathing: starts on tap, paces in and out, logs', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Sessions');
    await _show(tester, 'Slow breathing');
    await tester.tap(find.text('Slow breathing'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Breathe in for four'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Breathe in'), findsNothing, reason: 'not started');

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Breathe in'), findsOneWidget);
    expect(find.text('5:00 left'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Breathe out'), findsOneWidget);
    await tester.pump(const Duration(minutes: 5));
    expect(find.text('Done. Rest a moment.'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    final logged = (await _sessions(tester, db)).single;
    expect((logged.type, logged.durationSec), (SessionType.breathing, 300));

    // Walking needs no switch, and the step goal default stands.
    final goal = await tester.runAsync(
      () => SettingsRepository(db).watch(SettingKeys.stepGoal).first,
    );
    expect(goal, isNull);
  });
}
