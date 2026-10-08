import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_repository.g.dart';

/// File types the library accepts, by extension (ARCHITECTURE §9).
const Map<String, LibraryKind> libraryExtensions = {
  'pdf': LibraryKind.pdf,
  'txt': LibraryKind.text,
  'md': LibraryKind.text,
  'mp3': LibraryKind.audio,
  'm4a': LibraryKind.audio,
  'aac': LibraryKind.audio,
  'wav': LibraryKind.audio,
};

/// Books and audio the owner imports. Each file is copied into the private
/// `db/library/` folder (skipped by OS backups) and never leaves the phone.
class LibraryRepository {
  new(this._db, {required this.directory});

  final AppDatabase _db;

  /// `db/library/`, resolved lazily.
  final Future<Directory> Function() directory;

  /// Most recently opened first, then newest.
  Stream<List<LibraryItem>> watchItems() =>
      (_db.select(_db.libraryItems)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.desc(t.lastOpenedAt),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .watch();

  /// The audio she played last (or the newest, if none has played yet).
  Future<LibraryItem?> lastAudio() =>
      (_db.select(_db.libraryItems)
            ..where(
              (t) =>
                  t.deletedAt.isNull() & t.kind.equalsValue(LibraryKind.audio),
            )
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.lastOpenedAt,
                mode: OrderingMode.desc,
                nulls: NullsOrder.last,
              ),
              (t) => OrderingTerm.desc(t.createdAt),
            ])
            ..limit(1))
          .getSingleOrNull();

  Future<LibraryItem?> get(String id) => (_db.select(
    _db.libraryItems,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Copies the file called [name] into the library, streaming [bytes] (the
  /// picker may hand over a content URI, not a path). Returns null for a
  /// file type the library doesn't read.
  Future<LibraryItem?> import(String name, Stream<List<int>> bytes) async {
    final ext = p.extension(name).replaceFirst('.', '').toLowerCase();
    final kind = libraryExtensions[ext];
    if (kind == null) return null;
    final dir = await directory();
    await dir.create(recursive: true);
    final id = newId();
    final fileName = '$id.$ext';
    final sink = File(p.join(dir.path, fileName)).openWrite();
    try {
      await sink.addStream(bytes);
    } finally {
      await sink.close();
    }
    return await _db
        .into(_db.libraryItems)
        .insertReturning(
          LibraryItemsCompanion.insert(
            id: Value(id),
            kind: kind,
            title: titleFromFileName(name),
            fileName: fileName,
          ),
        );
  }

  /// Writes [bytes] as [item]'s file again (after a restore without the
  /// library). Her place in it stays.
  Future<void> replaceFile(LibraryItem item, Stream<List<int>> bytes) async {
    final dir = await directory();
    await dir.create(recursive: true);
    final sink = File(p.join(dir.path, item.fileName)).openWrite();
    try {
      await sink.addStream(bytes);
    } finally {
      await sink.close();
    }
  }

  /// Swaps [item]'s audio for the file called [name] (E2, Replace file):
  /// a new file name, so the player loads it afresh; the title stays and
  /// the length is read again. False for a file that isn't audio.
  Future<bool> replaceAudio(
    LibraryItem item,
    String name,
    Stream<List<int>> bytes,
  ) async {
    final ext = p.extension(name).replaceFirst('.', '').toLowerCase();
    if (libraryExtensions[ext] != LibraryKind.audio) return false;
    final dir = await directory();
    await dir.create(recursive: true);
    final fileName = '${newId()}.$ext';
    final sink = File(p.join(dir.path, fileName)).openWrite();
    try {
      await sink.addStream(bytes);
    } finally {
      await sink.close();
    }
    final old = await file(item);
    await _write(
      item.id,
      LibraryItemsCompanion(
        fileName: Value(fileName),
        durationSec: const Value(null),
      ),
    );
    if (old.existsSync()) await old.delete();
    return true;
  }

  Future<File> file(LibraryItem item) async =>
      File(p.join((await directory()).path, item.fileName));

  Future<void> rename(String id, String title) =>
      _write(id, LibraryItemsCompanion(title: Value(title.trim())));

  /// Soft-deletes the row and deletes the copied file.
  Future<void> remove(LibraryItem item) async {
    await _write(item.id, LibraryItemsCompanion(deletedAt: Value(clockNow())));
    final f = await file(item);
    if (f.existsSync()) await f.delete();
  }

  Future<void> markOpened(String id) =>
      _write(id, LibraryItemsCompanion(lastOpenedAt: Value(clockNow())));

  /// Saves where she left off; [LibraryItem.furthest] only goes up.
  Future<void> setProgress(
    String id, {
    required int position,
    int? total,
  }) async {
    final furthest = (await get(id))?.furthest ?? 0;
    await _write(
      id,
      LibraryItemsCompanion(
        position: Value(position),
        furthest: Value(position > furthest ? position : furthest),
        total: total == null ? const Value.absent() : Value(total),
      ),
    );
  }

  Future<void> setDuration(String id, int seconds) =>
      _write(id, LibraryItemsCompanion(durationSec: Value(seconds)));

  Future<void> _write(String id, LibraryItemsCompanion row) =>
      (_db.update(_db.libraryItems)..where((t) => t.id.equals(id))).write(
        row.copyWith(updatedAt: Value(clockNow())),
      );
}

/// "evening_stories-vol-2.pdf" → "evening stories vol 2".
String titleFromFileName(String path) {
  final name = p
      .basenameWithoutExtension(path)
      .replaceAll(RegExp('[_-]+'), ' ')
      .trim();
  return name.isEmpty ? p.basename(path) : name;
}

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) => LibraryRepository(
  ref.watch(appDatabaseProvider),
  directory: () async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'db', 'library'),
  ),
);

@riverpod
Stream<List<LibraryItem>> libraryItems(Ref ref) =>
    ref.watch(libraryRepositoryProvider).watchItems();

typedef PickedFile = ({String name, Stream<List<int>> bytes});

/// Opens the system file picker for [extensions]; faked in widget tests.
typedef PickFile = Future<PickedFile?> Function(List<String> extensions);

@riverpod
PickFile pickFile(Ref ref) => (extensions) async {
  final f = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: extensions,
  );
  return f == null ? null : (name: f.name, bytes: f.xFile.openRead());
};
