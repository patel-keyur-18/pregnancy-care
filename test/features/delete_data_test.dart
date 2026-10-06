import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';

import '../helpers.dart';

Future<void> _seed(AppDatabase db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  await SettingsRepository(db).put(SettingKeys.remindersOn, 'true');
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text('Me')),
  );
  await tester.pumpAndSettle();
  final button = find.text('Delete all data');
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('delete all data: explains, then starts again at onboarding', (
    tester,
  ) async {
    final scheduler = FakeScheduler();
    final db = await pumpApp(tester, scheduler: scheduler, seed: _seed);
    expect(scheduler.scheduled, isNotEmpty);
    await _openDialog(tester);
    expect(find.text('Delete all data?'), findsOneWidget);
    expect(
      find.text(
        'This deletes everything Navmaas keeps on this phone: your pregnancy, '
        'logs, photos, books, audio and settings. Backup files you saved '
        'elsewhere are not touched.',
      ),
      findsOneWidget,
    );
    expect(find.text('No backup yet'), findsOneWidget);

    // Cancel changes nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final before = await tester.runAsync(() => db.select(db.pregnancies).get());
    expect(before, hasLength(1));

    await _openDialog(tester);
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Navmaas'), findsOneWidget);
    expect(scheduler.scheduled, isEmpty);
    final after = await tester.runAsync(() => db.select(db.pregnancies).get());
    expect(after, isEmpty);
  });

  testWidgets('"Back up first" opens Backup & restore', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _openDialog(tester);
    await tester.tap(find.text('Back up first'));
    await tester.pumpAndSettle();
    expect(find.text('Create encrypted backup'), findsOneWidget);
  });

  testWidgets('a failed delete says so and can be tried again', (tester) async {
    var tries = 0;
    await pumpApp(
      tester,
      seed: _seed,
      deleteAll: () async {
        tries++;
        throw const FileSystemException('busy');
      },
    );
    await _openDialog(tester);
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
    expect(
      find.text('Not everything could be deleted. Please try again.'),
      findsOneWidget,
    );
    expect(tries, 1);
    expect(find.text('Delete everything'), findsOneWidget);
  });
}
