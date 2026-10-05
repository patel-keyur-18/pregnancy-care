import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:navmaas/core/db/db_key.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.drift.dart';
part 'app_database.g.dart';

@DriftDatabase(tables: [Pregnancies, Settings])
class AppDatabase extends _$AppDatabase {
  new(super.e);

  /// The on-device database, encrypted with SQLCipher.
  factory open() => AppDatabase(
    LazyDatabase(() async {
      final dir = Directory(
        p.join((await getApplicationSupportDirectory()).path, 'db'),
      );
      await dir.create(recursive: true);
      await _excludeFromBackup(dir);
      final key = await readOrCreateDbKey(secureStorage);
      return encryptedExecutor(File(p.join(dir.path, 'navmaas.db')), key);
    }),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

/// Opens [file] with a raw 256-bit SQLCipher key (64 hex chars). Refuses to
/// run on a plain SQLite build, and fails fast on a wrong key.
QueryExecutor encryptedExecutor(File file, String keyHex) =>
    NativeDatabase.createInBackground(
      file,
      setup: (db) {
        if (db.select('PRAGMA cipher_version').isEmpty) {
          throw StateError(
            'SQLCipher missing; refusing to store data unencrypted',
          );
        }
        db
          ..execute('''PRAGMA key = "x'$keyHex'"''')
          ..select('SELECT count(*) FROM sqlite_master');
      },
    );

/// Keeps the database out of iCloud / device backups on iOS. Android does the
/// same through `res/xml` backup rules. The `.navmaas` backup file (M5) is
/// the one way data moves between phones.
Future<void> _excludeFromBackup(Directory dir) async {
  if (!Platform.isIOS) return;
  await const MethodChannel('navmaas/files')
      .invokeMethod<void>('excludeFromBackup', dir.path);
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}
