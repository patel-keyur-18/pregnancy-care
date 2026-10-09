import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/db_key.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/backup/data/backup_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart';

part 'backup_service.g.dart';

/// Shown in a backup's header ("Navmaas 1.0"). A test keeps it equal to
/// the version in pubspec.yaml.
const appVersion = '1.2.0';

/// The keys a backup carries inside its encrypted body.
typedef BackupKeys = ({
  Future<String> Function() dbKey,
  Future<List<int>> Function() attachmentKey,
  Future<void> Function(List<int> key) setAttachmentKey,
});

typedef BackupResult = ({File file, int sizeBytes, int entries, int photos});
typedef RestoreResult = ({DateTime madeAt, int entries, int photos});

/// Creates and restores `.navmaas` backups (ARCHITECTURE §11).
abstract interface class BackupService {
  /// Encrypts a snapshot of everything into a new file, ready to share.
  /// Voice letters go in only with [includeVoice] (E3).
  Future<BackupResult> create({
    required String password,
    required bool includeLibrary,
    bool includeVoice = false,
  });

  /// Roughly how big a backup will be: everything but the library and
  /// voice letters, the library, and the voice letters.
  Future<({int base, int library, int voice})> sizes();

  /// Copies a picked backup onto the phone, so it can be read in pieces.
  Future<({File file, int size})> receive(Stream<List<int>> bytes);

  /// Reads a backup's header (no password needed).
  Future<BackupHeader> inspect(File file);

  /// Replaces everything with [file]'s contents, or changes nothing.
  /// Throws [BackupException].
  Future<RestoreResult> restore(File file, String password);
}

/// The real service: files under [dataDir] (`<app support>/db`), the
/// open database ([database], read each time: a restore replaces it), and
/// [reopen] to swap the database underneath the app.
class DeviceBackupService implements BackupService {
  new({
    required this.database,
    required this.dataDir,
    required this.workDir,
    required this.keys,
    required this.reopen,
    this.kdf = defaultKdf,
  });

  final AppDatabase Function() database;
  final Directory dataDir;

  /// Scratch space on the same volume as [dataDir].
  final Directory workDir;
  final BackupKeys keys;

  /// Closes the current database and opens the one now in [dataDir]
  /// (running migrations); throws if it can't.
  final Future<void> Function() reopen;
  final KdfParams kdf;

  Directory get _attachments => Directory(p.join(dataDir.path, 'attachments'));
  Directory get _library => Directory(p.join(dataDir.path, 'library'));
  Directory get _voice => Directory(p.join(dataDir.path, 'voice'));

  @override
  Future<BackupResult> create({
    required String password,
    required bool includeLibrary,
    bool includeVoice = false,
  }) async {
    final db = database();
    if (workDir.existsSync()) await workDir.delete(recursive: true);
    await workDir.create(recursive: true);
    // A consistent copy, still encrypted with the database key.
    final snapshot = p.join(workDir.path, 'navmaas.db');
    await db.customStatement("VACUUM INTO '${snapshot.replaceAll("'", "''")}'");
    final (:entries, :photos) = await _counts(db);
    final files = <BackupSource>[
      (name: 'navmaas.db', file: File(snapshot)),
      ...await _filesIn(_attachments, 'attachments'),
      if (includeLibrary) ...await _filesIn(_library, 'library'),
      if (includeVoice) ...await _filesIn(_voice, 'voice'),
    ];
    final now = clockNow();
    final out = File(
      p.join(
        workDir.path,
        'navmaas-backup-${DateFormat('yyyy-MM-dd').format(now)}.navmaas',
      ),
    );
    final manifest = {
      'dbKey': await keys.dbKey(),
      'attachmentKey': base64.encode(await keys.attachmentKey()),
      'entries': entries,
      'photos': photos,
    };
    final header = BackupHeader(
      createdAt: now,
      appVersion: appVersion,
      schemaVersion: db.schemaVersion,
      includesLibrary: includeLibrary,
      kdf: kdf,
    );
    // Key derivation and encryption take a few seconds: off the UI thread.
    await Isolate.run(
      () => writeBackup(
        out: out,
        header: header,
        password: password,
        files: files,
        manifest: manifest,
      ),
    );
    await File(snapshot).delete();
    final size = await out.length();
    await db
        .into(db.backupLog)
        .insert(
          BackupLogCompanion.insert(
            kind: BackupKind.backup,
            sizeBytes: size,
            includesLibrary: includeLibrary,
          ),
        );
    return (file: out, sizeBytes: size, entries: entries, photos: photos);
  }

  @override
  Future<({int base, int library, int voice})> sizes() async {
    Future<int> sum(Directory dir) async => !dir.existsSync()
        ? 0
        : [
            await for (final f in dir.list())
              if (f is File) await f.length(),
          ].fold<int>(0, (a, b) => a + b);
    final db = File(p.join(dataDir.path, 'navmaas.db'));
    return (
      base: (db.existsSync() ? await db.length() : 0) + await sum(_attachments),
      library: await sum(_library),
      voice: await sum(_voice),
    );
  }

  @override
  Future<({File file, int size})> receive(Stream<List<int>> bytes) async {
    final dir = Directory('${workDir.path}-incoming');
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'picked.navmaas'));
    await bytes.pipe(file.openWrite());
    return (file: file, size: await file.length());
  }

  @override
  Future<BackupHeader> inspect(File file) => readBackupHeader(file);

  @override
  Future<RestoreResult> restore(File file, String password) async {
    final header = await readBackupHeader(file);
    if (header.schemaVersion > database().schemaVersion) {
      throw const BackupException(BackupError.tooNew);
    }
    // Its own folder: the file being restored may sit in [workDir].
    final staging = Directory('${workDir.path}-restore');
    if (staging.existsSync()) await staging.delete(recursive: true);
    await staging.create(recursive: true);
    try {
      final manifest = await Isolate.run(
        () => readBackup(file: file, password: password, into: staging),
      );
      final dbFile = File(p.join(staging.path, 'navmaas.db'));
      final backupKey = manifest['dbKey'];
      final attachmentKey = manifest['attachmentKey'];
      if (!dbFile.existsSync() ||
          backupKey is! String ||
          attachmentKey is! String) {
        throw const BackupException(BackupError.damaged);
      }
      // The backup's database moves to this phone's key.
      _rekey(dbFile.path, from: backupKey, to: await keys.dbKey());
      await _swap(staging, base64.decode(attachmentKey), header);
      final restored = database();
      await restored
          .into(restored.backupLog)
          .insert(
            BackupLogCompanion.insert(
              kind: BackupKind.restore,
              sizeBytes: await file.length(),
              includesLibrary: header.includesLibrary,
            ),
          );
      return (
        madeAt: header.createdAt,
        entries: manifest['entries'] as int? ?? 0,
        photos: manifest['photos'] as int? ?? 0,
      );
    } finally {
      if (staging.existsSync()) await staging.delete(recursive: true);
    }
  }

  /// Moves [staging] into place, keeping the old data until the new
  /// database opens; puts everything back if it doesn't.
  Future<void> _swap(
    Directory staging,
    List<int> attachmentKey,
    BackupHeader header,
  ) async {
    final rollback = rollbackDirFor(dataDir);
    if (rollback.existsSync()) await rollback.delete(recursive: true);
    final oldKey = await keys.attachmentKey();
    await dataDir.rename(rollback.path);
    try {
      await staging.rename(dataDir.path);
      await keys.setAttachmentKey(attachmentKey);
      await reopen();
    } on Object {
      if (dataDir.existsSync()) await dataDir.delete(recursive: true);
      await rollback.rename(dataDir.path);
      await keys.setAttachmentKey(oldKey);
      await reopen();
      throw const BackupException(BackupError.damaged);
    }
    // Without the library in the backup, this phone's books and audio stay.
    final oldLibrary = Directory(p.join(rollback.path, 'library'));
    if (!header.includesLibrary && oldLibrary.existsSync()) {
      if (_library.existsSync()) await _library.delete(recursive: true);
      await oldLibrary.rename(_library.path);
    }
    await rollback.delete(recursive: true);
  }

  /// Rows she has logged (every table but settings), and photos.
  static Future<({int entries, int photos})> _counts(AppDatabase db) async {
    var entries = 0;
    for (final table in db.allTables) {
      if (table.actualTableName == db.settings.actualTableName) continue;
      final row = await db
          .customSelect(
            'SELECT count(*) AS n FROM ${table.actualTableName} '
            'WHERE deleted_at IS NULL',
          )
          .getSingle();
      entries += row.read<int>('n');
    }
    final photos =
        await (db.selectOnly(db.attachments)
              ..addColumns([db.attachments.id.count()])
              ..where(db.attachments.deletedAt.isNull()))
            .map((r) => r.read(db.attachments.id.count()) ?? 0)
            .getSingle();
    return (entries: entries, photos: photos);
  }

  static Future<List<BackupSource>> _filesIn(Directory dir, String as) async {
    if (!dir.existsSync()) return const [];
    return [
      await for (final f in dir.list())
        if (f is File) (name: '$as/${p.basename(f.path)}', file: f),
    ];
  }

  /// Opens [path] with key [from] and re-encrypts it with key [to].
  static void _rekey(String path, {required String from, required String to}) {
    final hex = RegExp(r'^[0-9a-f]{64}$');
    if (!hex.hasMatch(from) || !hex.hasMatch(to)) {
      throw const BackupException(BackupError.damaged);
    }
    final raw = sqlite3.open(path);
    try {
      raw
        ..execute('''PRAGMA key = "x'$from'"''')
        ..select('SELECT count(*) FROM sqlite_master')
        ..execute('''PRAGMA rekey = "x'$to'"''');
    } on SqliteException {
      throw const BackupException(BackupError.damaged);
    } finally {
      raw.close();
    }
  }
}

@Riverpod(keepAlive: true)
Future<BackupService> backupService(Ref ref) async {
  final support = await getApplicationSupportDirectory();
  return DeviceBackupService(
    database: () => ref.read(appDatabaseProvider),
    dataDir: Directory(p.join(support.path, 'db')),
    workDir: Directory(p.join(support.path, 'backup-work')),
    keys: (
      dbKey: () => readOrCreateDbKey(secureStorage),
      attachmentKey: () => readOrCreateAttachmentKey(secureStorage),
      setAttachmentKey: (key) => writeAttachmentKey(secureStorage, key),
    ),
    reopen: () => reopenAppDatabase(ref),
  );
}

/// How big a backup will be, with and without the library.
@riverpod
Future<({int base, int library, int voice})> backupSizes(Ref ref) async {
  final service = await ref.watch(backupServiceProvider.future);
  return await service.sizes();
}

/// Hands a finished backup to the share sheet ("Save to Files", Drive, …).
/// Navmaas itself never uploads anything. Faked in widget tests.
typedef ShareFile = Future<void> Function(File file);

@riverpod
ShareFile shareFile(Ref ref) => (file) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      fileNameOverrides: [p.basename(file.path)],
    ),
  );
};
