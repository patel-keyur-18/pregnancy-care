import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/third_trimester/data/third_trimester_repository.dart';

import '../../helpers.dart';

/// Week 24 on the test day.
Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

Future<String> _pregnancyId(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.pregnancies).getSingle()))!.id;

void main() {
  testWidgets('kick counter: count, undo, save; her pattern from 3 sessions', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await _seed(db);
        final id = (await db.select(db.pregnancies).getSingle()).id;
        final repo = ThirdTrimesterRepository(db);
        // Two earlier evenings, 8:20 pm and 9:05 pm.
        for (final (day, h, m) in [(4, 20, 20), (2, 21, 5)]) {
          final start = DateTime(2026, 10, day, h, m);
          await repo.saveKicks(
            pregnancyId: id,
            startedAt: start,
            endedAt: start.add(const Duration(minutes: 19)),
            count: 10,
          );
        }
      },
    );
    await _tab(tester, 'Care');
    await tester.tap(find.text('Kick counter'));
    await tester.pumpAndSettle();

    expect(find.text("Get to know your baby's usual pattern"), findsOneWidget);
    expect(find.text('Yesterday · 8:20 pm'), findsOneWidget);
    expect(find.text('Fri · 9:05 pm'), findsOneWidget);
    expect(find.text('10 in 19 min'), findsNWidgets(2));
    expect(find.textContaining('Usually most active'), findsNothing);
    expect(
      find.text(
        "Fewer movements than usual? Follow your doctor's advice and "
        'contact them.',
      ),
      findsOneWidget,
    );

    final tap = find.bySemanticsLabel(RegExp('^Log a movement'));
    for (var i = 0; i < 3; i++) {
      await tester.tap(tap);
      await tester.pump(const Duration(minutes: 3));
    }
    expect(find.bySemanticsLabel('Log a movement. 3 so far.'), findsOneWidget);
    expect(find.text('9:00 am'), findsOneWidget); // started
    expect(find.text('9 min'), findsOneWidget); // time so far
    await tester.tap(find.text('Undo last'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Save session'));
    await tester.pumpAndSettle();
    final saved = (await tester.runAsync(
      () => db.select(db.kickSessions).get(),
    ))!;
    expect(saved, hasLength(3));
    final today = saved.singleWhere((s) => s.startedAt.day == 5);
    expect(today.count, 2);
    expect(today.endedAt.difference(today.startedAt).inMinutes, 3);

    // A third session: her pattern appears. This morning's 2 in 3 min is
    // the briskest.
    await tester.tap(find.text('Kick counter'));
    await tester.pumpAndSettle();
    expect(find.text('Today · 9:00 am'), findsOneWidget);
    expect(find.text('2 in 3 min'), findsOneWidget);
    expect(find.text('Usually most active: 8–10 am'), findsOneWidget);
  });

  testWidgets('kick counter: leaving with a count saves it', (tester) async {
    final db = await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Care');
    await tester.tap(find.text('Kick counter'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Log a movement')));
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final saved = (await tester.runAsync(
      () => db.select(db.kickSessions).get(),
    ))!;
    expect(saved.single.count, 1);
  });

  testWidgets('contraction timer: time two, see length, gap and summary', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Care');
    await tester.tap(find.text('Contraction timer'));
    await tester.pumpAndSettle();
    expect(find.text('RESTING'), findsOneWidget);
    expect(find.text('Contractions you time appear here.'), findsOneWidget);

    await tester.tap(find.text('Contraction started'));
    await tester.pump(const Duration(seconds: 45));
    expect(find.text('CONTRACTION IN PROGRESS'), findsOneWidget);
    expect(find.text('0:45'), findsOneWidget);
    await tester.tap(find.text('Contraction ended'));
    await tester.pump(const Duration(minutes: 7, seconds: 15));
    await tester.tap(find.text('Contraction started'));
    await tester.pump(const Duration(seconds: 55));
    await tester.tap(find.text('Contraction ended'));
    await tester.pumpAndSettle();

    final log = (await tester.runAsync(
      () => db.select(db.contractions).get(),
    ))!;
    expect(log.map((c) => c.endedAt.difference(c.startedAt).inSeconds), [
      45,
      55,
    ]);
    expect(find.text('2'), findsOneWidget); // in the last hour
    expect(find.text('50 s'), findsOneWidget); // average length
    expect(find.text('8 min'), findsNWidgets(2)); // average and row gap
    expect(find.text('55 s'), findsOneWidget);
    expect(find.text('45 s'), findsOneWidget);
    expect(
      find.text(
        'A log to share with your doctor. Follow the plan they gave you for '
        'when to leave for the hospital.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('pause stops reminders and shows only the quiet page; resume', (
    tester,
  ) async {
    final scheduler = FakeScheduler()..permission = true;
    final db = await pumpApp(
      tester,
      scheduler: scheduler,
      seed: (db) async {
        await _seed(db);
        await SettingsRepository(db).put(SettingKeys.remindersOn, 'true');
        final id = (await db.select(db.pregnancies).getSingle()).id;
        await SupplementRepository(db).save(
          pregnancyId: id,
          name: 'Iron',
          doseText: '1 tablet',
          times: const [
            (id: null, minuteOfDay: 21 * 60, weekdayMask: 127, label: null),
          ],
        );
      },
    );
    await tester.pumpAndSettle();
    expect(
      scheduler.scheduled.where((r) => r.kind == ReminderKind.supplement),
      isNotEmpty,
    );

    await _tab(tester, 'Me');
    await _show(tester, 'Pause or end pregnancy tracking');
    await tester.tap(find.text('Pause or end pregnancy tracking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause tracking'));
    await tester.pumpAndSettle();

    expect(find.text('Tracking is paused'), findsOneWidget);
    expect(find.byType(NavmaasTabBar), findsNothing);
    expect(find.textContaining('weeks'), findsNothing);
    expect(scheduler.scheduled, isEmpty);
    final id = await _pregnancyId(tester, db);
    final row = (await tester.runAsync(
      () => db.select(db.pregnancies).getSingle(),
    ))!;
    expect((row.id, row.status), (id, PregnancyStatus.paused));

    await tester.tap(find.text('Resume tracking'));
    await tester.pumpAndSettle();
    expect(find.text("Today's gentle plan"), findsOneWidget);
    expect(
      scheduler.scheduled.where((r) => r.kind == ReminderKind.supplement),
      isNotEmpty,
    );
  });

  testWidgets('baby has arrived; start a new pregnancy from the quiet page', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Me');
    await _show(tester, 'Pause or end pregnancy tracking');
    await tester.tap(find.text('Pause or end pregnancy tracking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baby has arrived'));
    await tester.pumpAndSettle();
    expect(find.text('Congratulations'), findsOneWidget);
    expect(find.text('Resume tracking'), findsOneWidget);

    await tester.tap(find.text('Start a new pregnancy'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget); // onboarding
    // Back goes to the quiet page, not the tabs.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Congratulations'), findsOneWidget);
    final rows = (await tester.runAsync(
      () => db.select(db.pregnancies).get(),
    ))!;
    expect(rows.single.status, PregnancyStatus.delivered);
  });

  testWidgets('end tracking: no reason asked', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Me');
    await _show(tester, 'Pause or end pregnancy tracking');
    await tester.tap(find.text('Pause or end pregnancy tracking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Tracking has ended'), findsOneWidget);
    expect(find.text('Start a new pregnancy'), findsOneWidget);
  });

  testWidgets('iPhone build expiry: Me card; Today banner on the last day', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: _seed,
      buildExpiry: DateTime(2026, 10, 10, 14, 32),
    );
    // Five days left: no banner on Today.
    expect(find.textContaining('This iPhone build expires'), findsNothing);
    await _tab(tester, 'Me');
    await _show(tester, 'Expires Sat 10 Oct · in 5 days');
    expect(find.text('This iPhone build'), findsOneWidget);
  });

  testWidgets('iPhone build expiry: banner the day before', (tester) async {
    final scheduler = FakeScheduler()..permission = true;
    await pumpApp(
      tester,
      seed: (db) async {
        await _seed(db);
        await SettingsRepository(db).put(SettingKeys.remindersOn, 'true');
      },
      scheduler: scheduler,
      buildExpiry: DateTime(2026, 10, 6, 14, 32),
    );
    expect(
      find.text(
        'This iPhone build expires tomorrow. Back up, then run it from '
        'Xcode again.',
      ),
      findsOneWidget,
    );
    final reminder = scheduler.scheduled.singleWhere(
      (r) => r.kind == ReminderKind.buildExpiry,
    );
    expect(reminder.at, DateTime(2026, 10, 5, 10));
    expect(clockNow().isBefore(reminder.at), isTrue);
  });
}
