// The Phase 1 flows checked on a real phone or simulator (ARCHITECTURE §16,
// M11b): onboarding → Today, "Taken" from a notification action, and a PDF
// imported and read. Each starts from an empty install and deletes all data
// at the end, so it only runs on an empty install:
//   flutter test integration_test/app_flow_test.dart -d <device>
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/delete_all_data.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/today/today_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// The app as `main()` starts it, on the phone's real encrypted database;
  /// null (and the test skipped) when the install already has data.
  Future<ProviderContainer?> start(
    WidgetTester tester, {
    PickFile? pickFile,
    Future<void> Function(AppDatabase db)? seed,
  }) async {
    final container = ProviderContainer(
      overrides: [
        if (pickFile != null) pickFileProvider.overrideWithValue(pickFile),
      ],
    );
    addTearDown(container.dispose);
    final db = container.read(appDatabaseProvider);
    if ((await db.select(db.pregnancies).get()).isNotEmpty) {
      markTestSkipped('Only on an empty install: it deletes all data');
      return null;
    }
    await seed?.call(db);
    await loadFirstValues(container);
    await container.read(reminderSchedulerProvider).init();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NavmaasApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 170 days before today: 24 weeks 2 days.
  DateTime lmp() {
    final n = DateTime.now();
    return DateTime.utc(n.year, n.month, n.day - 170);
  }

  Future<void> seedPregnancy(AppDatabase db) =>
      PregnancyRepository(db).saveDating(method: .lmp, date: lmp());

  testWidgets('fresh install → onboarding → Today shows the week', (
    tester,
  ) async {
    final container = await start(tester);
    if (container == null) return;
    expect(find.text('Welcome to Navmaas'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final d = lmp();
    final field = find.byKey(const ValueKey('date-field'));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('24 weeks 2 days'), findsOneWidget);
    // Doctor and reminders are optional; the summary saves.
    for (var step = 0; step < 3; step++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('weeks + 2d'), findsOneWidget);
    await container.read(deleteAllDataProvider)();
  });

  testWidgets('Taken from a notification action logs the dose', (tester) async {
    final container = await start(
      tester,
      seed: (db) async {
        await seedPregnancy(db);
        final id = (await db.select(db.pregnancies).getSingle()).id;
        await SupplementRepository(db).save(
          pregnancyId: id,
          name: 'Iron',
          doseText: '1 tablet',
          times: [
            (id: null, minuteOfDay: 23 * 60, weekdayMask: 127, label: null),
          ],
        );
      },
    );
    if (container == null) return;
    final db = container.read(appDatabaseProvider);
    final repo = SupplementRepository(db);
    final pregnancy = await db.select(db.pregnancies).getSingle();
    final plans = await repo.watchPlans(pregnancy.id).first;
    final now = DateTime.now();
    final slot = slotsOn(DateTime(now.year, now.month, now.day), plans).single;

    // What the OS hands the app when "Taken" is pressed on the lock screen:
    // it runs the background isolate's entry point on its own connection.
    await reminderActionInBackground(
      NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: ReminderAction.taken,
        payload: ReminderPayload(
          keys: ['dose:${slot.key}'],
          title: 'Iron',
          body: '1 tablet',
          actions: true,
        ).toJson(),
      ),
    );

    // Back in the app, its streams refresh on resume (another isolate wrote).
    db.markTablesUpdated([db.doseLogs]);
    final day = DateTime(now.year, now.month, now.day);
    final taken = await repo
        .watchTaken(day, DateTime(now.year, now.month, now.day + 1))
        .first;
    expect(taken, contains(slot.key));
    await container.read(deleteAllDataProvider)();
  });

  testWidgets('a PDF is imported, read for a minute and logged', (
    tester,
  ) async {
    final container = await start(
      tester,
      seed: seedPregnancy,
      pickFile: (_) async => (
        name: 'little_lamp.pdf',
        bytes: Stream.value(_pdf('The little lamp')),
      ),
    );
    if (container == null) return;
    await tab(tester, 'Sessions');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A book (PDF or text)'));
    for (
      var i = 0;
      i < 20 && find.text('little lamp').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.tap(find.text('little lamp').first);
    await tester.pumpAndSettle();

    // A reading counts from one minute (real time on the phone).
    await Future<void>.delayed(const Duration(seconds: 62));
    await tester.pump();
    await tester.tap(find.textContaining('Finish'));
    await tester.pumpAndSettle();

    final db = container.read(appDatabaseProvider);
    final session = await db.select(db.sessions).getSingle();
    expect(session.type, SessionType.reading);
    expect(session.durationSec, greaterThanOrEqualTo(60));
    await container.read(deleteAllDataProvider)();
  });
}

/// A one-page PDF saying [text], with a correct cross-reference table.
List<int> _pdf(String text) {
  final content = 'BT /F1 18 Tf 20 100 Td ($text) Tj ET';
  const page =
      '<</Type/Page/Parent 2 0 R/MediaBox[0 0 300 200]/Contents 4 0 R '
      '/Resources<</Font<</F1 5 0 R>>>>>>';
  final objects = [
    '<</Type/Catalog/Pages 2 0 R>>',
    '<</Type/Pages/Kids[3 0 R]/Count 1>>',
    page,
    '<</Length ${content.length}>>\nstream\n$content\nendstream',
    '<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>',
  ];
  final out = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (final (i, o) in objects.indexed) {
    offsets.add(out.length);
    out.write('${i + 1} 0 obj\n$o\nendobj\n');
  }
  final xref = out.length;
  out
    ..write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n')
    ..writeAll([
      for (final o in offsets) '${o.toString().padLeft(10, '0')} 00000 n \n',
    ])
    ..write(
      'trailer\n<</Size ${objects.length + 1}/Root 1 0 R>>\n'
      'startxref\n$xref\n%%EOF\n',
    );
  return ascii.encode(out.toString());
}
