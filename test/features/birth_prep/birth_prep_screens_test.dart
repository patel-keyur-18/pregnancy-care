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
}
