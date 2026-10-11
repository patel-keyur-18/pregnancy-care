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

/// The largest file Navmaas keeps as a record.
const int maxRecordBytes = 25 * 1024 * 1024;

/// A picked file over [maxRecordBytes].
class RecordTooLarge implements Exception;

/// Records (M9a): files sealed by [AttachmentStore], one `attachment` row
/// each, per pregnancy. Bytes are decrypted only into memory.
class RecordsRepository {
  new(this._db, this._store);

  final AppDatabase _db;
  final AttachmentStore _store;

  /// Newest first.
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

/// Takes or chooses a photo, sized as visit photos always were; faked in
/// widget tests.
typedef PickImage = Future<Uint8List?> Function({required bool camera});

@riverpod
PickImage pickImage(Ref ref) => ({required camera}) async {
  final f = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 2400,
    imageQuality: 85,
  );
  return f == null ? null : await f.readAsBytes();
};

/// Where a record or the visit summary waits, plain, for the share sheet.
@riverpod
Future<Directory> recordsTempDir(Ref ref) async =>
    Directory(p.join((await getTemporaryDirectory()).path, 'navmaas-share'));

/// Deletes every plain copy in [dir] (at app start).
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
