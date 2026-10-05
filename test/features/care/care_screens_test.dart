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
}
