import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';

import '../../helpers.dart';

Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

void main() {
  testWidgets('foods I avoid: add with a reason, edit, remove', (tester) async {
    await pumpApp(tester, seed: _seed);
    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Care'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Nutrition'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Nutrition'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(find.text('Foods I avoid'), findsOneWidget);

    await tester.tap(find.text('Add a food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Food'), 'Papaya');
    await tester.enterText(
      find.widgetWithText(TextField, 'Reason (optional)'),
      "doctor's advice",
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Papaya'), findsOneWidget);
    expect(find.text("doctor's advice"), findsOneWidget);

    await tester.tap(find.text('Papaya'));
    await tester.pumpAndSettle();
    expect(find.text('Edit food'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Papaya'),
      'Raw papaya',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Raw papaya'), findsOneWidget);

    await tester.tap(find.text('Raw papaya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Raw papaya'), findsNothing);
  });
}
