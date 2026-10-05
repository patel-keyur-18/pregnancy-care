import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/care/presentation/supplements_screen.dart';

import '../../helpers.dart';

Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// The visible screen's list (not a text field's inner scrollable).
Finder get _list => find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: _list);
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Adds "Iron + folic acid", 1 tablet, 9:00 am (the default time).
Future<void> _addIron(WidgetTester tester) async {
  await _tab(tester, 'Care');
  await _tapText(tester, 'Add');
  expect(find.text('Common in pregnancy'), findsOneWidget);
  await tester.tap(find.text('Iron + folic acid'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'e.g. 1 tablet'),
    '1 tablet',
  );
  final label = find.widgetWithText(TextField, 'e.g. after breakfast');
  await tester.scrollUntilVisible(label, 200, scrollable: _list);
  await tester.enterText(label, 'after breakfast');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  // The first supplement offers reminders once.
  if (find.text('Not now').evaluate().isNotEmpty) {
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('add from the quick-pick, then take it from Care', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: _seed);
    await _addIron(tester);

    // Saving lands on the full list.
    expect(find.byType(SupplementsScreen), findsOneWidget);
    expect(find.text('9:00 am · 1 tablet · after breakfast'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    // Care keeps its scroll position; back to the top.
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('1 tablet · after breakfast'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Mark taken: Iron + folic acid'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Taken: Iron + folic acid'), findsOneWidget);
    final logs = await tester.runAsync(() => db.select(db.doseLogs).get());
    expect(logs, hasLength(1));
  });

  testWidgets("Today's plan lists and ticks today's doses", (tester) async {
    await pumpApp(tester, seed: _seed);
    expect(find.text('0 of 1 done'), findsOneWidget, reason: 'the walk');
    await _addIron(tester);
    await _tab(tester, 'Today');
    expect(find.text("Today's gentle plan"), findsOneWidget);
    expect(find.text('0 of 2 done'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Mark done: Iron + folic acid'),
      200,
      scrollable: _list,
    );
    await tester.tap(find.bySemanticsLabel('Mark done: Iron + folic acid'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 done'), findsOneWidget);
  });

  testWidgets('See all: this week, edit and remove', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _addIron(tester);
    expect(find.byType(SupplementsScreen), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(
      find.text(
        'Add exactly what your doctor prescribed. '
        'Navmaas reminds you — it never suggests doses.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Iron + folic acid'));
    await tester.pumpAndSettle();
    expect(find.text('Edit supplement'), findsOneWidget);
    await _tapText(tester, 'Remove supplement');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Remove supplement'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Iron + folic acid'), findsNothing);
  });

  testWidgets('Me: reminders need permission; limit and quiet hours persist', (
    tester,
  ) async {
    final reminders = find.descendant(
      of: find.ancestor(of: find.text('Reminders'), matching: find.byType(Row)),
      matching: find.byType(Switch),
    );
    final scheduler = FakeScheduler()..granted = false;
    final db = await pumpApp(tester, seed: _seed, scheduler: scheduler);
    await _tab(tester, 'Me');
    await tester.scrollUntilVisible(
      find.text('Calm notifications'),
      200,
      scrollable: _list,
    );
    await tester.ensureVisible(reminders);
    await tester.pumpAndSettle();

    await tester.tap(reminders);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget, reason: 'permission denied');
    expect(tester.widget<Switch>(reminders).value, isFalse);

    scheduler.granted = true;
    await tester.tap(reminders);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(reminders).value, isTrue);

    await tester.ensureVisible(find.byTooltip('More notifications'));
    await tester.tap(find.byTooltip('More notifications'));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    expect(find.text('9:30 pm – 7:00 am'), findsOneWidget);
    final saved = await tester.runAsync(
      () => SettingsRepository(db).watchAll().first,
    );
    expect(
      (saved![SettingKeys.remindersOn], saved[SettingKeys.dailyLimit]),
      ('true', '5'),
    );
  });

  testWidgets('first supplement offers reminders once', (tester) async {
    final scheduler = FakeScheduler();
    final db = await pumpApp(tester, seed: _seed, scheduler: scheduler);
    await _tab(tester, 'Care');
    await _tapText(tester, 'Add');
    await tester.tap(find.text('Folic acid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Remind you on time?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Turn on reminders'));
    await tester.pumpAndSettle();
    final on = await tester.runAsync(
      () => SettingsRepository(db).watch(SettingKeys.remindersOn).first,
    );
    expect(on, 'true');

    await _tapText(tester, 'Add');
    await tester.tap(find.text('Vitamin D3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Remind you on time?'), findsNothing);
  });
}
