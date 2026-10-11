# M9a Records vault and visit summary PDF — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Navmaas 1.7.0 adds two things:
- **Care → Records:** reports, scans, prescriptions and other files, encrypted on the phone, per pregnancy. Each can be viewed in memory, shared with a warning, or deleted.
- **A visit summary PDF:** the sections and dates she picks, values only, handed to the share sheet.

**Architecture:**
- **Schema v13** extends the existing `attachment` table: `pregnancy_id`, `category`, `title`, `taken_on` and `size_bytes`. Old prescription photos migrate to Prescriptions.
- **New feature folder** `lib/features/records/`:
  - `data/`: the records repository, pickers, the temporary share folder, and the summary loader.
  - `domain/`: the summary range, the content model and the PDF renderer.
  - `presentation/`: the screens.
- **The PDF:** `visitSummaryContent()` builds a plain `SummaryDoc`, then `renderSummaryPdf()` draws it with the `pdf` package and static Nunito fonts.
- **Sharing** reuses `shareFileProvider` (the backup's share sheet) through a temporary folder that is always emptied.

**Tech Stack:**
- Flutter, drift + SQLCipher, Riverpod 3 codegen, go_router, gen-l10n.
- `image_picker`, `file_picker`, `pdfrx` and `share_plus`, all existing.
- **New:** `pdf` 3.13.1 (owner-approved). It adds `barcode`, `bidi` and `qr` transitively; all are offline and pure Dart.

**Spec:** `docs/superpowers/specs/2026-10-11-m9-records-pdf-epub-design.md` §4 (and §6 for the approved boards). Prototype: https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8, section "Phase 2 · M9a Records and visit summary".

## Global Constraints

- **Branch, PR and version:**
  - Branch `feat/m9a-records-visit-summary` (already created; the spec commit is on it).
  - PR title `feat: records vault and visit summary PDF`.
  - Version `1.7.0+9` in `pubspec.yaml` and `appVersion` in `backup_service.dart`; a test checks they match.
- **No interpretation:**
  - Records and the PDF show values and her own words only. No ranges, colours, "high/low/normal", verdicts or advice.
  - Every word lives in `app_en.arb`, and the arb hard-line test covers the new prefixes `record`, `records` and `summary`.
  - "dose" is banned in those words, so the supplements column is headed "As prescribed".
- **Encryption:** record bytes are written only through `AttachmentStore.save` and decrypted only into memory.
  - The one plain copy is the share copy in `recordsTempDir`. It is deleted after the share sheet returns and swept at app start.
  - The PDF follows the same path.
- **Never** `DateTime.now()` in `lib/`. Use `clockNow()`, `todayProvider` / `nowProvider`, and the date helpers in `lib/core/utils/date_only.dart`.
- **Never** Material `Icons`, never hard-coded colours. Use `NavmaasIcon` / `NmIcon` and the theme (`context.navmaas.amberSoft` etc.). The PDF's own colours are the one exception: they're a printed page, defined once in `summary_pdf.dart`.
- **Accessibility:**
  - ≥ 48 dp targets.
  - A `Semantics(header: true)` heading on every screen, sheet and dialog.
  - No overflow at 1.0×, 1.3× and 2.0×.
  - Tooltips on icon-only buttons.
  - Reduce motion respected.
  - New screens are added to `test/accessibility_test.dart`.
- **Dialogs with text fields** own their controllers (create and dispose them in the dialog's `State`).
- **Drift transactions** read with `get…()`, never `watch().first`.
- **Records belong to the active pregnancy.** Never add per-screen status checks (CLAUDE.md "Tracking status").
- **After each task:**
  1. `dart format .`
  2. `flutter analyze` (zero issues)
  3. the task's tests
  4. commit (Conventional Commits, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`)
- **Docs** stay in sync in the same PR (Task 9).

## Review Focus

- **Removing a visit that has records.** Records stay in Care → Records, unlinked. Today's code deletes the visit's photos, and that must change (decision in this plan, recorded as Plan decision 79). Test in Task 2.
- **A file over 25 MB, or exactly 25 MB.** Over 25 MB is refused before anything is written to disk, and nothing is left behind. Exactly 25 MB (26 214 400 bytes) is accepted. Test in Task 2.
- **The app killed mid-share.** A plain copy left in `recordsTempDir` is deleted at the next app start. Test in Task 2 (the sweep function) and Task 4 (the share path deletes it).
- **Text the PDF font can't draw** (her name or a question in Hindi script, or an emoji). `renderSummaryPdf` still returns a valid PDF; it never throws. Test in Task 6.
- **"Since last visit" when her only visit is today or in the future.** It falls back to the whole pregnancy. Opened from a visit, it starts at the visit *before* that one, or the pregnancy start when there is none. Test in Task 5.

---

### Task 1: Schema v13: `attachment` becomes a record

**Files:**
- Modify: `lib/core/db/tables.dart` (the `Attachments` table and the new `RecordCategory` enum)
- Modify: `lib/core/db/app_database.dart` (`schemaVersion` 13, `from12To13`)
- Generated: `lib/core/db/app_database.drift.dart`, `lib/core/db/app_database.steps.dart`, `drift_schemas/navmaas/drift_schema_v13.json`, `test/drift/navmaas/generated/schema_v13.dart` and `schema.dart` (from `dart run build_runner build` and `dart run drift_dev make-migrations`)
- Test: `test/drift/navmaas/migration_test.dart`

**Interfaces:**
- Produces:
  - `enum RecordCategory { report, scan, prescription, other }` in `tables.dart`.
  - `Attachment` rows gain:
    - `String? pregnancyId`
    - `RecordCategory category`
    - `String title`
    - `DateTime? takenOn` (UTC midnight, `DateOnlyConverter`)
    - `int? sizeBytes`
  - `AttachmentsCompanion` gains the same fields.

- [ ] **Step 1: Write the failing migration test.** Add the import `import 'generated/schema_v12.dart' as v12;` after the v11 import (v12's snapshot already exists; v13's comes in Step 4). Then append:

```dart
  test('v12 → v13 turns visit photos into prescription records', () async {
    final schema = await verifier.schemaAt(12);
    final old = v12.DatabaseAtV12(schema.newConnection());
    const at = '2026-10-05T00:00:00.000';
    await old
        .into(old.pregnancy)
        .insert(
          v12.PregnancyCompanion.insert(
            id: 'p1',
            createdAt: at,
            updatedAt: at,
            status: 'active',
            datingMethod: 'lmp',
            startDate: '2026-04-15',
            dueDate: '2027-01-20',
          ),
        );
    await old
        .into(old.appointment)
        .insert(
          v12.AppointmentCompanion.insert(
            id: 'a1',
            createdAt: at,
            updatedAt: at,
            pregnancyId: 'p1',
            at: '2026-10-08T11:00:00.000',
          ),
        );
    await old
        .into(old.attachment)
        .insert(
          v12.AttachmentCompanion.insert(
            id: 'f1',
            createdAt: at,
            updatedAt: at,
            appointmentId: const Value('a1'),
            fileName: 'abc.bin',
            mimeType: 'image/jpeg',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 13);
    final r = await db.select(db.attachments).getSingle();
    expect(
      (r.pregnancyId, r.category, r.title, r.takenOn, r.sizeBytes),
      ('p1', RecordCategory.prescription, '', DateTime.utc(2026, 10, 8), null),
    );
    await db.close();
  });
```

- [ ] **Step 2: Change the table.** In `tables.dart`, replace the `Attachments` class:

```dart
/// What a record is (M9a). Words in `app_en.arb` (`recordKind*`).
enum RecordCategory { report, scan, prescription, other }

/// A record (M9a): a report, scan, prescription photo or other file, kept
/// encrypted in the private `db/attachments/` folder (ARCHITECTURE §13).
/// Belongs to a pregnancy; a visit link is optional.
@DataClassName('Attachment')
class Attachments extends Table with BaseColumns {
  @override
  String get tableName => 'attachment';

  TextColumn get appointmentId =>
      text().nullable().references(Appointments, #id)();

  /// File name inside `db/attachments/`.
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();

  /// v13. Nullable in SQL only; the app always sets it.
  TextColumn get pregnancyId =>
      text().nullable().references(Pregnancies, #id)();
  TextColumn get category => textEnum<RecordCategory>().withDefault(
    const Constant('other'),
  )();

  /// Her title; empty shows the category word.
  TextColumn get title => text().withDefault(const Constant(''))();

  /// The date on the record (defaults to the day it was added).
  TextColumn get takenOn =>
      text().map(const DateOnlyConverter()).nullable()();
  IntColumn get sizeBytes => integer().nullable()();
}
```

- [ ] **Step 3: Write the migration.** In `app_database.dart`, set `schemaVersion => 13` and add after `from11To12`:

```dart
      // v13 (M9a): records — a pregnancy, kind, title, date and size on each
      // attachment. Visit photos become prescriptions dated by their visit.
      from12To13: (m, schema) async {
        final a = schema.attachment;
        await m.addColumn(a, a.pregnancyId);
        await m.addColumn(a, a.category);
        await m.addColumn(a, a.title);
        await m.addColumn(a, a.takenOn);
        await m.addColumn(a, a.sizeBytes);
        await m.database.customStatement('''
          UPDATE attachment SET
            category = 'prescription',
            pregnancy_id = (SELECT pregnancy_id FROM appointment
                            WHERE appointment.id = attachment.appointment_id),
            taken_on = (SELECT substr(at, 1, 10) FROM appointment
                        WHERE appointment.id = attachment.appointment_id)
          WHERE appointment_id IS NOT NULL
        ''');
      },
```

- [ ] **Step 4: Generate the code.** Run `dart run build_runner build`, then `dart run drift_dev make-migrations`. `from12To13` won't compile until `app_database.steps.dart` is regenerated, so run build_runner once more if needed.

- [ ] **Step 5: Run the tests.** `flutter test test/drift/navmaas/migration_test.dart`. Expected: every version pair passes, including `v12 → v13 …`.

- [ ] **Step 6: Fix compile fallout.** `VisitRepository.addAttachment` keeps compiling, since the new columns have defaults or are nullable. Run `flutter analyze` and `flutter test test/core/db test/features/backup` and expect PASS.

- [ ] **Step 7: Commit.**

```bash
git add lib/core/db drift_schemas test/drift
git commit -m "feat(db): schema v13 records on the attachment table"
```

---

### Task 2: Records repository, pickers and the temporary share folder

**Files:**
- Create: `lib/features/records/data/records_repository.dart`
- Modify: `lib/features/care/data/visit_repository.dart` (remove the attachment methods; `removeAppointment` unlinks records)
- Modify: `lib/main.dart` (sweeps `recordsTempDir` at start)
- Modify: `test/helpers.dart` (`pumpApp` overrides for the attachment store, image picker and records temp folder)
- Test: `test/features/records/records_data_test.dart`

**Interfaces:**
- Consumes: `Attachment`, `RecordCategory` (Task 1); `AttachmentStore` (`lib/core/db/attachment_store.dart`); `PickFile` / `PickedFile` (`library_repository.dart`); `ShareFile` (`backup_service.dart`).
- Produces:
  - `const maxRecordBytes = 25 * 1024 * 1024;`
  - `class RecordTooLarge implements Exception {}`
  - `class RecordsRepository { new(AppDatabase db, AttachmentStore store); ... }` with these methods:
    - `Stream<List<Attachment>> watch(String pregnancyId)`, newest `takenOn` first
    - `Stream<List<Attachment>> watchForVisit(String appointmentId)`
    - `Future<List<Attachment>> inRange(String pregnancyId, DateTime from, DateTime to)`, date-only and inclusive
    - `Future<Uint8List> readCapped(Stream<List<int>> bytes)`, which throws `RecordTooLarge` past 25 MB
    - `Future<String> add({required String pregnancyId, required Uint8List bytes, required String mimeType, required RecordCategory category, required String title, required DateTime takenOn, String? appointmentId})`
    - `Future<void> updateDetails(String id, {required RecordCategory category, required String title, required DateTime takenOn})`
    - `Future<void> delete(Attachment a)`
    - `Future<Uint8List> bytes(Attachment a)`
  - `String mimeForName(String fileName)`: `pdf` gives `application/pdf`, `png` gives `image/png`, `heic` gives `image/heic`, anything else `image/jpeg`.
  - Providers:
    - `recordsRepositoryProvider` (`Future<RecordsRepository>`)
    - `recordsProvider` (`Stream<List<Attachment>>`, the active pregnancy)
    - `visitRecordsProvider(String appointmentId)`
    - `pickImageProvider` (`PickImage`)
    - `recordsTempDirProvider` (`Future<Directory>`)
  - `typedef PickImage = Future<Uint8List?> Function({required bool camera});`
  - `Future<void> clearRecordsTemp(Directory dir)`
  - `Future<void> shareRecordCopy({required Directory temp, required String name, required Uint8List bytes, required ShareFile share})`: writes, shares, and always deletes.

- [ ] **Step 1: Write the failing tests.** Create `test/features/records/records_data_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/records/data/records_repository.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late RecordsRepository repo;
  late String pid;

  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(64, 1)]);
  final pdf = Uint8List.fromList([...'%PDF-1.7'.codeUnits, ...List.filled(64, 2)]);

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('navmaas_rec');
    final store = AttachmentStore(
      directory: dir,
      key: () async => List.filled(32, 7),
    );
    repo = RecordsRepository(db, store);
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pid = (await db.select(db.pregnancies).getSingle()).id;
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<String> add(Uint8List bytes, {String mime = 'image/jpeg', String? visit}) =>
      repo.add(
        pregnancyId: pid,
        bytes: bytes,
        mimeType: mime,
        category: RecordCategory.report,
        title: 'Blood report',
        takenOn: DateTime.utc(2026, 10, 2),
        appointmentId: visit,
      );

  test('files on disk carry no image or PDF signature', () async {
    await add(jpeg);
    await add(pdf, mime: 'application/pdf');
    final files = dir.listSync().whereType<File>().toList();
    expect(files, hasLength(2));
    for (final f in files) {
      final head = f.readAsBytesSync().take(8).toList();
      expect(head.take(3), isNot([0xFF, 0xD8, 0xFF]));
      expect(String.fromCharCodes(head.take(4)), isNot('%PDF'));
      expect(String.fromCharCodes(head.skip(4).take(4)), isNot('ftyp'));
      expect(head.take(4), isNot([0x89, 0x50, 0x4E, 0x47]));
    }
  });

  test('a record reads back, with its size, kind, title and date', () async {
    await add(pdf, mime: 'application/pdf');
    final r = (await repo.watch(pid).first).single;
    expect(
      (r.category, r.title, r.takenOn, r.sizeBytes, r.mimeType),
      (RecordCategory.report, 'Blood report', DateTime.utc(2026, 10, 2),
          pdf.length, 'application/pdf'),
    );
    expect(await repo.bytes(r), pdf);
  });

  test('records belong to the pregnancy', () async {
    await add(jpeg);
    final other = await db.into(db.pregnancies).insertReturning(
      PregnanciesCompanion.insert(
        status: PregnancyStatus.active,
        datingMethod: .lmp,
        startDate: DateTime.utc(2027, 5, 1),
        dueDate: DateTime.utc(2028, 2, 5),
      ),
    );
    expect(await repo.watch(other.id).first, isEmpty);
  });

  test('25 MB is kept; one byte more is refused before anything is written',
      () async {
    final ok = await repo.readCapped(
      Stream.value(Uint8List(maxRecordBytes)),
    );
    expect(ok.length, maxRecordBytes);
    await expectLater(
      repo.readCapped(Stream.fromIterable([
        Uint8List(maxRecordBytes),
        Uint8List(1),
      ])),
      throwsA(isA<RecordTooLarge>()),
    );
    expect(dir.listSync(), isEmpty);
  });

  test('a date after today is kept as today', () async {
    await repo.add(
      pregnancyId: pid,
      bytes: jpeg,
      mimeType: 'image/jpeg',
      category: RecordCategory.scan,
      title: '',
      takenOn: DateTime.utc(2099, 1, 1),
    );
    final r = (await repo.watch(pid).first).single;
    expect(r.takenOn!.isAfter(DateTime.now().toUtc()), isFalse);
  });

  test('edit details, and delete removes the row and the file', () async {
    final id = await add(jpeg);
    await repo.updateDetails(
      id,
      category: RecordCategory.prescription,
      title: ' Iron tablets ',
      takenOn: DateTime.utc(2026, 9, 9),
    );
    var r = (await repo.watch(pid).first).single;
    expect((r.category, r.title), (RecordCategory.prescription, 'Iron tablets'));
    await repo.delete(r);
    expect(await repo.watch(pid).first, isEmpty);
    expect(dir.listSync(), isEmpty);
  });

  test('removing a visit keeps its records, unlinked', () async {
    final visits = VisitRepository(db);
    final visit = await visits.saveAppointment(
      pregnancyId: pid,
      at: DateTime(2026, 10, 8, 11),
    );
    await add(jpeg, visit: visit);
    await visits.removeAppointment(visit);
    final r = (await repo.watch(pid).first).single;
    expect(r.appointmentId, isNull);
    expect(dir.listSync(), hasLength(1));
  });

  test('inRange is inclusive at both ends', () async {
    await add(jpeg); // 2 Oct
    expect(
      await repo.inRange(pid, DateTime.utc(2026, 10, 2), DateTime.utc(2026, 10, 2)),
      hasLength(1),
    );
    expect(
      await repo.inRange(pid, DateTime.utc(2026, 10, 3), DateTime.utc(2026, 10, 9)),
      isEmpty,
    );
  });

  test('a shared copy is deleted after sharing, even when sharing fails',
      () async {
    final temp = Directory.systemTemp.createTempSync('navmaas_share');
    File? seen;
    await shareRecordCopy(
      temp: temp,
      name: 'Blood report.pdf',
      bytes: pdf,
      share: (f) async => seen = f,
    );
    expect(seen!.path, endsWith('Blood report.pdf'));
    expect(temp.listSync(), isEmpty);
    await expectLater(
      shareRecordCopy(
        temp: temp,
        name: 'x.pdf',
        bytes: pdf,
        share: (_) async => throw StateError('no share sheet'),
      ),
      throwsStateError,
    );
    expect(temp.listSync(), isEmpty);
  });

  test('clearRecordsTemp removes a copy left by a crash', () async {
    final temp = Directory.systemTemp.createTempSync('navmaas_share');
    File('${temp.path}/left.pdf').writeAsBytesSync(pdf);
    await clearRecordsTemp(temp);
    expect(temp.existsSync(), isFalse);
  });

  test('mime from a file name', () {
    expect(mimeForName('a.PDF'), 'application/pdf');
    expect(mimeForName('a.png'), 'image/png');
    expect(mimeForName('a.heic'), 'image/heic');
    expect(mimeForName('a.jpeg'), 'image/jpeg');
  });
}
```

- [ ] **Step 2: Run them and see them fail.** `flutter test test/features/records/records_data_test.dart` fails because `records_repository.dart` doesn't exist.

- [ ] **Step 3: Write the repository.** Create `lib/features/records/data/records_repository.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:image_picker/image_picker.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'records_repository.g.dart';

/// The largest file Navmaas keeps as a record (spec §4.2).
const maxRecordBytes = 25 * 1024 * 1024;

/// A picked file over [maxRecordBytes].
class RecordTooLarge implements Exception {}

/// Records (M9a): files sealed by [AttachmentStore], one row each in
/// `attachment`, per pregnancy. Bytes are decrypted only into memory.
class RecordsRepository {
  new(this._db, this._store);

  final AppDatabase _db;
  final AttachmentStore _store;

  Stream<List<Attachment>> watch(String pregnancyId) =>
      (_db.select(_db.attachments)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.takenOn),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .watch();

  Stream<List<Attachment>> watchForVisit(String appointmentId) =>
      (_db.select(_db.attachments)
            ..where(
              (t) =>
                  t.appointmentId.equals(appointmentId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Records dated [from]..[to] (UTC-midnight dates, both included).
  Future<List<Attachment>> inRange(
    String pregnancyId,
    DateTime from,
    DateTime to,
  ) {
    const c = DateOnlyConverter();
    return (_db.select(_db.attachments)
          ..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.takenOn.isBetweenValues(c.toSql(from), c.toSql(to)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.takenOn)]))
        .get();
  }

  /// Reads a picked file, refusing it as soon as it passes 25 MB.
  Future<Uint8List> readCapped(Stream<List<int>> bytes) async {
    final b = BytesBuilder(copy: false);
    await for (final chunk in bytes) {
      b.add(chunk);
      if (b.length > maxRecordBytes) throw RecordTooLarge();
    }
    return b.takeBytes();
  }

  Future<String> add({
    required String pregnancyId,
    required Uint8List bytes,
    required String mimeType,
    required RecordCategory category,
    required String title,
    required DateTime takenOn,
    String? appointmentId,
  }) async {
    final name = await _store.save(bytes);
    final row = await _db
        .into(_db.attachments)
        .insertReturning(
          AttachmentsCompanion.insert(
            fileName: name,
            mimeType: mimeType,
            pregnancyId: Value(pregnancyId),
            appointmentId: Value(appointmentId),
            category: Value(category),
            title: Value(title.trim()),
            takenOn: Value(_notAfterToday(takenOn)),
            sizeBytes: Value(bytes.length),
          ),
        );
    return row.id;
  }

  Future<void> updateDetails(
    String id, {
    required RecordCategory category,
    required String title,
    required DateTime takenOn,
  }) => (_db.update(_db.attachments)..where((t) => t.id.equals(id))).write(
    AttachmentsCompanion(
      category: Value(category),
      title: Value(title.trim()),
      takenOn: Value(_notAfterToday(takenOn)),
      updatedAt: Value(clockNow()),
    ),
  );

  Future<void> delete(Attachment a) async {
    final now = clockNow();
    await (_db.update(_db.attachments)..where((t) => t.id.equals(a.id))).write(
      AttachmentsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await _store.delete(a.fileName);
  }

  Future<Uint8List> bytes(Attachment a) => _store.read(a.fileName);

  static DateTime _notAfterToday(DateTime d) {
    final today = dateOnly(clockNow());
    return d.isAfter(today) ? today : d;
  }
}

String mimeForName(String fileName) =>
    switch (p.extension(fileName).toLowerCase()) {
      '.pdf' => 'application/pdf',
      '.png' => 'image/png',
      '.heic' => 'image/heic',
      _ => 'image/jpeg',
    };

/// Takes or chooses a photo, sized like visit photos were; faked in tests.
typedef PickImage = Future<Uint8List?> Function({required bool camera});

@riverpod
PickImage pickImage(Ref ref) => ({required camera}) async {
  final f = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 2400,
    imageQuality: 85,
  );
  return f?.readAsBytes();
};

/// Where a record or the visit summary waits for the share sheet, plain.
@riverpod
Future<Directory> recordsTempDir(Ref ref) async =>
    Directory(p.join((await getTemporaryDirectory()).path, 'navmaas-share'));

/// Deletes every plain copy in [dir] (app start).
Future<void> clearRecordsTemp(Directory dir) async {
  if (dir.existsSync()) await dir.delete(recursive: true);
}

/// Writes [bytes] as [name] in [temp], hands it to [share], and deletes it
/// whatever happens.
Future<void> shareRecordCopy({
  required Directory temp,
  required String name,
  required Uint8List bytes,
  required ShareFile share,
}) async {
  await temp.create(recursive: true);
  final file = File(p.join(temp.path, name.replaceAll(RegExp(r'[/\\:]'), '-')));
  try {
    await file.writeAsBytes(bytes, flush: true);
    await share(file);
  } finally {
    if (file.existsSync()) await file.delete();
  }
}

@riverpod
Future<RecordsRepository> recordsRepository(Ref ref) async => RecordsRepository(
  ref.watch(appDatabaseProvider),
  await ref.watch(attachmentStoreProvider.future),
);

/// Records of the active pregnancy, newest first.
@riverpod
Stream<List<Attachment>> records(Ref ref) async* {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) {
    yield const [];
    return;
  }
  final repo = await ref.watch(recordsRepositoryProvider.future);
  yield* repo.watch(id);
}

@riverpod
Stream<List<Attachment>> visitRecords(Ref ref, String appointmentId) async* {
  final repo = await ref.watch(recordsRepositoryProvider.future);
  yield* repo.watchForVisit(appointmentId);
}
```

- [ ] **Step 4: Update `VisitRepository`.**
  - Delete `watchAttachments`, `addAttachment`, `removeAttachment` and the `visitAttachments` provider, plus the `attachment_store.dart` import.
  - Replace `removeAppointment` so it unlinks records and questions inside one transaction:

```dart
  /// Removes a visit; its records stay in Records, unlinked (Plan 79).
  Future<void> removeAppointment(String id) => _db.transaction(() async {
    final now = clockNow();
    await (_db.update(_db.attachments)..where((t) => t.appointmentId.equals(id)))
        .write(AttachmentsCompanion(appointmentId: const Value(null), updatedAt: Value(now)));
    await (_db.update(_db.appointments)..where((t) => t.id.equals(id))).write(
      AppointmentsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  });
```

  - In `visit_screen.dart`, temporarily delete the attachment loop in `_remove` (lines ~142–146) and the `photos` / `_Photo` usage so it compiles. Task 4 rebuilds that section.

- [ ] **Step 5: Wire the app and tests.**
  - In `lib/main.dart`, after the voice sweep:

```dart
  // A plain share copy left by a crash goes now (M9a).
  unawaited(container.read(recordsTempDirProvider.future).then(clearRecordsTemp));
```

  - In `test/helpers.dart`, add three `pumpApp` parameters, `Directory? records`, `PickImage? pickImage` and `Directory? recordsTemp`, and these overrides:

```dart
        attachmentStoreProvider.overrideWith(
          (_) async => AttachmentStore(
            directory: records ?? Directory.systemTemp.createTempSync('navmaas_rec'),
            key: () async => List.filled(32, 7),
          ),
        ),
        pickImageProvider.overrideWithValue(pickImage ?? ({required camera}) async => null),
        recordsTempDirProvider.overrideWith(
          (_) async => recordsTemp ?? Directory.systemTemp.createTempSync('navmaas_st'),
        ),
```

- [ ] **Step 6: Generate and run.** `dart run build_runner build`, then `flutter test test/features/records test/features/care test/core/db` and expect PASS. `flutter analyze` should report zero issues.

- [ ] **Step 7: Commit.**

```bash
git add lib/features/records lib/features/care lib/main.dart test/helpers.dart test/features/records
git commit -m "feat(records): repository, pickers and plain-copy share folder"
```

---

### Task 3: Records screen, Care tile, Add flow and icons

**Files:**
- Modify: `lib/core/theme/navmaas_icons.dart`: new `folder`, `share` and `list` icons. SVG paths are copied from the approved boards (`Records.dc.html`, `RecordViewer.dc.html`, `Reader.dc.html`).
- Modify: `lib/l10n/app_en.arb`: the strings below.
- Create: `lib/features/records/presentation/records_screen.dart`, which holds `RecordsScreen`, `showAddRecord` and `RecordDetailsDialog`.
- Modify: `lib/features/care/presentation/care_screen.dart`: `_RecordsTile` under `_NutritionTile`.
- Modify: `lib/app/router.dart`: `/care/records`, `/care/records/view` and `/care/visit-summary`. The last starts as a placeholder `Scaffold` and Task 7 fills it.
- Modify: `test/core/content/content_pack_test.dart`: add the prefixes `record`, `records` and `summary` to the arb hard-line list.
- Test: `test/features/records/records_screens_test.dart`

**Interfaces:**
- Consumes: Task 2's providers and the `RecordsRepository` API.
- Produces:
  - `RecordsScreen` (route `/care/records`).
  - `Future<void> showAddRecord(BuildContext context, WidgetRef ref, {String? appointmentId, DateTime? visitDay})`, used again by the visit screen in Task 4.
  - `class RecordDetailsDialog extends StatefulWidget { new({this.record, required this.initialCategory, required this.initialDay}); }`. It pops `({RecordCategory category, String title, DateTime takenOn})?`.
  - `String recordLabel(AppLocalizations l10n, Attachment a)`: the title, or the category word when the title is empty.
  - `String recordKindWord(AppLocalizations l10n, RecordCategory c)`.
  - `NavmaasIcon.folder`, `.share` and `.list`.

- [ ] **Step 1: Add the strings to `app_en.arb`.** Keys only; each needs `@` metadata where it takes placeholders.

```json
  "recordsTitle": "Records",
  "recordsTileSub": "{count, plural, =0{None yet} =1{1 kept} other{{count} kept}}{latest, select, none{} other{ · latest: {latest}}}",
  "@recordsTileSub": {"placeholders": {"count": {"type": "int"}, "latest": {"type": "String"}}},
  "recordsEmptyTitle": "No records yet",
  "recordsEmptyBody": "Keep reports, scans and prescriptions together, encrypted on this phone.",
  "recordsPrivacy": "Kept encrypted on this phone. Navmaas doesn't read or interpret them.",
  "recordsAll": "All",
  "recordsFilterReport": "Reports",
  "recordsFilterScan": "Scans",
  "recordsFilterPrescription": "Prescriptions",
  "recordsFilterOther": "Other",
  "recordKindReport": "Report",
  "recordKindScan": "Scan",
  "recordKindPrescription": "Prescription",
  "recordKindOther": "Other",
  "recordAdd": "Add a record",
  "recordTakePhoto": "Take a photo",
  "recordChoosePhoto": "Choose a photo",
  "recordChooseFile": "Choose a file",
  "recordChooseFileSub": "A PDF or an image, up to 25 MB",
  "recordKeptEncrypted": "Kept encrypted on this phone.",
  "recordTooLarge": "Too large to keep here (25 MB at most)",
  "recordSaving": "Saving…",
  "recordDetails": "Record details",
  "recordTitleOptional": "Title (optional)",
  "recordKind": "Kind",
  "recordDate": "Date",
  "recordRowSub": "{kind} · {date} · {size}",
  "@recordRowSub": {"placeholders": {"kind": {"type": "String"}, "date": {"type": "String"}, "size": {"type": "String"}}},
  "recordFromVisit": "from the visit",
  "summaryMake": "Make visit summary",
```

- [ ] **Step 2: Write the failing widget tests.** Create `test/features/records/records_screens_test.dart`. Seed and pump like `test/features/nutrition/` tests do (`pumpApp(seed: …)` with `PregnancyRepository.saveDating`), then cover:

```dart
  testWidgets('Care shows Records; empty Records offers Add', (t) async {
    await pumpApp(t, seed: _seedPregnancy);
    await t.tap(find.text('Care'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Records'), 200);
    await t.ensureVisible(find.text('Records'));
    expect(find.text('None yet'), findsOneWidget);
    await t.tap(find.text('Records'));
    await t.pumpAndSettle();
    expect(find.text('No records yet'), findsOneWidget);
    expect(find.text('Add a record'), findsOneWidget);
    expect(find.text('Make visit summary'), findsOneWidget);
  });

  testWidgets('a photo is added with its details, encrypted', (t) async {
    final dir = Directory.systemTemp.createTempSync('navmaas_rec');
    final db = await pumpApp(
      t,
      seed: _seedPregnancy,
      records: dir,
      pickImage: ({required camera}) async => _png,
    );
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/care/records');
    await t.pumpAndSettle();
    await t.tap(find.text('Add a record'));
    await t.pumpAndSettle();
    await t.tap(find.text('Choose a photo'));
    await t.pumpAndSettle();
    expect(find.text('Record details'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Thyroid report');
    await t.tap(find.text('Report'));
    await t.tap(find.text('Save'));
    await _settleIo(t);
    expect(find.text('Thyroid report'), findsOneWidget);
    final row = await t.runAsync(() => db.select(db.attachments).getSingle());
    expect(row!.category, RecordCategory.report);
    expect(dir.listSync(), hasLength(1));
  });

  testWidgets('a file over 25 MB is refused with an amber line', (t) async {
    await pumpApp(
      t,
      seed: _seedPregnancy,
      pickFile: (_) async => (
        name: 'big.pdf',
        bytes: Stream.fromIterable([Uint8List(maxRecordBytes), Uint8List(1)]),
      ),
    );
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/care/records');
    await t.pumpAndSettle();
    await t.tap(find.text('Add a record'));
    await t.pumpAndSettle();
    await t.tap(find.text('Choose a file'));
    await _settleIo(t);
    expect(find.text('Too large to keep here (25 MB at most)'), findsOneWidget);
    expect(find.text('Record details'), findsNothing);
  });

  testWidgets('filter chips show one kind', (t) async { /* seed a report and a scan
      through RecordsRepository in seed (store from a temp dir), tap "Scans",
      expect only the scan's title */ });
```

The fourth test's body follows the same pattern. Seed two records with `RecordsRepository(db, AttachmentStore(directory: dir, key: () async => List.filled(32, 7)))`, pass the same `dir` as `records:`, tap the `Scans` chip, and expect the report's title `findsNothing`. Write it out in full.

Also add these to the test file:
- `_png`: a valid 1×1 PNG as a `Uint8List` constant (`base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')`).
- `_settleIo`, copied from `test/features/sessions/` (loops `t.runAsync(() => Future.delayed(10ms))` and `t.pump()` five times).

- [ ] **Step 3: Run them and see them fail.** `flutter test test/features/records/records_screens_test.dart` fails (no route, no tile).

- [ ] **Step 4: Add the icons.** Add to the `NavmaasIcon` enum, keeping the existing order and style:

```dart
  folder([
    'M3.5 7.5A2 2 0 0 1 5.5 5.5h4l2 2.5h7a2 2 0 0 1 2 2v7.5a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2z',
    'M3.5 11h17',
  ]),
  share([
    'M12 15V3.5M7.5 8 12 3.5 16.5 8',
    'M8 11H6.5A1.5 1.5 0 0 0 5 12.5v7A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5v-7a1.5 1.5 0 0 0-1.5-1.5H16',
  ]),
  list([
    'M9 6.5h11M9 12h11M9 17.5h11',
    'M4.5 5.6a.9.9 0 1 0 0 1.8a.9.9 0 1 0 0-1.8z',
    'M4.5 11.1a.9.9 0 1 0 0 1.8a.9.9 0 1 0 0-1.8z',
    'M4.5 16.6a.9.9 0 1 0 0 1.8a.9.9 0 1 0 0-1.8z',
  ]),
```

The prototype draws the list dots as zero-length strokes. Here they are small filled-circle paths, the same technique `more` uses. Note this in DESIGN_SYSTEM §8 in Task 9. If `test/core/icons_and_motion_test.dart` counts icons, update the count.

- [ ] **Step 5: Build `RecordsScreen`** in `records_screen.dart`, following the `Records.dc.html` board:
  - **Top:** an `AppBar`-less column (the same header style as `NutritionScreen`): back button with `l10n.backTooltip`, the overline `l10n.careOverline`, and `Semantics(header: true)` "Records".
  - **Make visit summary:** a full-width `OutlinedButton.icon(NmIcon(NavmaasIcon.birthPlan) … l10n.summaryMake)` that runs `context.push('/care/visit-summary')`. The board's icon is the birth-plan document glyph, so reuse `NavmaasIcon.birthPlan`.
  - **Empty:** a centred amber-soft 64-dp tile with `NavmaasIcon.folder`, the heading `recordsEmptyTitle`, and the body `recordsEmptyBody`.
  - **Filter:** chips `All · Reports · Scans · Prescriptions · Other`, as `ChoiceChip`s in a `Wrap`, held as a `RecordCategory?` in State (null means All).
  - **List:** grouped by `DateFormat('MMMM yyyy')` of `takenOn ?? createdAt`, each group a `Card`.
    - **Thumbnail:** "PDF" text on `primaryContainer` for `application/pdf`; otherwise `NmIcon(NavmaasIcon.scan)` on `surfaceContainerHighest`. Don't decrypt in the list, so it stays fast and nothing extra is decrypted.
    - **Title:** `recordLabel`.
    - **Subtitle:** `recordRowSub(kind, formatShortDate(takenOn), formatBytes(sizeBytes ?? 0))`, adding ` · ${recordFromVisit}` when `appointmentId != null`. `formatBytes` is in `backup_screen.dart`; move it to `lib/core/utils/format_bytes.dart` and update its importers.
    - **Tap:** `context.push('/care/records/view', extra: a.id)`.
  - **Footer:** a privacy line, then a full-width `FilledButton.icon(NmIcon(NavmaasIcon.plus) … recordAdd)` that calls `showAddRecord(context, ref)`.
- [ ] **Step 6: Write `showAddRecord`:**

```dart
Future<void> showAddRecord(
  BuildContext context,
  WidgetRef ref, {
  String? appointmentId,
  DateTime? visitDay,
}) async {
  final l10n = AppLocalizations.of(context);
  final source = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Semantics(
              header: true,
              child: Text(l10n.recordAdd, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          ListTile(
            leading: const NmIcon(NavmaasIcon.camera),
            title: Text(l10n.recordTakePhoto),
            onTap: () => Navigator.pop(context, 0),
          ),
          ListTile(
            leading: const NmIcon(NavmaasIcon.scan),
            title: Text(l10n.recordChoosePhoto),
            onTap: () => Navigator.pop(context, 1),
          ),
          ListTile(
            leading: const NmIcon(NavmaasIcon.notes),
            title: Text(l10n.recordChooseFile),
            subtitle: Text(l10n.recordChooseFileSub),
            onTap: () => Navigator.pop(context, 2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Text(l10n.recordKeptEncrypted),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  final repo = await ref.read(recordsRepositoryProvider.future);
  Uint8List? bytes;
  var mime = 'image/jpeg';
  try {
    if (source < 2) {
      bytes = await ref.read(pickImageProvider)(camera: source == 0);
    } else {
      final f = await ref.read(pickFileProvider)(const ['pdf', 'jpg', 'jpeg', 'png', 'heic']);
      if (f != null) {
        bytes = await repo.readCapped(f.bytes);
        mime = mimeForName(f.name);
      }
    }
  } on RecordTooLarge {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.navmaas.amberSoft,
          content: Text(
            l10n.recordTooLarge,
            style: TextStyle(color: context.navmaas.onAmberSoft),
          ),
        ),
      );
    }
    return;
  }
  if (bytes == null || !context.mounted) return;
  final details = await showDialog<RecordDetailsResult>(
    context: context,
    builder: (_) => RecordDetailsDialog(
      initialCategory: appointmentId == null ? RecordCategory.other : RecordCategory.prescription,
      initialDay: visitDay ?? ref.read(todayProvider),
    ),
  );
  if (details == null || !context.mounted) return;
  final pregnancyId = ref.read(activePregnancyProvider).value?.id;
  if (pregnancyId == null) return;
  // Encrypting a large PDF takes a moment in pure Dart: show it.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SavingDialog(label: l10n.recordSaving),
  ));
  try {
    await repo.add(
      pregnancyId: pregnancyId,
      bytes: bytes,
      mimeType: mime,
      category: details.category,
      title: details.title,
      takenOn: details.takenOn,
      appointmentId: appointmentId,
    );
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

typedef RecordDetailsResult = ({RecordCategory category, String title, DateTime takenOn});
```

  - `_SavingDialog` is an `AlertDialog` with `Semantics(header: true, child: Text(label))` and a `CircularProgressIndicator`. Under reduce motion, use `value: null` all the same: it's a system indicator, as backup uses.
  - The file picker's extensions list `pdf, jpg, jpeg, png, heic`.
  - Check that `pickFileProvider` already exists with type `PickFile`; it does.
- [ ] **Step 7: Write `RecordDetailsDialog`** as a `StatefulWidget` that owns its `TextEditingController`:
  - Title field labelled `recordTitleOptional`.
  - A `Kind` radio row of four `ChoiceChip`s (`recordKind*` words).
  - A date row (`key: const ValueKey('date-field')` so the `pickDate` helper works) that opens `showDatePicker(firstDate: DateTime(2020), lastDate: localDay(clockNow()))`.
  - `Back` / `Save`.
  - Heading `recordDetails` in `Semantics(header: true)`.
  - Save pops `(category: …, title: controller.text, takenOn: dateOnly(picked))`.
- [ ] **Step 8: Add the Care tile.** Add `_RecordsTile` under `_NutritionTile` with `SizedBox(height: 10)` between them. It uses `NavmaasIcon.folder` on `context.navmaas.amberSoft` / `onAmberSoft`, label `recordsTitle`, and subtitle `recordsTileSub(list.length, list.isEmpty ? 'none' : '${recordLabel(l10n, list.first)}, ${DateFormat('d MMM').format(list.first.takenOn!)}')`. Tapping it runs `context.go('/care/records')`.
- [ ] **Step 9: Add the routes** under the `/care` branch:

```dart
              GoRoute(
                path: 'records',
                builder: (_, _) => const RecordsScreen(),
                routes: [
                  GoRoute(
                    path: 'view',
                    builder: (_, state) => RecordScreen(recordId: state.extra! as String),
                  ),
                ],
              ),
              GoRoute(
                path: 'visit-summary',
                builder: (_, state) => VisitSummaryScreen(visitId: state.extra as String?),
              ),
```

Until Tasks 4 and 7 exist, `RecordScreen` and `VisitSummaryScreen` are minimal classes: a `Scaffold` with a `Semantics(header: true)` title, created in `record_screen.dart` and `visit_summary_screen.dart`.

- [ ] **Step 10: Add the content-test prefixes.** Add `'record', 'records', 'summary'` to the prefix list in `test/core/content/content_pack_test.dart` (the "hard lines: no advice, warning…" test).
- [ ] **Step 11: Run the tests.** `flutter test test/features/records test/core test/features/care` and expect PASS. `flutter analyze` should report zero issues.
- [ ] **Step 12: Commit.**

```bash
git add lib test
git commit -m "feat(records): Care → Records with add, filter and the Care tile"
```

---

### Task 4: Record viewer, share warning, delete, and the visit's records

**Files:**
- Create or fill: `lib/features/records/presentation/record_screen.dart`
- Modify: `lib/features/care/presentation/visit_screen.dart`: the "After the visit" row loses Prescription; add "Records from this visit" and "Make visit summary"; delete `_addPhoto` and `_Photo`.
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/records/records_screens_test.dart` (append)

**Interfaces:**
- Consumes: `recordsProvider`, `visitRecordsProvider`, `recordsRepositoryProvider`, `shareRecordCopy`, `recordsTempDirProvider`, `shareFileProvider`, `showAddRecord`, `RecordDetailsDialog` and `recordLabel`.
- Produces:
  - `RecordScreen({required String recordId})`.
  - The visit screen's records section.
  - `String recordShareName(AppLocalizations l10n, Attachment a)`: `'<label>.<pdf|jpg|png|heic>'`.

- [ ] **Step 1: Add the strings.**

```json
  "recordMoreTooltip": "More for this record",
  "recordEdit": "Edit details",
  "recordEditSub": "Title, kind and date",
  "recordShare": "Share a copy",
  "recordShareSub": "With your doctor, or to print",
  "recordDelete": "Delete record",
  "recordShareTitle": "Share a copy?",
  "recordShareBody": "The shared copy isn't encrypted. Navmaas deletes its own copy after sharing; the app you share with keeps what it receives.",
  "recordShareButton": "Share",
  "recordDeleteTitle": "Delete this record?",
  "recordDeleteBody": "It's removed from this phone. Backups you made earlier still have it.",
  "recordDeleteButton": "Delete",
  "recordViewerNote": "Kept encrypted. Opened only on this screen, never saved as a plain copy.",
  "recordCantOpen": "This record couldn't be opened on this phone.",
  "recordPinch": "Pinch to zoom",
  "visitRecords": "Records from this visit",
  "visitAllRecords": "All records",
  "visitAddRecord": "Add",
```

Change `removeVisitNote` to: "This removes the visit and its notes. Its records stay in Care → Records, and questions you haven't asked stay for your next visit."

- [ ] **Step 2: Write the failing tests.** Seed one image record (the `_png` bytes through `RecordsRepository` in `seed`, with the same `records:` dir passed to `pumpApp`), and pass `share: (f) async => shared.add(f.path)` plus `recordsTemp: temp`. Then:

```dart
  testWidgets('a photo record opens, shares after the warning, and leaves no copy', (t) async {
    final shared = <String>[];
    final temp = Directory.systemTemp.createTempSync('navmaas_st');
    await pumpApp(t, seed: _seedRecord(dir), records: dir, recordsTemp: temp,
        share: (f) async => shared.add(f.path));
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/care/records');
    await t.pumpAndSettle();
    await t.tap(find.text('Thyroid report'));
    await _settleIo(t);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await t.tap(find.byTooltip('More for this record'));
    await t.pumpAndSettle();
    await t.tap(find.text('Share a copy'));
    await t.pumpAndSettle();
    expect(find.text('Share a copy?'), findsOneWidget);
    await t.tap(find.text('Share'));
    await _settleIo(t);
    expect(shared.single, endsWith('Thyroid report.png'));
    expect(temp.listSync(), isEmpty);
  });

  testWidgets('delete asks first, then removes the record', (t) async {
    // open the record, ⋯ → Delete record → dialog "Delete this record?" → Delete
    // → back on Records, which shows "No records yet"; dir is empty.
  });

  testWidgets('a visit lists its records and adds one as a prescription', (t) async {
    // seed a visit; pumpApp(pickImage: …_png); go('/care/visit', extra: visitId);
    // scroll to "Records from this visit"; tap Add → Choose a photo → the details
    // dialog shows Prescription selected → Save; the visit shows the record;
    // the row's appointmentId is the visit; "Make visit summary" is present.
  });
```

Write the two commented bodies out in full in the test file, following the first test's calls.

- [ ] **Step 3: Run them and see them fail.**

- [ ] **Step 4: Build `RecordScreen`.**
  - **Data:** a `ConsumerStatefulWidget`. In `initState` it reads the row (`recordsProvider` value, matched by id) and the bytes with `repo.bytes(a)` into a `Future<Uint8List>` field. The bytes are only in memory.
  - **Header:** the same as the board.
    - A back `IconButton` with a tooltip.
    - A centred `Semantics(header: true)` label with the subtitle `'${recordKindWord} · ${formatShortDate(takenOn)}'`.
    - `IconButton(tooltip: l10n.recordMoreTooltip, icon: NmIcon(NavmaasIcon.more))`.
  - **Body**, on `surfaceContainerHighest`:
    - **Images:** `InteractiveViewer(child: Image.memory(bytes, errorBuilder: (_, _, _) => Text(l10n.recordCantOpen)))`, plus "Pinch to zoom".
    - **PDFs:** `PdfViewer.data(bytes, sourceName: a.id)`. Not run in widget tests, since pdfium isn't available there; it's checked on the phone (Task 9 checklist).
    - **Decrypt failure:** `recordCantOpen`.
  - **Footer note:** `recordViewerNote`.
  - **⋯ sheet:**
    - A heading, then Edit details, Share a copy, and Delete record (`scheme.error` text and icon).
    - **Edit** opens `RecordDetailsDialog(record: a, initialCategory: a.category, initialDay: a.takenOn!)`, then `repo.updateDetails`.
    - **Share** opens an `AlertDialog` (heading `recordShareTitle`), then:
      ```dart
      await shareRecordCopy(
        temp: await ref.read(recordsTempDirProvider.future),
        name: recordShareName(l10n, a),
        bytes: await bytesFuture,
        share: ref.read(shareFileProvider),
      );
      ```
    - **Delete** opens an `AlertDialog` whose red `FilledButton` follows `_remove` in `visit_screen.dart`, then `repo.delete(a)` and `context.pop()`.
- [ ] **Step 5: Change the visit screen.**
  - The `_AfterTile` row keeps Notes and Next visit only.
  - Add a header row: `heading(l10n.visitRecords)` plus a `TextButton(l10n.visitAllRecords)` that runs `context.go('/care/records')`.
  - Add a `Wrap` of 96-dp tiles for `ref.watch(visitRecordsProvider(visit.id))`:
    - an image tile shows `NmIcon(NavmaasIcon.scan)` and the label;
    - a PDF tile shows "PDF" on `primaryContainer`;
    - each is a `Semantics(button: true, label: '${recordLabel} ${formatShortDate(takenOn)}')` and runs `context.push('/care/records/view', extra: a.id)`.
  - Then a dashed-border Add tile (`DottedBorder` isn't available; use `Border.all(color: outline, width: 1.5)` on a `Container`, and record the difference in DESIGN_SYSTEM §8) that calls `showAddRecord(context, ref, appointmentId: visit.id, visitDay: dateOnly(visit.at))`.
  - Then `OutlinedButton.icon(NavmaasIcon.birthPlan, l10n.summaryMake)` that runs `context.push('/care/visit-summary', extra: visit.id)`.
  - In `_remove`, drop the attachment deletion: `removeAppointment` now unlinks.
- [ ] **Step 6: Run the tests.** `flutter test test/features/records test/features/care` and expect PASS. `flutter analyze` should report zero issues.
- [ ] **Step 7: Commit.**

```bash
git add lib test
git commit -m "feat(records): viewer, share a copy, delete, and records on a visit"
```

---

### Task 5: Visit summary data, range and content model

**Files:**
- Create: `lib/features/records/domain/visit_summary.dart`: range, sections and `SummaryDoc`.
- Create: `lib/features/records/data/summary_data.dart`: the loader.
- Modify: `lib/core/db/settings_repository.dart`: `SettingKeys.summarySections` and its provider.
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/records/visit_summary_test.dart`

**Interfaces:**
- Consumes: the tables; `PregnancySnapshot`; `mostActiveWindow` (`third_trimester/domain/patterns.dart`); `RecordsRepository.inRange`; `BirthPlanPrompt` (`content_pack.dart`); `WellbeingWords` (`lib/features/wellbeing/…`; check its exact API with `grep -rn "class WellbeingWords" lib`).
- Produces:

```dart
enum SummarySection { pregnancy, supplements, vitals, questions, kicks, records, wellbeing, birthPlan }
const defaultSummarySections = {
  SummarySection.pregnancy, SummarySection.supplements, SummarySection.vitals,
  SummarySection.questions, SummarySection.kicks, SummarySection.records,
};
enum SummaryRangeChoice { sinceLastVisit, lastFourWeeks, wholePregnancy, custom }
typedef SummaryRange = ({DateTime from, DateTime to}); // UTC-midnight dates, both included

SummaryRange summaryRange(
  SummaryRangeChoice choice, {
  required DateTime today,          // dateOnly
  required DateTime pregnancyStart, // dateOnly
  required List<DateTime> visitDays, // dateOnly, any order
  DateTime? fromVisitDay,           // opened from a visit: that visit's day
  SummaryRange? custom,
});

typedef SummaryTable = ({List<String> header, List<List<String>> rows});
typedef SummaryBlock = ({String heading, List<String> lines, SummaryTable? table});
typedef SummaryDoc = ({String title, String subtitle, String? forLine, List<SummaryBlock> blocks, String footer});

typedef SummaryData = ({
  String? name,
  Pregnancy pregnancy,
  Profile? profile,
  List<({String name, String asPrescribed, int daysTaken})> supplements,
  List<VitalReading> vitals,
  List<String> questions,
  List<KickSession> kicks,
  List<Contraction> contractions,
  List<Attachment> records,
  List<MoodEntry> moods,
  List<SymptomEntry> symptoms,
  List<SleepLog> sleep,
  List<WaterLog> water,
  List<({String prompt, String answer})> birthPlan,
});

SummaryDoc visitSummaryContent(
  SummaryData data, SummaryRange range, Set<SummarySection> sections, {
  required AppLocalizations l10n, required DateTime today,
});

Future<SummaryData> loadSummaryData(
  AppDatabase db, {
  required String pregnancyId, required SummaryRange range,
  String? visitId, required List<BirthPlanPrompt> prompts,
});

Set<SummarySection> parseSummarySections(String? stored); // null → defaults
String storeSummarySections(Set<SummarySection> s);       // comma-separated names
```

- [ ] **Step 1: Add the strings.** These cover the PDF's words and the summary screen's words. "dose" is banned, so the column reads "As prescribed".

```json
  "summaryTitle": "Visit summary",
  "summaryIntro": "A PDF of what you logged, to share with your doctor. Values only, as you entered them.",
  "summaryDates": "Dates",
  "summarySinceLastVisit": "Since last visit",
  "summaryLastFourWeeks": "Last 4 weeks",
  "summaryWholePregnancy": "Whole pregnancy",
  "summaryCustom": "Custom",
  "summaryInclude": "Include",
  "summarySectionPregnancy": "Pregnancy summary",
  "summarySectionPregnancySub": "Due date, week today, your doctor",
  "summarySectionSupplements": "Supplements",
  "summarySectionSupplementsSub": "What you take, and days marked taken",
  "summarySectionVitals": "Vitals",
  "summarySectionVitalsSub": "Weight, blood pressure, blood sugar",
  "summarySectionQuestions": "Questions",
  "summarySectionQuestionsSub": "The ones you want to ask",
  "summarySectionKicks": "Kicks and contractions",
  "summarySectionKicksSub": "Sessions and timings you logged",
  "summarySectionRecords": "Records",
  "summarySectionRecordsSub": "Titles and dates only; files stay here",
  "summarySectionWellbeing": "Wellbeing",
  "summarySectionWellbeingSub": "Mood, symptoms, sleep and water",
  "summarySectionBirthPlan": "Birth plan",
  "summarySectionBirthPlanSub": "Your answers, in your words",
  "summaryMakePdf": "Make PDF and share",
  "summaryPdfNote": "The PDF isn't encrypted. Navmaas deletes its copy after sharing.",
  "summaryNothing": "Nothing logged in this range",
  "summaryRangeLine": "{from} – {to}",
  "@summaryRangeLine": {"placeholders": {"from": {"type": "String"}, "to": {"type": "String"}}},
  "summaryForLine": "For {doctor}",
  "@summaryForLine": {"placeholders": {"doctor": {"type": "String"}}},
  "summaryDueDate": "Due date",
  "summaryToday": "Today",
  "summaryWeekDay": "Week {week}, day {day}",
  "@summaryWeekDay": {"placeholders": {"week": {"type": "int"}, "day": {"type": "int"}}},
  "summaryDatedBy": "Dated by",
  "summaryDoctor": "Doctor",
  "summaryName": "Name",
  "summaryAsPrescribed": "As prescribed",
  "summaryMarkedTaken": "Marked taken",
  "summaryDaysOf": "{n} of {m} days",
  "@summaryDaysOf": {"placeholders": {"n": {"type": "int"}, "m": {"type": "int"}}},
  "summaryDate": "Date",
  "summaryKind": "Kind",
  "summaryTitleColumn": "Title",
  "summaryKickLine": "Kick sessions: {count}{window, select, none{} other{ · most movement {window}}}",
  "@summaryKickLine": {"placeholders": {"count": {"type": "int"}, "window": {"type": "String"}}},
  "summaryContractionLine": "Contractions timed: {count}{avg, select, none{} other{ · average length {avg}}}",
  "@summaryContractionLine": {"placeholders": {"count": {"type": "int"}, "avg": {"type": "String"}}},
  "summaryFooter": "Made with Navmaas on {date} · values as she logged them",
  "@summaryFooter": {"placeholders": {"date": {"type": "String"}}},
  "summaryPage": "Page {n} of {m}",
  "@summaryPage": {"placeholders": {"n": {"type": "int"}, "m": {"type": "int"}}},
```

- [ ] **Step 2: Write the failing unit tests** in `test/features/records/visit_summary_test.dart`. Use `AppLocalizationsEn()` (as `planner_test.dart` does) and build `SummaryData` directly:

```dart
  final l10n = AppLocalizationsEn();
  final today = DateTime.utc(2026, 10, 5);
  final start = DateTime.utc(2026, 4, 4);

  group('range', () {
    test('since last visit: the latest past visit to today', () {
      final r = summaryRange(.sinceLastVisit, today: today, pregnancyStart: start,
          visitDays: [DateTime.utc(2026, 8, 20), DateTime.utc(2026, 9, 17), DateTime.utc(2026, 10, 8)]);
      expect(r, (from: DateTime.utc(2026, 9, 17), to: today));
    });
    test('since last visit with only today or future visits: whole pregnancy', () {
      final r = summaryRange(.sinceLastVisit, today: today, pregnancyStart: start,
          visitDays: [today, DateTime.utc(2026, 10, 8)]);
      expect(r, (from: start, to: today));
    });
    test('from a visit: the visit before it, else the pregnancy start', () {
      final days = [DateTime.utc(2026, 9, 17), DateTime.utc(2026, 10, 8)];
      expect(summaryRange(.sinceLastVisit, today: today, pregnancyStart: start,
          visitDays: days, fromVisitDay: DateTime.utc(2026, 10, 8)).from,
          DateTime.utc(2026, 9, 17));
      expect(summaryRange(.sinceLastVisit, today: today, pregnancyStart: start,
          visitDays: days, fromVisitDay: DateTime.utc(2026, 9, 17)).from, start);
    });
    test('last four weeks and whole pregnancy', () {
      expect(summaryRange(.lastFourWeeks, today: today, pregnancyStart: start, visitDays: const []).from,
          DateTime.utc(2026, 9, 7));
      expect(summaryRange(.wholePregnancy, today: today, pregnancyStart: start, visitDays: const []).from, start);
    });
  });

  group('content', () {
    test('only the chosen sections, in order, each with a heading', () {
      final doc = visitSummaryContent(_data(), _range, {SummarySection.vitals, SummarySection.pregnancy},
          l10n: l10n, today: today);
      expect(doc.blocks.map((b) => b.heading), ['Pregnancy summary', 'Vitals']);
    });
    test('an empty section says so instead of disappearing', () {
      final doc = visitSummaryContent(_data(vitals: const []), _range, {SummarySection.vitals},
          l10n: l10n, today: today);
      expect(doc.blocks.single.lines, ['Nothing logged in this range']);
    });
    test('vitals are values with units and context, never judged', () {
      final doc = visitSummaryContent(_data(), _range, {SummarySection.vitals}, l10n: l10n, today: today);
      final cells = doc.blocks.single.table!.rows.expand((r) => r).join(' ');
      expect(cells, contains('61.2 kg'));
      expect(cells, contains('112/72 mmHg'));
      expect(cells, contains('96 mg/dL · Fasting'));
    });
    test('the words the summary adds pass the hard-line check', () {
      final doc = visitSummaryContent(_data(), _range, SummarySection.values.toSet(),
          l10n: l10n, today: today);
      final text = [doc.title, doc.subtitle, doc.forLine ?? '', doc.footer,
        for (final b in doc.blocks) ...[b.heading, ...b.lines,
          ...?b.table?.header, ...?b.table?.rows.expand((r) => r)]]
          .join('\n').replaceAll('mg/dL', '');
      expect(_forbidden.allMatches(text).map((m) => m[0]), isEmpty);
    });
  });
```

  - `_forbidden` is the same `RegExp` literal as the arb test in `content_pack_test.dart`; copy it with a comment pointing there.
  - `_data({…})` returns a full `SummaryData` built from row-class constructors such as `VitalReading(id: 'v1', createdAt: …, …)`. Every field must be filled with neutral values: name `Meera`, questions without judgement words, symptom `backache` / `mild`.
  - `_range` is `(from: DateTime.utc(2026, 9, 17), to: today)`.
  - A **loader test** seeds an in-memory DB with:
    - one supplement plus a schedule, with two taken doses inside the range and one outside;
    - one vital inside the range and one outside;
    - an unasked question, plus a question asked at another visit.
  - It asserts `loadSummaryData` returns:
    - `daysTaken == 2`;
    - one vital;
    - only the unasked question, plus questions linked to `visitId`.

- [ ] **Step 3: Run them and see them fail.**

- [ ] **Step 4: Implement `visit_summary.dart`.**
  - **`summaryRange`:**
    - `sinceLastVisit`:
      ```dart
      final before = fromVisitDay ?? today;
      final past = visitDays.where((d) => d.isBefore(before)).toList()..sort();
      final from = past.isEmpty ? pregnancyStart : past.last;
      ```
    - `lastFourWeeks`: `addDays(today, -28)`, clamped so it's never before `pregnancyStart`.
    - `wholePregnancy`: `pregnancyStart`.
    - `custom`: `custom!`.
    - `to` is always `today` except for custom.
  - **`visitSummaryContent`:** walk `SummarySection.values` in order, skipping the unchosen ones:
    - **pregnancy:** table rows Name, Due date (`formatDate(pregnancy.dueDate)` plus `l10n.datedBy(method.name)`), Today (`summaryWeekDay` from `PregnancySnapshot.of(start: pregnancy.startDate, today: today)`), and Doctor (`doctorName · clinicName`, when set). `forLine` is `summaryForLine(doctor)` when the doctor is set.
    - **supplements:** header `[summaryName, summaryAsPrescribed, summaryMarkedTaken]`; each row is `[name, asPrescribed, summaryDaysOf(daysTaken, daysBetween(range.from, range.to) + 1)]`.
    - **vitals:** header `[summaryDate, weight, bloodPressure, bloodSugar]` (existing arb keys). Group readings by local day, newest first. Cells are `'${v.value1.toStringAsFixed(1)} kg'`, `'${v1}/${v2} mmHg'` and `'${v1.round()} mg/dL · ${bloodSugarContextWord}, ${time}'`, or `—` when absent.
    - **questions:** `'• $q'` lines.
    - **kicks:**
      - `summaryKickLine(kicks.length, window)`. `window` comes from `mostActiveWindow(kicks)`, formatted as `'${formatMinuteOfDay(w*60)}–${formatMinuteOfDay((w+2)*60)}'`, or `none`.
      - `summaryContractionLine(contractions.length, avg)`. The average length is `'${m} min ${s} s'`, or `none`.
    - **records:** header `[summaryDate, summaryKind, summaryTitleColumn]`, rows from `records`.
    - **wellbeing:** lines per day, newest first, as `'${formatShortDate(day)}: ${mood word}; ${symptoms "Backache (mild)"}; sleep ${h} h ${m} min; water ${glasses}'`. Every word comes from the existing `WellbeingWords` / arb keys.
    - **birthPlan:** for each answer, the prompt as a line in bold, then the answer. The renderer bolds any line that starts with `## `, so encode prompts as `'## ${prompt}'`.
    - When a section has no data, its lines are `[summaryNothing]` and `table` is null.
    - `title` is `summaryTitle`; `subtitle` is `'${name ?? ''} · ${summaryRangeLine(formatShortDate(from), formatDate(to))}'` with leading separators trimmed; `footer` is `summaryFooter(formatDate(today))`.
  - **`parseSummarySections` / `storeSummarySections`:** comma-separated `SummarySection.name`s. Unknown names are ignored. An empty stored string means an empty set; `null` means the defaults.
- [ ] **Step 5: Implement `summary_data.dart`.** Each query uses `get()` and filters `deletedAt.isNull()` with the active `pregnancyId`.
  - **Range as local DateTimes:** `from = DateTime(range.from.year, range.from.month, range.from.day)` to `toEnd = DateTime(to.year, to.month, to.day + 1)`.
  - **supplements:** a join of `supplements` → `supplement_schedule` → `dose_log` with `status = taken` and `dueAt` in [from, toEnd).
    - Count distinct local days per supplement.
    - `asPrescribed` is `doseText`, and when there are schedules it adds `' · ' + labels/times joined by ', '` (`label ?? formatMinuteOfDay(minuteOfDay)`).
    - Supplements with no taken dose still appear, with 0.
  - **vitals:** `at` in [from, toEnd), newest first.
  - **questions:** `askedAt IS NULL` OR `appointmentId = visitId`.
  - **kicks and contractions:** `startedAt` in [from, toEnd).
  - **records:** `RecordsRepository.inRange` logic as a direct query, so there's no store dependency.
  - **moods, sleep and water:** `day BETWEEN from AND to` (date strings).
  - **symptoms:** `loggedAt` in [from, toEnd).
  - **birthPlan:** each prompt joined with `birth_plan_answer` for the pregnancy, keeping only non-empty answers.
  - **name:** `SettingKeys.firstName`.
  - **profile:** the single `profile` row.
- [ ] **Step 6: Add the setting.** In `SettingKeys`: `/// Visit summary sections she last chose (M9a). static const summarySections = 'summary_sections';`, plus a provider `Stream<Set<SummarySection>> summarySections(Ref ref)` mapping through `parseSummarySections`.
- [ ] **Step 7: Run the tests.** `flutter test test/features/records test/core/content` and expect PASS.
- [ ] **Step 8: Commit.**

```bash
git add lib test
git commit -m "feat(records): visit summary range, data and content model"
```

---

### Task 6: PDF renderer with static Nunito

**Files:**
- Modify: `pubspec.yaml`: `pdf: ^3.13.1` under dependencies, and the `assets/fonts/pdf/` folder under `flutter: assets:`.
- Create: `assets/fonts/pdf/Nunito-Regular.ttf` and `assets/fonts/pdf/Nunito-Bold.ttf` (instances made from `assets/fonts/Nunito-Variable.ttf`), plus `assets/fonts/pdf/OFL.txt` (a copy of `assets/fonts/OFL-Nunito.txt`).
- Create: `lib/features/records/domain/summary_pdf.dart`
- Test: `test/features/records/summary_pdf_test.dart`

**Interfaces:**
- Consumes: `SummaryDoc`, `SummaryBlock` and `SummaryTable` (Task 5).
- Produces:
  - `typedef PdfFonts = ({ByteData regular, ByteData bold});`
  - `Future<Uint8List> renderSummaryPdf(SummaryDoc doc, PdfFonts fonts, {required String Function(int n, int m) pageLabel})`
  - `Future<PdfFonts> loadPdfFonts()`, which reads the two assets through `rootBundle`.

- [ ] **Step 1: Make the static fonts.** This is a one-off dev step; fonttools is not an app dependency and is installed in a scratch venv only.

```bash
python3 -m venv "$TMPDIR/ft" && "$TMPDIR/ft/bin/pip" install fonttools
mkdir -p assets/fonts/pdf
"$TMPDIR/ft/bin/fonttools" varLib.instancer assets/fonts/Nunito-Variable.ttf wght=400 -o assets/fonts/pdf/Nunito-Regular.ttf
"$TMPDIR/ft/bin/fonttools" varLib.instancer assets/fonts/Nunito-Variable.ttf wght=800 -o assets/fonts/pdf/Nunito-Bold.ttf
cp assets/fonts/OFL-Nunito.txt assets/fonts/pdf/OFL.txt
```

Check that both files exist and are under 300 KB each (`ls -l assets/fonts/pdf`).

- [ ] **Step 2: Add the package.** Run `flutter pub add pdf`. Expected: `+ pdf 3.13.1 + barcode + bidi + qr`, with `archive` staying at 4.3.0. Add the assets entry:

```yaml
  assets:
    - assets/fonts/pdf/
```

  Add it to the existing `assets:` list; keep the entries already there.

- [ ] **Step 3: Write the failing tests:**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/records/domain/summary_pdf.dart';
import 'package:navmaas/features/records/domain/visit_summary.dart';

PdfFonts _fonts() => (
  regular: ByteData.sublistView(File('assets/fonts/pdf/Nunito-Regular.ttf').readAsBytesSync()),
  bold: ByteData.sublistView(File('assets/fonts/pdf/Nunito-Bold.ttf').readAsBytesSync()),
);

SummaryDoc _doc({int questions = 3, String name = 'Meera'}) => (
  title: 'Visit summary',
  subtitle: '$name · Thu 17 Sep – Mon, 5 Oct 2026',
  forLine: 'For Dr. Mehta',
  blocks: [
    (heading: 'Vitals', lines: const [], table: (
      header: const ['Date', 'Weight', 'Blood pressure', 'Blood sugar'],
      rows: const [['Fri, 2 Oct', '61.2 kg', '112/72 mmHg', '—']],
    )),
    (heading: 'Questions', lines: [for (var i = 0; i < questions; i++) '• Question $i'], table: null),
  ],
  footer: 'Made with Navmaas on Mon, 5 Oct 2026 · values as she logged them',
);

void main() {
  String label(int n, int m) => 'Page $n of $m';

  test('a valid PDF', () async {
    final bytes = await renderSummaryPdf(_doc(), _fonts(), pageLabel: label);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(bytes.skip(bytes.length - 8)), contains('%%EOF'));
  });

  test('long content runs onto more pages', () async {
    final bytes = await renderSummaryPdf(_doc(questions: 200), _fonts(), pageLabel: label);
    final pages = RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(bytes)).length;
    expect(pages, greaterThan(1));
  });

  test('text the font has no glyphs for does not throw', () async {
    final bytes = await renderSummaryPdf(_doc(name: 'मीरा 🌙'), _fonts(), pageLabel: label);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
```

- [ ] **Step 4: Run them and see them fail.**

- [ ] **Step 5: Implement `summary_pdf.dart`.** Its colours are the printed page's, as in the board `VisitSummaryPdf.dc.html`.

```dart
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:navmaas/features/records/domain/visit_summary.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

typedef PdfFonts = ({ByteData regular, ByteData bold});

Future<PdfFonts> loadPdfFonts() async => (
  regular: await rootBundle.load('assets/fonts/pdf/Nunito-Regular.ttf'),
  bold: await rootBundle.load('assets/fonts/pdf/Nunito-Bold.ttf'),
);

// The printed page's own colours (board VisitSummaryPdf), not the app theme.
const _ink = PdfColor.fromInt(0xFF1F2622);
const _muted = PdfColor.fromInt(0xFF55605A);
const _sage = PdfColor.fromInt(0xFF3E5C4B);
const _rule = PdfColor.fromInt(0xFFCBD6CF);

/// Draws [doc] as A4 pages. Characters the font lacks are skipped by the
/// `pdf` package, never thrown.
Future<Uint8List> renderSummaryPdf(
  SummaryDoc doc,
  PdfFonts fonts, {
  required String Function(int n, int m) pageLabel,
}) async {
  final regular = pw.Font.ttf(fonts.regular);
  final bold = pw.Font.ttf(fonts.bold);
  final theme = pw.ThemeData.withFont(base: regular, bold: bold)
      .copyWith(defaultTextStyle: pw.TextStyle(font: regular, fontSize: 10, color: _ink));
  final small = pw.TextStyle(fontSize: 9, color: _muted);
  final pdf = pw.Document(title: doc.title, creator: 'Navmaas', theme: theme);
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.applyMargin(left: 44, top: 40, right: 44, bottom: 28),
      header: (context) => context.pageNumber > 1
          ? pw.SizedBox()
          : pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 1.5)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(doc.title, style: pw.TextStyle(font: bold, fontSize: 20)),
                        pw.Text(doc.subtitle, style: small.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  if (doc.forLine case final f?) pw.Text(f, style: small),
                ],
              ),
            ),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(doc.footer, style: small),
            pw.Text(pageLabel(context.pageNumber, context.pagesCount), style: small),
          ],
        ),
      ),
      build: (context) => [
        for (final b in doc.blocks) ...[
          pw.Header(
            level: 2,
            decoration: const pw.BoxDecoration(),
            padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
            child: pw.Text(b.heading, style: pw.TextStyle(font: bold, fontSize: 12, color: _sage)),
          ),
          for (final line in b.lines)
            line.startsWith('## ')
                ? pw.Text(line.substring(3), style: pw.TextStyle(font: bold))
                : pw.Paragraph(text: line, margin: const pw.EdgeInsets.only(bottom: 2)),
          if (b.table case final t?)
            pw.TableHelper.fromTextArray(
              headers: t.header,
              data: t.rows,
              border: null,
              headerStyle: pw.TextStyle(font: bold, color: _muted),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 0),
            ),
        ],
      ],
    ),
  );
  return pdf.save();
}
```

If the missing-glyph test throws (the `pdf` package can throw on unknown code points in some versions), remove characters the font lacks before drawing. `pw.Font.ttf(...)` exposes `font.isRuneSupported(rune)` (check the API in `~/.pub-cache/hosted/pub.dev/pdf-3.13.1/lib/src/pdf/font/ttf_parser.dart` / `widgets/font.dart`). Map every string through a `_drawable(String)` helper that replaces unsupported runes with `'?'`, and record the fallback in ADR 065.

- [ ] **Step 6: Run the tests.** `flutter test test/features/records/summary_pdf_test.dart` and expect PASS.
- [ ] **Step 7: Commit.**

```bash
git add pubspec.yaml pubspec.lock assets/fonts/pdf lib/features/records/domain/summary_pdf.dart test/features/records/summary_pdf_test.dart
git commit -m "feat(records): visit summary PDF renderer with static Nunito"
```

---

### Task 7: Visit summary screen, share flow and on-device text check

**Files:**
- Fill: `lib/features/records/presentation/visit_summary_screen.dart`
- Create: `integration_test/visit_summary_test.dart`
- Test: `test/features/records/visit_summary_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 5 and 6, `shareRecordCopy`, `recordsTempDirProvider`, `shareFileProvider` and `summarySectionsProvider`.
- Produces: `VisitSummaryScreen({String? visitId})`, plus an injectable `pdfFontsProvider` (`@riverpod Future<PdfFonts> pdfFonts(Ref ref) => loadPdfFonts();`) that tests override to read the files directly.

- [ ] **Step 1: Write the failing widget tests:**

```dart
  testWidgets('defaults: since last visit, clinical sections ticked', (t) async {
    await pumpApp(t, seed: _seedWithVisit); // a past visit on 17 Sep 2026
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/care/visit-summary');
    await t.pumpAndSettle();
    expect(find.text('Visit summary'), findsOneWidget);
    expect(_selected(t, 'Since last visit'), isTrue);
    expect(find.textContaining('17 Sep'), findsOneWidget);
    for (final s in ['Pregnancy summary', 'Supplements', 'Vitals', 'Questions',
        'Kicks and contractions', 'Records']) {
      expect(_checked(t, s), isTrue, reason: s);
    }
    expect(_checked(t, 'Wellbeing'), isFalse);
    expect(_checked(t, 'Birth plan'), isFalse);
  });

  testWidgets('her choice is remembered', (t) async {
    final db = await pumpApp(t, seed: _seedWithVisit);
    // open, tap "Wellbeing", go back, open again → Wellbeing checked;
    // the stored setting is "pregnancy,supplements,vitals,questions,kicks,records,wellbeing".
  });

  testWidgets('Make PDF shares a PDF and leaves no copy', (t) async {
    final shared = <List<int>>[];
    final temp = Directory.systemTemp.createTempSync('navmaas_st');
    await pumpApp(t, seed: _seedWithVisit, recordsTemp: temp,
        share: (f) async => shared.add(f.readAsBytesSync()));
    // override pdfFontsProvider through a new pumpApp parameter `pdfFonts`
    // that defaults to reading assets/fonts/pdf/*.ttf with File (Task 7 step 3)
    // … tap "Make PDF and share", _settleIo
    expect(String.fromCharCodes(shared.single.take(5)), '%PDF-');
    expect(temp.listSync(), isEmpty);
  });
```

Write the bodies of tests 2 and 3 out in full. `_selected` and `_checked` read the `ChoiceChip.selected` and `Checkbox.value` of the widget whose label matches.

- [ ] **Step 2: Run them and see them fail.**

- [ ] **Step 3: Build the screen** to the `VisitSummary.dc.html` board:
  - **Header:** the same as Records, with the heading "Visit summary".
  - **Body:** the intro line.
  - **Dates:** `Semantics(header: true)` "Dates", four `ChoiceChip`s, and the range line `summaryRangeLine(formatShortDate(from), formatDate(to))`. Custom opens `showDateRangePicker(firstDate: localDay(pregnancyStart), lastDate: localDay(today))`.
  - **Include:** "Include", then a `Card` of `CheckboxListTile`s (title plus `…Sub`). Each change writes `storeSummarySections` to `SettingKeys.summarySections`.
  - **Initial state:** the range comes from `visitId` (when given, `fromVisitDay = dateOnly(visit.at)`) and `appointmentsProvider` (`visitDays`). The sections are seeded with `ref.listenManual(summarySectionsProvider, fireImmediately: true)`, the "Screens that start from saved data" pattern in CLAUDE.md.
  - **Footer:** a full-width `FilledButton.icon(NmIcon(NavmaasIcon.share), summaryMakePdf)` (disabled while working, or when no section is ticked), then the line `summaryPdfNote`.
  - **On tap:**

```dart
    final db = ref.read(appDatabaseProvider);
    final data = await loadSummaryData(db, pregnancyId: p.id, range: range,
        visitId: widget.visitId, prompts: await ref.read(birthPlanPromptsProvider.future));
    final doc = visitSummaryContent(data, range, sections, l10n: l10n, today: today);
    final bytes = await renderSummaryPdf(doc, await ref.read(pdfFontsProvider.future),
        pageLabel: l10n.summaryPage);
    await shareRecordCopy(
      temp: await ref.read(recordsTempDirProvider.future),
      name: 'Visit summary ${DateFormat('yyyy-MM-dd').format(today)}.pdf',
      bytes: bytes,
      share: ref.read(shareFileProvider),
    );
```

  Run it inside try/finally around a `_working` flag. Rendering runs on the main isolate; it is small (a few pages). If a long summary visibly stalls on the phone, move `renderSummaryPdf` into `compute`; it's pure, but `ByteData` must be passed as `Uint8List`.

- [ ] **Step 4: Add the `pumpApp` hook.** Add a `PdfFonts? pdfFonts` parameter and override `pdfFontsProvider` with the files read through `File(...).readAsBytesSync()` (the `rootBundle` asset cache can hang across widget tests; see CLAUDE.md "Assets in tests").

- [ ] **Step 5: Write the on-device text check** in `integration_test/visit_summary_test.dart`. pdfium exists only on a device or simulator.

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navmaas/features/records/domain/summary_pdf.dart';
import 'package:navmaas/features/records/domain/visit_summary.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the PDF holds the chosen headings and none of the others', (t) async {
    await pdfrxFlutterInitialize();
    final fonts = await loadPdfFonts();
    final SummaryDoc doc = (
      title: 'Visit summary', subtitle: 'Meera · 17 Sep – 5 Oct 2026', forLine: null,
      blocks: [
        (heading: 'Vitals', lines: const ['Nothing logged in this range'], table: null),
        (heading: 'Questions', lines: const ['• When is the next scan?'], table: null),
      ],
      footer: 'Made with Navmaas on Mon, 5 Oct 2026 · values as she logged them',
    );
    final bytes = await renderSummaryPdf(doc, fonts, pageLabel: (n, m) => 'Page $n of $m');
    final pdf = await PdfDocument.openData(bytes);
    final text = (await pdf.pages.first.loadText())!.fullText;
    expect(text, contains('Vitals'));
    expect(text, contains('When is the next scan?'));
    expect(text, isNot(contains('Birth plan')));
    expect(text, isNot(contains('Wellbeing')));
    await pdf.dispose();
  });
}
```

Run: `flutter test integration_test/visit_summary_test.dart -d <iPhone simulator>`. Expected: PASS. The output goes into the PR's evidence.

- [ ] **Step 6: Run the tests.** `flutter test test/features/records` and expect PASS. `flutter analyze` should report zero issues.
- [ ] **Step 7: Commit.**

```bash
git add lib test integration_test
git commit -m "feat(records): visit summary screen, PDF to the share sheet"
```

---

### Task 8: Backups, accessibility and goldens

**Files:**
- Modify: `lib/l10n/app_en.arb`: `backupSummary` and `restoredBody` say "record(s)" instead of "photo(s)". The manifest field stays `photos` (spec §4.1). In `deleteAllBody`, change "photos" to "records".
- Modify: `test/features/backup/backup_service_test.dart`: a round trip with records of each kind.
- Modify: `test/core/db/delete_all_data_test.dart`: records are gone after delete-all. The folder deletion already exists; assert the row and file are gone too.
- Modify: `test/accessibility_test.dart`: entries for Records, Records empty, the Add sheet, Record details, the Record (image), the ⋯ sheet, Share a copy?, Delete this record?, the visit with records, and Visit summary.
- Modify: `test/goldens/screens_golden_test.dart`: Records, Record (image), Visit summary and Care (it now has the tile), in light and dark.

- [ ] **Step 1: Backup round trip.** In `backup_service_test.dart`, follow the existing two-"phones" test:
  - Seed a report PDF and a scan image through `RecordsRepository` with the service's `attachments/` dir.
  - Back up, restore on phone B, and expect two rows with the same `category`, `title` and `takenOn`.
  - `RecordsRepository.bytes` returns identical bytes, and `photos == 2` in the result.
- [ ] **Step 2: Restore an older backup.** The existing "a backup from an older version restores and migrates" test covers the v12 DB file. Extend its assertions: a v12 attachment row comes back as `RecordCategory.prescription`.
- [ ] **Step 3: Accessibility entries.** Add them, following the existing `'nutrition'` / `'hospital bag'` entries (`(seeded, (t) => _go(t, '/care/records'))`, etc.). Seed one image record through `RecordsRepository` in `_seed` (a temp dir passed as `records:`).
- [ ] **Step 4: Goldens.** Add the cases, then run `flutter test test/goldens --update-goldens` and inspect the new macOS PNGs against the boards. Linux goldens come from CI's `linux-goldens` artifact after pushing (CLAUDE.md).
- [ ] **Step 5: Run the full suite.** `flutter test`, expecting all tests to PASS. `dart format --set-exit-if-changed .` should exit 0, and `flutter analyze` should report zero issues.
- [ ] **Step 6: Commit.**

```bash
git add lib test
git commit -m "test(records): backups, accessibility and goldens for records and the summary"
```

---

### Task 9: Version, docs in sync, release checks and PR

**Files:**
- Modify: `pubspec.yaml` (`version: 1.7.0+9`) and `lib/features/backup/data/backup_service.dart` (`appVersion = '1.7.0'`).
- Modify: `docs/PLAN.md`:
  - status line;
  - Plan decision **79** (M9a: records per pregnancy; the visit's records; removing a visit keeps its records; summary range and default sections; made from a visit or Records, not Me; values only; share copy deleted; Navmaas 1.7.0 (build 9));
  - the feature-map rows "Records vault" and "Garbhasanskar" (EPUB stays M9b);
  - the Phase 2 row.
- Modify: `docs/ARCHITECTURE.md`:
  - status line;
  - §3 packages: `pdf` moves from Planned to in use, with its transitive `barcode`, `bidi` and `qr`;
  - §4 folders: `lib/features/records/`;
  - §8 data model: `attachment` columns and the `summary_sections` setting;
  - §11 backups: "photos" become records;
  - §13 security: the share copy in `navmaas-share/`, swept at start;
  - §15: the M9 row (M9a ✅, v13) and M9's Scope and Status (made from a visit and Records, not Me);
  - ADR **064**: records reuse `attachment` with `pregnancy_id`; removing a visit unlinks; plain share copies only in `navmaas-share/`, deleted after share and at start;
  - ADR **065**: the visit summary is a plain content model rendered by `pdf` with static Nunito instances made from the bundled OFL font; text checked on device through pdfrx because pdfium isn't in unit tests.
- Modify: `docs/DESIGN_SYSTEM.md`:
  - the prototype line (M9a boards added 2026-10-11);
  - §4 icons (`folder`, `share`, `list`);
  - §6 components (Records row, record tile on a visit);
  - §8 differences: list-icon dots are filled paths; the dashed Add tile is drawn solid.
- Modify: `README.md` ("Next" line: M9b EPUB, then Phase 3) and `CLAUDE.md`:
  - a `records/` folder bullet: repository, `recordsTempDir`, the summary content model and PDF, `pickImageProvider`, `pdfFontsProvider`;
  - `pumpApp` gains `records`, `pickImage`, `recordsTemp` and `pdfFonts`;
  - commands: `integration_test/visit_summary_test.dart`;
  - gotchas: "Records' plain copies only via `shareRecordCopy`"; "PDF viewer isn't widget-testable (pdfium)".

- [ ] **Step 1: Bump the version.** Run `flutter test test/app/version_test.dart` and expect PASS.
- [ ] **Step 2: Docs.** Update the docs listed above, then sweep for stale text: `grep -rn "M9\|deferred\|photos\|1\.6\.0" README.md CLAUDE.md docs/*.md` and fix every stale line.
- [ ] **Step 3: Release checks (definition of done):**

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm,android-arm64
# No INTERNET in the merged release manifest:
grep -c "android.permission.INTERNET" build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml || true
ls -l build/app/outputs/flutter-apk/app-release.apk   # under 100 MB
flutter build ios --release --no-codesign
flutter test integration_test/visit_summary_test.dart -d "<iPhone simulator>"
```

Expected: the format check, analyze and tests are clean; the INTERNET count is `0`; the APK is under 100 MB; the iOS build compiles; the integration test passes. Also check that the DB file is still encrypted, using the existing database test (`test/core/db/database_test.dart` "file on disk is encrypted") as the evidence.

- [ ] **Step 4: Commit, push and open the PR.**

```bash
git add -A ':!android/build'
git commit -m "docs: M9a records and visit summary, Navmaas 1.7.0"
git push -u origin feat/m9a-records-visit-summary
gh pr create --base main --title "feat: records vault and visit summary PDF" --body "<summary, evidence for each definition-of-done item, owner phone checklist below>

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

The owner's phone checklist goes in the PR body:
- A PDF record opens and pages on Android and iPhone.
- Camera and photo add work.
- A HEIC file from the iPhone opens.
- Share a copy reaches WhatsApp / Files and leaves nothing in the app's temporary folder.
- A 20 MB PDF saves in a few seconds on her phone.
- The visit summary PDF reads well when printed.
- A 1.6.0 backup restores into 1.7.0, with its prescription photos under Prescriptions.

- [ ] **Step 5: Linux goldens.** When CI's tests fail on the new goldens, run `gh run download <run-id> -n linux-goldens -D test/goldens/linux`, then commit `test: Linux goldens for records and the visit summary` and push. Check that CI is green.
