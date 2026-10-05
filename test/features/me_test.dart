import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/settings/edit_details_screen.dart';
import 'package:navmaas/features/settings/me_screen.dart';
import 'package:navmaas/features/today/today_screen.dart';

import '../helpers.dart';

Future<void> _seed(AppDatabase db) async {
  await SettingsRepository(db).put(SettingKeys.firstName, 'Meera');
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
}

final Finder _editList = find
    .descendant(
      of: find.byType(EditDetailsScreen),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _openMe(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text('Me')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows name, due date, method and the disclaimer', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await _openMe(tester);
    expect(find.text('Meera'), findsOneWidget);
    expect(find.text('Due Wed, 20 Jan 2027'), findsOneWidget);
    expect(find.text('Dated by last period'), findsOneWidget);
    expect(
      find.text('Navmaas is a personal tracking aid, not medical advice.'),
      findsOneWidget,
    );
  });

  testWidgets('appearance: Light / Dark / System, persisted', (tester) async {
    final db = await pumpApp(
      tester,
      seed: _seed,
      platformBrightness: Brightness.dark,
    );
    await _openMe(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(MeScreen))).brightness;
    expect(brightness(), Brightness.dark, reason: 'System by default');

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    expect(
      await tester.runAsync(
        () => SettingsRepository(db).watch(SettingKeys.themeMode).first,
      ),
      'system',
    );
  });

  testWidgets('edit dates re-runs the engine everywhere', (tester) async {
    final db = await pumpApp(tester, seed: _seed);
    await _openMe(tester);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('24 weeks 5 days'),
      200,
      scrollable: _editList,
    );

    await tester.ensureVisible(find.text('Scan due date'));
    await tester.tap(find.text('Scan due date'));
    await tester.pumpAndSettle();
    await pickDate(tester, '01/27/2027');
    await tester.scrollUntilVisible(
      find.text('23 weeks 5 days'),
      200,
      scrollable: _editList,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(MeScreen), findsOneWidget);
    expect(find.text('Due Wed, 27 Jan 2027'), findsOneWidget);
    expect(find.text('Dated by scan due date'), findsOneWidget);
    expect(
      await tester.runAsync(() => db.select(db.pregnancies).get()),
      hasLength(1),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Today'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('23 weeks 5 days')), findsOneWidget);
  });

  testWidgets('name can be changed, and cleared', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _openMe(tester);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Meera'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Asha ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Asha'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('You'), findsOneWidget);
    await _tab(tester, 'Today');
    expect(find.textContaining(RegExp(r'^Good \w+$')), findsOneWidget);
  });
}
