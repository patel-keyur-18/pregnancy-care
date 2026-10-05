import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/features/today/today_screen.dart';

import '../helpers.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('fresh install → onboarding → Today (${brightness.name})', (
      tester,
    ) async {
      final db = await pumpApp(tester, platformBrightness: brightness);
      expect(
        Theme.of(tester.element(find.text('Welcome to Navmaas'))).brightness,
        brightness,
      );

      // Step 1: optional name.
      expect(
        find.text('No account needed. Everything stays on this phone.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'Meera');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: last period, 28-day cycle; Continue waits for a date.
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await pickDate(tester, '04/15/2026');
      expect(find.text('24 weeks 5 days'), findsOneWidget);
      expect(find.text('Month 6 · Second trimester'), findsOneWidget);
      expect(find.text('Due Wed, 20 Jan 2027'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: confirm and save.
      expect(find.text('Does this look right?'), findsOneWidget);
      expect(find.text('Dated by last period'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(TodayScreen), findsOneWidget);
      final saved = await tester.runAsync(
        () => db.select(db.pregnancies).getSingle(),
      );
      expect(saved!.datingMethod, DatingMethod.lmp);
      expect(saved.dueDate, DateTime.utc(2027, 1, 20));
      final name = await tester.runAsync(
        () => SettingsRepository(db).watch(SettingKeys.firstName).first,
      );
      expect(name, 'Meera');
    });
  }
}
