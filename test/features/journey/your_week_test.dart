import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';

import '../../helpers.dart';

/// Dating start 15 Apr 2026: this week (5 Oct) is week 24; week 22 is
/// 16–22 Sep, when Iron (9 pm daily) was added.
Future<void> _seed(AppDatabase db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  final id = (await db.select(db.pregnancies).getSingle()).id;
  final supplements = SupplementRepository(db);
  await supplements.save(
    pregnancyId: id,
    name: 'Iron',
    doseText: '1 tablet',
    times: [(id: null, minuteOfDay: 21 * 60, weekdayMask: 127, label: null)],
  );
  await db
      .update(db.supplements)
      .write(SupplementsCompanion(createdAt: Value(DateTime(2026, 9, 16))));
  final schedule = await db.select(db.supplementSchedules).getSingle();
  for (var d = 16; d <= 21; d++) {
    await supplements.setTaken(
      schedule.id,
      DateTime(2026, 9, d, 21),
      taken: true,
    );
  }
  final sessions = SessionRepository(db);
  Future<void> log(SessionType type, int day, int minutes) => sessions.log(
    pregnancyId: id,
    type: type,
    startedAt: DateTime(2026, 9, day, 8),
    durationSec: minutes * 60,
  );
  await log(.walk, 16, 20);
  await log(.walk, 18, 20);
  await log(.exercise, 17, 15);
  await log(.reading, 19, 15);
  final wellbeing = WellbeingRepository(db);
  await wellbeing.setMood(
    pregnancyId: id,
    day: DateTime.utc(2026, 9, 17),
    mood: .calm,
  );
  await wellbeing.addWater(
    pregnancyId: id,
    day: DateTime.utc(2026, 9, 18),
    delta: 6,
  );
}

Finder get _list => find.byType(Scrollable).first;

Future<void> _see(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _list);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _week(WidgetTester tester, int week) async {
  // Back to the top, where the week chips are.
  await tester.drag(_list, const Offset(0, 3000));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel('Week $week'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a past week: three rows, then Show more and Show less', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Journey'),
      ),
    );
    await tester.pumpAndSettle();
    await _week(tester, 22);
    await _see(tester, find.text('Your week 22'));
    expect(find.text('16 Sep – 22 Sep'), findsOneWidget);
    expect(find.text('6 of 7 taken'), findsOneWidget);
    // Two walks; Health's 4,820 a day (under the goal) over 7 days.
    expect(find.text('2 days · 40 min · 33,740 steps'), findsOneWidget);
    expect(find.text('1 session · 15 min'), findsOneWidget);
    expect(find.text('Reading'), findsNothing);

    await _see(tester, find.text('Show more (3)'));
    await tester.tap(find.text('Show more (3)'));
    await tester.pumpAndSettle();
    await _see(tester, find.text('Calm 1'));
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('6 glasses a day, on average'), findsOneWidget);

    await _see(tester, find.text('Show less'));
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text('Reading'), findsNothing);
  });

  testWidgets('this week so far; nothing logged; none for later weeks', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Journey'),
      ),
    );
    await tester.pumpAndSettle();
    await _see(tester, find.text('Your week so far'));
    expect(find.text('30 Sep – today'), findsOneWidget);
    // Doses due this week (none taken): the row shows what was due.
    expect(find.text('0 of 6 taken'), findsOneWidget);

    await _week(tester, 25);
    expect(find.textContaining('Your week'), findsNothing);

    await _week(tester, 23);
    await _see(tester, find.text('Your week 23'));
    expect(find.text('0 of 7 taken'), findsOneWidget);
    expect(find.text('Show more (1)'), findsNothing, reason: 'nothing more');

    // Before Iron was added (16 Sep) and before any log.
    await _week(tester, 21);
    await _see(tester, find.text('Your week 21'));
    expect(find.text('Nothing logged this week.'), findsOneWidget);
  });
}
