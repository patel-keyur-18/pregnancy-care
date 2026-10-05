import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/utils/clock.dart';

/// Fixed "today" for widget tests: Monday, 5 October 2026.
final testToday = DateTime.utc(2026, 10, 5);

/// Pumps the whole app on a fresh in-memory database, like a first install.
/// [seed] runs against the database before the first frame.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db)? seed,
  Brightness platformBrightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // Synchronous stream closing: no drift timer outlives the widget tree.
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  if (seed != null) await tester.runAsync(() => seed(db));
  tester.platformDispatcher
    ..platformBrightnessTestValue = platformBrightness
    ..textScaleFactorTestValue = textScale;
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() async {
    tester.platformDispatcher.clearAllTestValues();
    tester.view.reset();
    // Real async: after a failed test drift may still be mid-query, and
    // closing inside the fake-async zone would wait forever.
    await tester.runAsync(db.close);
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(testToday),
        // 9:00 am, so the greeting is always "Good morning".
        nowProvider.overrideWithValue(DateTime(2026, 10, 5, 9)),
      ],
      child: const NavmaasApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Opens the date field and types [mmddyyyy] in the picker's input mode.
Future<void> pickDate(WidgetTester tester, String mmddyyyy) async {
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
    mmddyyyy,
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}
