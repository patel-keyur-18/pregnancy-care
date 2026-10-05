import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/sessions/data/letter_repository.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late String pregnancyId;
  late Directory tmp;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pregnancyId = (await db.select(db.pregnancies).getSingle()).id;
    tmp = await Directory.systemTemp.createTemp('navmaas_lib');
  });
  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('library: import copies the file; remove deletes it', () async {
    final library = Directory(p.join(tmp.path, 'library'));
    final repo = LibraryRepository(db, directory: () async => library);
    final source = File(p.join(tmp.path, 'evening_stories-vol-2.PDF'))
      ..writeAsStringSync('%PDF-1.4');

    final item = (await repo.import(source.path, source.openRead()))!;
    expect((item.kind, item.title), (LibraryKind.pdf, 'evening stories vol 2'));
    final copy = await repo.file(item);
    expect(copy.readAsStringSync(), '%PDF-1.4');
    expect(p.isWithin(library.path, copy.path), isTrue);

    expect(await repo.import('x.epub', const Stream.empty()), isNull);

    await repo.setProgress(item.id, position: 41, total: 120);
    await repo.rename(item.id, ' Evening stories ');
    final saved = (await repo.watchItems().first).single;
    expect(
      (saved.title, saved.position, saved.total),
      ('Evening stories', 41, 120),
    );

    await repo.remove(saved);
    expect(await repo.watchItems().first, isEmpty);
    expect(copy.existsSync(), isFalse);
  });

  test('library: last opened comes first', () async {
    final repo = LibraryRepository(
      db,
      directory: () async => Directory(p.join(tmp.path, 'library')),
    );
    final a = (await repo.import('a.txt', Stream.value([97])))!;
    await repo.import('b.mp3', Stream.value([98]));
    await repo.markOpened(a.id);
    expect((await repo.watchItems().first).map((i) => i.title), ['a', 'b']);
  });

  test('sessions: logged, grown, and read back by day', () async {
    final repo = SessionRepository(db);
    final id = await repo.log(
      pregnancyId: pregnancyId,
      type: SessionType.listening,
      startedAt: DateTime(2026, 10, 5, 21),
      durationSec: 60,
    );
    await repo.setDuration(id, 540);
    await repo.log(
      pregnancyId: pregnancyId,
      type: SessionType.reading,
      startedAt: DateTime(2026, 10, 4, 21),
      durationSec: 900,
    );
    final today = await repo
        .watchBetween(pregnancyId, DateTime(2026, 10, 5), DateTime(2026, 10, 6))
        .first;
    expect(today.map((s) => (s.type, s.durationSec)), [
      (SessionType.listening, 540),
    ]);
  });

  test('letters: newest first; edit and remove', () async {
    final repo = LetterRepository(db);
    await repo.save(pregnancyId, ' Dear little one, ');
    var letters = await repo.watch(pregnancyId).first;
    expect(letters.single.body, 'Dear little one,');
    await repo.save(
      pregnancyId,
      'Dear little one, hello.',
      id: letters.single.id,
    );
    letters = await repo.watch(pregnancyId).first;
    expect(letters.single.body, 'Dear little one, hello.');
    await repo.remove(letters.single.id);
    expect(await repo.watch(pregnancyId).first, isEmpty);
  });
}
