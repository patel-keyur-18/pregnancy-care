import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';

import '../../helpers.dart';

/// A pregnancy, a past visit on 17 Sep and a question for the next one.
Future<void> _seed(AppDatabase db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  final pid = (await db.select(db.pregnancies).getSingle()).id;
  final visits = VisitRepository(db);
  await visits.saveAppointment(pregnancyId: pid, at: DateTime(2026, 9, 17, 11));
  await visits.addQuestion(pid, 'When is the next scan?');
}

Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(NavmaasTabBar)))
      .go('/care/visit-summary');
  await _settleIo(tester);
}

bool _selected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

bool? _checked(WidgetTester tester, String label) => tester
    .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label))
    .value;

void main() {
  testWidgets('defaults: since last visit, the clinical sections ticked', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    await _open(tester);
    expect(find.text('Visit summary'), findsOneWidget);
    expect(_selected(tester, 'Since last visit'), isTrue);
    expect(find.text('Thu, 17 Sep – Mon, 5 Oct 2026'), findsOneWidget);
    for (final s in [
      'Pregnancy summary',
      'Supplements',
      'Vitals',
      'Questions',
      'Kicks and contractions',
      'Records',
    ]) {
      await tester.scrollUntilVisible(
        find.text(s),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(_checked(tester, s), isTrue, reason: s);
    }
    for (final s in ['Wellbeing', 'Birth plan']) {
      await tester.scrollUntilVisible(
        find.text(s),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(_checked(tester, s), isFalse, reason: s);
    }
  });

  testWidgets('whole pregnancy changes the dates', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _open(tester);
    await tester.tap(find.text('Whole pregnancy'));
    await tester.pumpAndSettle();
    expect(find.text('Wed, 15 Apr – Mon, 5 Oct 2026'), findsOneWidget);
  });

  testWidgets('her choice of sections is remembered', (tester) async {
    final db = await pumpApp(tester, seed: _seed);
    await _open(tester);
    await tester.scrollUntilVisible(
      find.text('Wellbeing'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Wellbeing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wellbeing'));
    await _settleIo(tester);
    final stored = await tester.runAsync(() => SettingsRepository(db).getAll());
    expect(
      stored![SettingKeys.summarySections],
      'pregnancy,supplements,vitals,questions,kicks,records,wellbeing',
    );
    GoRouter.of(tester.element(find.byType(NavmaasTabBar))).go('/care');
    await _settleIo(tester);
    await _open(tester);
    await tester.scrollUntilVisible(
      find.text('Wellbeing'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(_checked(tester, 'Wellbeing'), isTrue);
  });

  testWidgets('Make PDF shares a PDF and leaves no copy', (tester) async {
    final shared = <List<int>>[];
    final temp = Directory.systemTemp.createTempSync('navmaas_st');
    await pumpApp(
      tester,
      seed: _seed,
      recordsTemp: temp,
      share: (f) async => shared.add(f.readAsBytesSync()),
    );
    await _open(tester);
    await tester.tap(find.text('Make PDF and share'));
    await _settleIo(tester);
    expect(String.fromCharCodes(shared.single.take(5)), '%PDF-');
    expect(temp.listSync(), isEmpty);
  });
}
