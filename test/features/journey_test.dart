import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';

import '../helpers.dart';

Future<AppDatabase> _openJourney(WidgetTester tester, {DateTime? lmp}) async {
  final db = await pumpApp(
    tester,
    seed: (db) =>
        PregnancyRepository(db)
            .saveDating(method: .lmp, date: lmp ?? DateTime.utc(2026, 4, 15)),
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavmaasTabBar),
      matching: find.text('Journey'),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

final Finder _list = find.byType(Scrollable).first;

/// Scrolls [text] fully into view (not just partly, under the tab bar).
Future<void> _see(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: _list);
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on this week with its notes and checklist', (
    tester,
  ) async {
    await _openJourney(tester);
    expect(find.text('Week 24 · this week'), findsOneWidget);
    expect(find.text('About the size of a bhutta (corn cob)'), findsOneWidget);
    expect(
      find.text('The lungs are growing branches and tiny air sacs.'),
      findsOneWidget,
    );
    await _see(tester, "This week's checklist");
    await _see(
      tester,
      'Book the glucose test (GTT) if your doctor has advised it',
    );
    await _see(tester, 'Second trimester so far');
    expect(find.text('Week 11 of 14'), findsOneWidget);
    expect(find.text('checklist items done'), findsOneWidget);
    await _see(
      tester,
      'General information to help you keep track. '
      "Always follow your own doctor's advice.",
    );
  });

  testWidgets('ticking an item is saved and counted', (tester) async {
    final db = await _openJourney(tester);
    const item = 'Book the glucose test (GTT) if your doctor has advised it';
    await _see(tester, item);
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(
      () => db.select(db.checklistTicks).get(),
    );
    expect(rows!.single.itemKey, 'w24-gtt');
    expect(tester.getSemantics(find.text(item)), isSemantics(isChecked: true));
    await _see(tester, 'checklist item done');

    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
    await _see(tester, 'checklist items done');
  });

  testWidgets('pick another week, and switch trimester', (tester) async {
    await _openJourney(tester);
    // The chips open centred on this week.
    expect(
      tester.getCenter(find.bySemanticsLabel('Week 24')).dx,
      moreOrLessEquals(195, epsilon: 1),
    );
    await tester.tap(find.bySemanticsLabel('Week 27'));
    await tester.pumpAndSettle();
    expect(find.text('Week 27'), findsOneWidget);
    expect(
      find.text('About the size of a cabbage (patta gobhi)'),
      findsOneWidget,
    );
    await _see(tester, 'Week 27 checklist');

    await tester.scrollUntilVisible(find.text('3rd'), -200, scrollable: _list);
    await tester.tap(find.text('3rd'));
    await tester.pumpAndSettle();
    expect(find.text('Week 28'), findsOneWidget);

    await tester.tap(find.text('2nd'));
    await tester.pumpAndSettle();
    expect(find.text('Week 24 · this week'), findsOneWidget);
  });

  testWidgets('before week 4: shows week 4, not "this week"', (tester) async {
    await _openJourney(tester, lmp: DateTime.utc(2026, 9, 21));
    expect(find.text('Week 4'), findsOneWidget);
    expect(
      find.text('About the size of a poppy seed (khus khus)'),
      findsOneWidget,
    );
  });
}
