import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/settings/edit_details_screen.dart';
import 'package:navmaas/features/today/today_screen.dart';

import '../helpers.dart';

void main() {
  testWidgets('no name: plain greeting', (tester) async {
    await pumpApp(
      tester,
      seed: (db) =>
          PregnancyRepository(db)
              .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15)),
    );
    expect(find.textContaining(RegExp(r'^Good \w+$')), findsOneWidget);
  });

  testWidgets('theme toggle flips light ↔ dark and persists', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) =>
          PregnancyRepository(db)
              .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15)),
    );
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(TodayScreen))).brightness;
    expect(brightness(), Brightness.light);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    expect(
      await tester.runAsync(
        () => SettingsRepository(db).watch(SettingKeys.themeMode).first,
      ),
      'dark',
    );

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });

  testWidgets('past the due date shows "Due date + N days"', (tester) async {
    await pumpApp(
      tester,
      seed: (db) =>
          PregnancyRepository(db)
              .saveDating(method: .scan, date: DateTime.utc(2026, 10, 2)),
    );
    expect(find.text('Due date + 3 days'), findsOneWidget);
    expect(find.text('40 weeks 3 days'), findsOneWidget);
  });

  testWidgets('implausible dates: asks to check them', (tester) async {
    await pumpApp(
      tester,
      seed: (db) =>
          PregnancyRepository(db)
              .saveDating(method: .lmp, date: DateTime.utc(2025, 10, 2)),
    );
    expect(find.text('24 weeks 5 days'), findsNothing);
    await tester.tap(find.text('Check dates'));
    await tester.pumpAndSettle();
    expect(find.byType(EditDetailsScreen), findsOneWidget);
  });
}
