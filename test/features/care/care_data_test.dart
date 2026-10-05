import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/care/data/care_repository.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/care/data/vitals_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late String pregnancyId;
  late Directory dir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pregnancyId = (await db.select(db.pregnancies).getSingle()).id;
    dir = await Directory.systemTemp.createTemp('navmaas_att');
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  group('attachments', () {
    // A fake JPEG: starts with the JPEG magic bytes and a readable marker.
    final photo = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      ...'PRESCRIPTION Dr Mehta'.codeUnits,
    ]);
    AttachmentStore store(int keyByte) => AttachmentStore(
      directory: dir,
      key: () async => List.filled(32, keyByte),
    );

    test('encrypted on disk, readable with the key', () async {
      final name = await store(7).save(photo);
      final onDisk = File(p.join(dir.path, name)).readAsBytesSync();
      expect(onDisk.take(3), isNot([0xFF, 0xD8, 0xFF]));
      expect(String.fromCharCodes(onDisk).contains('PRESCRIPTION'), isFalse);
      expect(await store(7).read(name), photo);
    });

    test('wrong key or a changed byte fails to open', () async {
      final name = await store(7).save(photo);
      await expectLater(store(8).read(name), throwsA(anything));
      final f = File(p.join(dir.path, name));
      final bytes = f.readAsBytesSync()..[20] ^= 1;
      f.writeAsBytesSync(bytes);
      await expectLater(store(7).read(name), throwsA(anything));
    });
  });

  test('care template is seeded once; book and done', () async {
    final repo = CareRepository(db);
    const template = [
      CareTemplateItem(
        key: 'gtt',
        kind: CareKind.test,
        title: 'Glucose test (GTT)',
        fromWeek: 24,
        toWeek: 28,
        note: 'n',
      ),
      CareTemplateItem(
        key: 'nt',
        kind: CareKind.scan,
        title: 'NT scan',
        fromWeek: 11,
        toWeek: 14,
        note: 'n',
      ),
    ];
    await repo.ensureTemplate(pregnancyId, template);
    await repo.ensureTemplate(pregnancyId, template);
    var items = await repo.watchItems(pregnancyId).first;
    expect(items.map((i) => i.templateKey), ['nt', 'gtt']);

    final at = DateTime(2026, 10, 20, 10);
    await repo.book(items.last.id, at);
    await repo.markDone(items.first.id, done: true);
    items = await repo.watchItems(pregnancyId).first;
    expect(items.last.scheduledAt, at);
    expect(items.first.doneAt, isNotNull);
  });

  test(
    'visits: questions wait for the next visit, then are asked there',
    () async {
      final repo = VisitRepository(db);
      final visit = await repo.saveAppointment(
        pregnancyId: pregnancyId,
        at: DateTime(2026, 10, 8, 11),
        doctor: 'Dr. Mehta',
        place: ' ',
      );
      await repo.addQuestion(
        pregnancyId,
        '  When should I book the glucose test? ',
      );
      var q = (await repo.watchQuestions(pregnancyId).first).single;
      expect(
        (q.body, q.appointmentId),
        ('When should I book the glucose test?', null),
      );

      await repo.setAsked(q.id, asked: true, appointmentId: visit);
      q = (await repo.watchQuestions(pregnancyId).first).single;
      expect((q.appointmentId, q.askedAt != null), (visit, true));

      await repo.setBringAlong(visit, [
        'Last blood report',
        ' ',
        'Supplements list',
      ]);
      await repo.setNotes(visit, 'BP fine, next visit in 4 weeks');
      final a = (await repo.watchAppointments(pregnancyId).first).single;
      expect(a.place, isNull);
      expect(a.bringAlong.split('\n'), [
        'Last blood report',
        'Supplements list',
      ]);
    },
  );

  test('vitals: logged, oldest first; never interpreted', () async {
    final repo = VitalsRepository(db);
    await repo.add(
      pregnancyId: pregnancyId,
      kind: VitalKind.weight,
      value1: 61.2,
      at: DateTime(2026, 10, 4),
    );
    await repo.add(
      pregnancyId: pregnancyId,
      kind: VitalKind.weight,
      value1: 54.8,
      at: DateTime(2026, 5, 2),
    );
    await repo.add(
      pregnancyId: pregnancyId,
      kind: VitalKind.bloodPressure,
      value1: 112,
      value2: 72,
    );
    final weights = await repo.watch(pregnancyId, VitalKind.weight).first;
    expect(weights.map((w) => w.value1), [54.8, 61.2]);
    final bp =
        (await repo.watch(pregnancyId, VitalKind.bloodPressure).first).single;
    expect((bp.value1, bp.value2), (112, 72));
  });
}
