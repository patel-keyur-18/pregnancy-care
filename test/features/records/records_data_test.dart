import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/records/data/records_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Directory dir;
  late RecordsRepository repo;
  late String pid;

  final jpeg = Uint8List.fromList([
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    ...List.filled(64, 1),
  ]);
  final pdf = Uint8List.fromList([
    ...'%PDF-1.7'.codeUnits,
    ...List.filled(64, 2),
  ]);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('navmaas_rec');
    repo = RecordsRepository(
      db,
      AttachmentStore(directory: dir, key: () async => List.filled(32, 7)),
    );
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pid = (await db.select(db.pregnancies).getSingle()).id;
  });
  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<String> add(
    Uint8List bytes, {
    String mime = 'image/jpeg',
    String? visit,
  }) => repo.add(
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
      final head = f.readAsBytesSync().take(12).toList();
      expect(head.take(3), isNot([0xFF, 0xD8, 0xFF]));
      expect(head.take(4), isNot([0x89, 0x50, 0x4E, 0x47]));
      expect(String.fromCharCodes(head.take(4)), isNot('%PDF'));
      expect(String.fromCharCodes(head.skip(4).take(4)), isNot('ftyp'));
    }
  });

  test('a record reads back, with its size, kind, title and date', () async {
    await add(pdf, mime: 'application/pdf');
    final r = (await repo.watch(pid).first).single;
    expect(
      (r.category, r.title, r.takenOn, r.sizeBytes, r.mimeType),
      (
        RecordCategory.report,
        'Blood report',
        DateTime.utc(2026, 10, 2),
        pdf.length,
        'application/pdf',
      ),
    );
    expect(await repo.bytes(r), pdf);
  });

  test('records belong to the pregnancy', () async {
    await add(jpeg);
    final other = await db
        .into(db.pregnancies)
        .insertReturning(
          PregnanciesCompanion.insert(
            status: PregnancyStatus.active,
            datingMethod: .lmp,
            startDate: DateTime.utc(2027, 5, 2),
            dueDate: DateTime.utc(2028, 2, 5),
          ),
        );
    expect(await repo.watch(other.id).first, isEmpty);
    expect(await repo.watch(pid).first, hasLength(1));
  });

  test(
    '25 MB is kept; one byte more is refused before anything is written',
    () async {
      final ok = await repo.readCapped(Stream.value(Uint8List(maxRecordBytes)));
      expect(ok.length, maxRecordBytes);
      await expectLater(
        repo.readCapped(
          Stream.fromIterable([Uint8List(maxRecordBytes), Uint8List(1)]),
        ),
        throwsA(isA<RecordTooLarge>()),
      );
      expect(dir.listSync(), isEmpty);
    },
  );

  test('a date after today is kept as today', () async {
    await repo.add(
      pregnancyId: pid,
      bytes: jpeg,
      mimeType: 'image/jpeg',
      category: RecordCategory.scan,
      title: '',
      takenOn: DateTime.utc(2099, 6),
    );
    final r = (await repo.watch(pid).first).single;
    final now = DateTime.now();
    expect(r.takenOn, DateTime.utc(now.year, now.month, now.day));
  });

  test('edit details, and delete removes the row and the file', () async {
    final id = await add(jpeg);
    await repo.updateDetails(
      id,
      category: RecordCategory.prescription,
      title: ' Iron tablets ',
      takenOn: DateTime.utc(2026, 9, 9),
    );
    final r = (await repo.watch(pid).first).single;
    expect(
      (r.category, r.title, r.takenOn),
      (RecordCategory.prescription, 'Iron tablets', DateTime.utc(2026, 9, 9)),
    );
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
    expect(await repo.watchForVisit(visit).first, hasLength(1));
    await visits.removeAppointment(visit);
    final r = (await repo.watch(pid).first).single;
    expect(r.appointmentId, isNull);
    expect(dir.listSync(), hasLength(1));
  });

  test('inRange is inclusive at both ends', () async {
    await add(jpeg); // 2 Oct
    expect(
      await repo.inRange(
        pid,
        DateTime.utc(2026, 10, 2),
        DateTime.utc(2026, 10, 2),
      ),
      hasLength(1),
    );
    expect(
      await repo.inRange(
        pid,
        DateTime.utc(2026, 10, 3),
        DateTime.utc(2026, 10, 9),
      ),
      isEmpty,
    );
  });

  test(
    'a shared copy is deleted after sharing, even when sharing fails',
    () async {
      final temp = Directory.systemTemp.createTempSync('navmaas_share');
      File? seen;
      await shareRecordCopy(
        temp: temp,
        name: 'Blood report.pdf',
        bytes: pdf,
        share: (f) async {
          seen = f;
          expect(f.readAsBytesSync(), pdf);
        },
      );
      expect(p.basename(seen!.path), 'Blood report.pdf');
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
    },
  );

  test('a name with slashes stays inside the share folder', () async {
    final temp = Directory.systemTemp.createTempSync('navmaas_share');
    File? seen;
    await shareRecordCopy(
      temp: temp,
      name: '../CBC 2/10.pdf',
      bytes: pdf,
      share: (f) async => seen = f,
    );
    expect(p.dirname(seen!.path), temp.path);
  });

  test('mime from a file name', () {
    expect(mimeForName('a.PDF'), 'application/pdf');
    expect(mimeForName('a.png'), 'image/png');
    expect(mimeForName('a.heic'), 'image/heic');
    expect(mimeForName('a.jpeg'), 'image/jpeg');
  });

  test('the start-up sweep removes plain copies the plugins leave', () {
    final tmp = Directory.systemTemp.createTempSync('navmaas_tmp');
    File put(String path) => File(p.join(tmp.path, path))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
    put('navmaas-share/Blood report.pdf'); // ours, mid-share
    put('share_plus/Blood report.pdf'); // share_plus (Android)
    put('file_picker/1700000000/scan.pdf'); // file_picker (Android)
    put('image_picker_ABC.jpg'); // image_picker (iPhone)
    put('flutter_image_picker_copy_1.jpg'); // image_picker (iPhone)
    put('scaled_1700000000.jpg'); // image_picker resized (Android)
    put('3f2b8c1e-0d4a-4b7e-9a1c-2e5f6a7b8c9d/IMG_1.jpg'); // its original
    final keep = put('other/kept.bin');
    sweepPlainCopies(tmp);
    final left = tmp
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => p.relative(f.path, from: tmp.path))
        .toList();
    expect(left, [p.relative(keep.path, from: tmp.path)]);
  });
}
