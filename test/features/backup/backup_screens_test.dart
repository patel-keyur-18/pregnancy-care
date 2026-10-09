import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/reminders/data_reminders.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';
import 'package:navmaas/l10n/gen/app_localizations_en.dart';

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

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _openBackup(WidgetTester tester) async {
  await _tab(tester, 'Me');
  await _tapText(tester, 'Backup & restore');
}

void main() {
  group('weekly backup reminder', () {
    final l10n = AppLocalizationsEn();
    // Monday 5 October 2026, 9:00.
    final now = DateTime(2026, 10, 5, 9);

    test('Sundays at 10:00 by default', () {
      final c = backupCandidates(
        now: now,
        day: DateTime.sunday,
        lastBackup: null,
        expiry: null,
        l10n: l10n,
      );
      expect(c.map((c) => c.at), [DateTime(2026, 10, 11, 10)]);
      expect(c.single.kind, ReminderKind.backup);
      expect(c.single.title, 'Time for a backup');
    });

    test('skipped after a backup in the 6 days before it', () {
      List<DateTime> at(DateTime last) => [
        for (final c in backupCandidates(
          now: now,
          day: DateTime.sunday,
          lastBackup: last,
          expiry: null,
          l10n: l10n,
          days: 15,
        ))
          c.at,
      ];
      expect(at(DateTime(2026, 10, 6, 20)), [DateTime(2026, 10, 18, 10)]);
      expect(at(DateTime(2026, 10, 4, 20)), [
        DateTime(2026, 10, 11, 10),
        DateTime(2026, 10, 18, 10),
      ]);
    });

    test('the build-expiry reminder covers its day; off is off', () {
      expect(
        backupCandidates(
          now: now,
          day: DateTime.saturday,
          lastBackup: null,
          expiry: DateTime(2026, 10, 11, 14),
          l10n: l10n,
        ),
        isEmpty,
      );
      expect(
        backupCandidates(
          now: now,
          day: 0,
          lastBackup: null,
          expiry: null,
          l10n: l10n,
        ),
        isEmpty,
      );
    });
  });

  test('the backup header names the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  testWidgets('back up: password twice, then save or share', (tester) async {
    final backup = FakeBackupService();
    final shared = <File>[];
    await pumpApp(
      tester,
      seed: _seed,
      backup: backup,
      share: (f) async => shared.add(f),
    );
    await _tab(tester, 'Me');
    await tester.scrollUntilVisible(
      find.text('No backup yet · password protected'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _tapText(tester, 'Backup & restore');

    expect(find.text('No backup yet'), findsOneWidget);
    expect(find.text('Next reminder Sun 11 Oct'), findsOneWidget);
    expect(
      find.text(
        'Off keeps it small (about 2.4 MB). Books and audio can be '
        're-imported.',
      ),
      findsOneWidget,
    );
    final create = find.widgetWithText(FilledButton, 'Create encrypted backup');
    expect(tester.widget<FilledButton>(create).onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), 'correct horse');
    await tester.enterText(find.byType(TextField).at(1), 'correct hors');
    await tester.pump();
    expect(find.text('The two passwords don’t match yet.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'correct horse');
    await tester.pump();
    expect(find.text('Passwords match.'), findsOneWidget);
    // Show / hide.
    expect(find.bySemanticsLabel('Show password'), findsOneWidget);
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(
      find.text('Backup about 184.8 MB — includes imported books and audio'),
      findsOneWidget,
    );
    // Voice letters: off by default, and remembered once on (E3).
    expect(
      find.textContaining('their voice notes stay on this phone'),
      findsOne,
    );
    await tester.ensureVisible(find.byType(Switch).last);
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'About 6.0 MB more; the voice notes stay encrypted inside the backup',
      ),
      findsOneWidget,
    );
    await _tapText(tester, 'Create encrypted backup');
    expect(backup.created.single, (
      password: 'correct horse',
      includeLibrary: true,
      includeVoice: true,
    ));
    expect(find.text('Backup ready'), findsOneWidget);
    expect(find.text('navmaas-backup-2026-10-05.navmaas'), findsOneWidget);
    expect(find.text('2.4 MB · 1,284 entries · 6 photos'), findsOneWidget);
    await _tapText(tester, 'Save to Files or share…');
    expect(shared.single.path, 'navmaas-backup-2026-10-05.navmaas');
    await _tapText(tester, 'Done');
    expect(find.text('Create encrypted backup'), findsOneWidget);
  });

  testWidgets('restore: wrong password, then replace and restore', (
    tester,
  ) async {
    final backup = FakeBackupService();
    await pumpApp(
      tester,
      seed: _seed,
      backup: backup,
      pickFile: (_) async => (
        name: 'navmaas-backup-2026-10-03.navmaas',
        bytes: Stream.value(utf8.encode('…')),
      ),
    );
    await _openBackup(tester);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Choose backup file');
    expect(
      find.text('Made Sat 3 Oct, 9:12 pm · 2.4 MB · Navmaas 1.0.0'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Restoring replaces everything on this phone with the backup. Make '
        "a fresh backup first if you're unsure.",
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'wrong horse');
    await _tapText(tester, 'Replace data and restore');
    expect(
      find.text('That password doesn’t open this backup.'),
      findsOneWidget,
    );
    expect(backup.restores, 0);

    await tester.enterText(find.byType(TextField), 'correct horse');
    await _tapText(tester, 'Replace data and restore');
    expect(backup.restores, 1);
    expect(find.text('Restored from Sat 3 Oct'), findsOneWidget);
    expect(
      find.text(
        '1,284 entries and 6 photos are back. Reminders have been planned '
        'again.',
      ),
      findsOneWidget,
    );
    await _tapText(tester, 'Done');
    expect(find.text("Today's gentle plan"), findsOneWidget);
  });

  testWidgets('a new phone restores from onboarding', (tester) async {
    final db = await pumpApp(
      tester,
      pickFile: (_) async => (name: 'b.navmaas', bytes: Stream.value([1])),
    );
    await tester.tap(find.text('Restore from a backup'));
    await tester.pumpAndSettle();
    // Opens on Restore.
    expect(find.text('Choose backup file'), findsOneWidget);
    await _tapText(tester, 'Choose backup file');
    await tester.enterText(find.byType(TextField), 'correct horse');
    await _tapText(tester, 'Replace data and restore');
    expect(find.text('Restored from Sat 3 Oct'), findsOneWidget);
    // The restored data has a pregnancy: Done goes to Today.
    await tester.runAsync(() => _seed(db));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Done');
    expect(find.text("Today's gentle plan"), findsOneWidget);
  });

  testWidgets('the weekly reminder day can change or switch off', (
    tester,
  ) async {
    final db = await pumpApp(tester, seed: _seed);
    await _openBackup(tester);
    expect(find.text('Sunday'), findsOneWidget);
    await _tapText(tester, 'Remind me weekly');
    await tester.tap(find.text('Off').last);
    await tester.pumpAndSettle();
    expect(find.text('Weekly reminder is off'), findsOneWidget);
    final day = await tester.runAsync(
      () => SettingsRepository(db).watch(SettingKeys.backupDay).first,
    );
    expect(day, '0');
  });

  testWidgets('the quiet page keeps Backup & restore', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await _seed(db);
        final p = await db.select(db.pregnancies).getSingle();
        await PregnancyRepository(db).setStatus(p.id, PregnancyStatus.paused);
      },
    );
    expect(find.text('Tracking is paused'), findsOneWidget);
    await tester.tap(find.text('Backup & restore'));
    await tester.pumpAndSettle();
    expect(find.text('Create encrypted backup'), findsOneWidget);
  });

  testWidgets('a book restored without its file asks to re-import it', (
    tester,
  ) async {
    final library = Directory.systemTemp.createTempSync('navmaas_reimport');
    await pumpApp(
      tester,
      library: library,
      seed: (db) async {
        await _seed(db);
        // Listed, but its file isn't on this phone.
        await db
            .into(db.libraryItems)
            .insert(
              LibraryItemsCompanion.insert(
                kind: LibraryKind.text,
                title: 'Evening stories',
                fileName: 'gone.txt',
              ),
            );
      },
      pickFile: (_) async => (
        name: 'evening_stories.txt',
        bytes: Stream.value(utf8.encode('# Back again\n\nOnce upon a time.')),
      ),
    );
    await _tab(tester, 'Sessions');
    await _tapText(tester, 'Evening stories');
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text("This file isn't on this phone"), findsOneWidget);
    await tester.tap(find.text('Re-import file'));
    // The copy and the reader's file read are real I/O.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(
      File('${library.path}/gone.txt').readAsStringSync(),
      startsWith('# Back again'),
    );
    expect(find.text('Once upon a time.'), findsOneWidget);
  });
}
