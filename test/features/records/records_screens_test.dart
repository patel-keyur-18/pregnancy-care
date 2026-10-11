import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/records/data/records_repository.dart';

import '../../helpers.dart';

/// A valid 1 × 1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwAD'
  'hgGAWjR9awAAAABJRU5ErkJggg==',
);

Future<void> _seedPregnancy(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

/// A pregnancy with a report and a scan sealed into [dir].
Future<void> Function(AppDatabase) _seedRecords(Directory dir) => (db) async {
  await _seedPregnancy(db);
  final pid = (await db.select(db.pregnancies).getSingle()).id;
  final repo = RecordsRepository(
    db,
    AttachmentStore(directory: dir, key: () async => List.filled(32, 7)),
  );
  await repo.add(
    pregnancyId: pid,
    bytes: _png,
    mimeType: 'image/png',
    category: RecordCategory.report,
    title: 'Thyroid report',
    takenOn: DateTime.utc(2026, 9, 9),
  );
  await repo.add(
    pregnancyId: pid,
    bytes: _png,
    mimeType: 'image/png',
    category: RecordCategory.scan,
    title: 'Week 20 anomaly scan',
    takenOn: DateTime.utc(2026, 9, 21),
  );
};

Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(NavmaasTabBar))).go(path);
  await _settleIo(tester);
}

void main() {
  testWidgets('Care shows Records; empty Records offers Add', (tester) async {
    await pumpApp(tester, seed: _seedPregnancy);
    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Care'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Records'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Records'));
    await tester.pumpAndSettle();
    expect(find.text('None yet'), findsOneWidget);
    await tester.tap(find.text('Records'));
    await _settleIo(tester);
    expect(find.text('No records yet'), findsOneWidget);
    expect(find.text('Add a record'), findsOneWidget);
    expect(find.text('Make visit summary'), findsOneWidget);
  });

  testWidgets('a photo is added with its details, encrypted', (tester) async {
    final dir = Directory.systemTemp.createTempSync('navmaas_rec');
    final db = await pumpApp(
      tester,
      seed: _seedPregnancy,
      records: dir,
      pickImage: ({required camera}) async => _png,
    );
    await _go(tester, '/care/records');
    await tester.tap(find.text('Add a record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a photo'));
    await _settleIo(tester);
    expect(find.text('Record details'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Title (optional)'),
      'Thyroid report',
    );
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await _settleIo(tester);
    expect(find.text('Thyroid report'), findsOneWidget);
    final row = await tester.runAsync(
      () => db.select(db.attachments).getSingle(),
    );
    expect(
      (row!.category, row.title, row.mimeType),
      (RecordCategory.report, 'Thyroid report', 'image/jpeg'),
    );
    expect(dir.listSync(), hasLength(1));
    expect(dir.listSync().single.path, isNot(endsWith('.png')));
  });

  testWidgets('a file over 25 MB is refused with a calm line', (tester) async {
    final dir = Directory.systemTemp.createTempSync('navmaas_rec');
    await pumpApp(
      tester,
      seed: _seedPregnancy,
      records: dir,
      pickFile: (_) async => (
        name: 'big.pdf',
        bytes: Stream<List<int>>.fromIterable([
          Uint8List(maxRecordBytes),
          Uint8List(1),
        ]),
      ),
    );
    await _go(tester, '/care/records');
    await tester.tap(find.text('Add a record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a file'));
    await _settleIo(tester);
    expect(find.text('Too large to keep here (25 MB at most)'), findsOneWidget);
    expect(find.text('Record details'), findsNothing);
    expect(dir.listSync(), isEmpty);
  });

  testWidgets('filter chips show one kind', (tester) async {
    final dir = Directory.systemTemp.createTempSync('navmaas_rec');
    await pumpApp(tester, seed: _seedRecords(dir), records: dir);
    await _go(tester, '/care/records');
    expect(find.text('Thyroid report'), findsOneWidget);
    expect(find.text('Week 20 anomaly scan'), findsOneWidget);
    await tester.tap(find.text('Scans'));
    await tester.pumpAndSettle();
    expect(find.text('Thyroid report'), findsNothing);
    expect(find.text('Week 20 anomaly scan'), findsOneWidget);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Thyroid report'), findsOneWidget);
  });
}
