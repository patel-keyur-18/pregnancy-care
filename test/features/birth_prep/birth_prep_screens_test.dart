import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';

import '../../helpers.dart';

/// Week 32 on the test's day (5 Oct 2026).
Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 2, 20));

Future<void> _open(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(NavmaasTabBar))).go(path);
  await tester.pumpAndSettle();
}

final int _bagCount = parseHospitalBag(
  File('assets/content/hospital_bag.json').readAsStringSync(),
).length;

void main() {
  testWidgets('hospital bag: tick, add her own, remove it', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _open(tester, '/care/bag');
    expect(find.text('0 of $_bagCount packed'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1 of $_bagCount packed'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Add your own'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add your own'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents').last);
    await tester.enterText(find.byType(TextField), 'Phone charger');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // Her own item sits under Documents, the last section.
    await tester.scrollUntilVisible(
      find.text('Phone charger'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Remove Phone charger'));
    await tester.pumpAndSettle();
    expect(find.text('Phone charger'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('1 of $_bagCount packed'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
  });

  testWidgets('hospital bag: the reminder shows when set and clears', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await _seed(db);
        await SettingsRepository(db)
            .put(SettingKeys.bagRemindAt, '2026-10-08T10:00:00.000');
      },
    );
    await _open(tester, '/care/bag');
    expect(find.text('Thu, 8 Oct at 10:00 am'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('No reminder set'), findsOneWidget);
    final left = await tester.runAsync(() => SettingsRepository(db).getAll());
    expect(left![SettingKeys.bagRemindAt], isNull);
  });

  testWidgets('birth plan: answer a prompt, edit it, others stay empty', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await _open(tester, '/care/birth-plan');
    expect(find.text('Talk this through with your doctor.'), findsOneWidget);
    final prompts = parseBirthPlan(
      File('assets/content/birth_plan.json').readAsStringSync(),
    );
    expect(find.text('Add your thoughts'), findsWidgets);
    await tester.tap(find.text(prompts.first.title));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My husband');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('My husband'), findsOneWidget);

    await tester.tap(find.text('My husband'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My husband and my mother');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('My husband and my mother'), findsOneWidget);
  });

  // Review fix: a reminder must never look set when it can't ring.
  testWidgets('hospital bag: a past reminder shows as none', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await _seed(db);
        await SettingsRepository(db)
            .put(SettingKeys.bagRemindAt, '2026-10-04T10:00:00.000');
      },
    );
    await _open(tester, '/care/bag');
    expect(find.text('No reminder set'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('hospital bag: with reminders off, says so and offers them', (
    tester,
  ) async {
    final scheduler = FakeScheduler();
    final db = await pumpApp(
      tester,
      scheduler: scheduler,
      seed: (db) async {
        await _seed(db);
        await SettingsRepository(db)
            .put(SettingKeys.bagRemindAt, '2026-10-08T10:00:00.000');
      },
    );
    await _open(tester, '/care/bag');
    expect(
      find.text("Reminders are off, so this one won't ring."),
      findsOneWidget,
    );

    // Setting it again offers to turn reminders on.
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Remind you on time?'), findsOneWidget);
    await tester.tap(find.text('Turn on reminders'));
    await tester.pumpAndSettle();
    final settings = await tester.runAsync(
      () => SettingsRepository(db).getAll(),
    );
    expect(settings![SettingKeys.remindersOn], 'true');
    expect(
      find.text("Reminders are off, so this one won't ring."),
      findsNothing,
    );
  });
}
