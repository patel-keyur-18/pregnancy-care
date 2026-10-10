import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/profile_repository.dart';
import 'package:navmaas/features/care/presentation/tests_screen.dart';
import 'package:navmaas/features/care/presentation/visit_screen.dart';

import '../../helpers.dart';

Future<void> _seed(AppDatabase db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  await ProfileRepository(db)
      .save(doctorName: 'Dr. Mehta', clinicName: 'City Clinic');
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

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

void main() {
  testWidgets('Coming up: tests due now; mark one done', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Care');
    await tester.scrollUntilVisible(
      find.text('Glucose test (GTT)'),
      200,
      scrollable: _list,
    );
    expect(find.text('Due weeks 24–28 · not booked yet'), findsOneWidget);

    await _tapText(tester, 'Glucose test (GTT)');
    expect(
      find.textContaining('Checks how your body handles sugar'),
      findsOneWidget,
    );
    await tester.tap(find.text('Mark as done'));
    await tester.pumpAndSettle();
    expect(
      find.text('Glucose test (GTT)'),
      findsNothing,
      reason: 'done items leave Coming up',
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all').last);
    await tester.pumpAndSettle();
    expect(find.byType(TestsScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Glucose test (GTT)'),
      200,
      scrollable: _list,
    );
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('add a visit: questions, bring along, Today card', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Care');
    await _tapText(tester, 'Add a visit');
    expect(
      find.widgetWithText(TextField, 'Dr. Mehta'),
      findsOneWidget,
      reason: 'from Me',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(VisitScreen), findsOneWidget);
    expect(find.text('TOMORROW'), findsOneWidget);
    expect(find.text('Dr. Mehta · City Clinic'), findsOneWidget);
    expect(
      find.text("Add the clinic's phone in Me → Your doctor."),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Add a question…'),
      'When should I book the GTT?',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('When should I book the GTT?'), findsOneWidget);

    await tester.tap(find.text('When should I book the GTT?'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('When should I book the GTT?')),
      isSemantics(isChecked: true),
    );

    final bring = find.widgetWithText(TextField, 'Add something to bring…');
    await tester.scrollUntilVisible(bring, 200, scrollable: _list);
    await tester.enterText(bring, 'Last blood report');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Last blood report'), findsOneWidget);

    await _tab(tester, 'Today');
    await tester.scrollUntilVisible(
      find.text('Next doctor visit'),
      200,
      scrollable: _list,
    );
    expect(
      find.text('Dr. Mehta · No questions yet'),
      findsOneWidget,
      reason: 'the one question was asked',
    );
  });

  testWidgets('blood sugar time: now at first, earlier is fine, never later', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Care');
    await _tapText(tester, 'Log blood sugar');
    // The clock is pinned to 9:00 am.
    expect(find.text('Today, 9:00 am'), findsOneWidget);
    Future<void> pick(String hour, String minute) async {
      await tester.tap(find.text('Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to text input mode'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), hour);
      await tester.enterText(fields.at(1), minute);
      await tester.tap(find.text('AM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    await pick('10', '30');
    expect(find.text('Pick a time that has passed'), findsOneWidget);
    expect(find.text('Today, 9:00 am'), findsOneWidget);
    await pick('7', '40');
    expect(find.text('Pick a time that has passed'), findsNothing);
    expect(find.text('Today, 7:40 am'), findsOneWidget);
  });

  testWidgets(
    'blood sugar: whole mg/dL only, logged with when, listed by day',
    (tester) async {
      await pumpApp(tester, seed: _seed);
      await _tab(tester, 'Care');
      await _tapText(tester, 'Log blood sugar');
      final value = find.widgetWithText(TextField, 'mg/dL');
      // A mmol/L habit or a zero is refused: Save does nothing.
      for (final typed in ['5.6', '0']) {
        await tester.enterText(value, typed);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget, reason: typed);
        // Review fix: she is told why, not left guessing.
        expect(
          find.text('Whole mg/dL, like 96'),
          findsOneWidget,
          reason: typed,
        );
      }
      await tester.enterText(value, '96');
      await tester.tap(find.text('Fasting'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Note (optional)'),
        'after a walk',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.scrollUntilVisible(
        find.text('96 mg/dL'),
        200,
        scrollable: _list,
      );

      await _tapText(tester, 'Blood sugar');
      expect(find.text('96'), findsOneWidget);
      expect(find.text('Fasting'), findsOneWidget);
      expect(find.text('after a walk'), findsOneWidget);
      expect(
        find.textContaining(
          RegExp(r'\b(high|low|normal|range)\b', caseSensitive: false),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('vitals: log weight and blood pressure', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _tab(tester, 'Care');
    await _tapText(tester, 'Log weight');
    await tester.enterText(find.byType(TextField), '61.2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('61.2 kg'),
      200,
      scrollable: _list,
    );

    await _tapText(tester, 'Log weight');
    await tester.enterText(find.byType(TextField), '62');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('+0.8 kg since your first log'),
      200,
      scrollable: _list,
    );

    await _tapText(tester, 'Log BP');
    await tester.enterText(
      find.widgetWithText(TextField, 'Upper (systolic)'),
      '112',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Lower (diastolic)'),
      '72',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('112/72'),
      200,
      scrollable: _list,
    );
  });

  // Owner, 2026-10-10: the kick counter always; the contraction timer from
  // week 28; Hospital bag and Birth plan from week 32, under them.
  for (final (week, lmp, contractions, ready) in [
    (24, DateTime.utc(2026, 4, 15), false, false),
    (30, DateTime.utc(2026, 3, 9), true, false),
    (33, DateTime.utc(2026, 2, 16), true, true),
  ]) {
    testWidgets('Care tiles at week $week', (tester) async {
      await pumpApp(
        tester,
        seed: (db) =>
            PregnancyRepository(db).saveDating(method: .lmp, date: lmp),
      );
      await _tab(tester, 'Care');
      expect(find.text('Kick counter'), findsOneWidget);
      expect(
        find.text('Contraction timer'),
        contractions ? findsOneWidget : findsNothing,
      );
      expect(find.text('Hospital bag'), ready ? findsOneWidget : findsNothing);
      expect(find.text('Birth plan'), ready ? findsOneWidget : findsNothing);
      if (ready) {
        expect(
          tester.getTopLeft(find.text('Hospital bag')).dy,
          lessThan(tester.getTopLeft(find.text('Wellbeing')).dy),
        );
        await tester.tap(find.text('Hospital bag'));
        await tester.pumpAndSettle();
        expect(find.textContaining('packed'), findsOneWidget);
      }
    });
  }
}
