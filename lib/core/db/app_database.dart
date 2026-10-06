import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:navmaas/core/content/content_pack.dart' show CareKind;
import 'package:navmaas/core/db/app_database.steps.dart';
import 'package:navmaas/core/db/db_key.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.drift.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Pregnancies,
    Settings,
    ChecklistTicks,
    Profiles,
    Supplements,
    SupplementSchedules,
    DoseLogs,
    CareItems,
    Appointments,
    VisitQuestions,
    Attachments,
    VitalReadings,
    LibraryItems,
    Sessions,
    Letters,
    KickSessions,
    Contractions,
    BackupLog,
  ],
)
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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      // v2 (M2): Journey checklist ticks.
      from1To2: (m, schema) => m.createTable(schema.checklistTick),
      // v3 (M3a): doctor profile, supplements, schedules and dose logs.
      from2To3: (m, schema) async {
        await m.createTable(schema.profile);
        await m.createTable(schema.supplement);
        await m.createTable(schema.supplementSchedule);
        await m.createTable(schema.doseLog);
      },
      // v4 (M3b): care items, visits, questions, attachments, vitals.
      from3To4: (m, schema) async {
        await m.createTable(schema.careItem);
        await m.createTable(schema.appointment);
        await m.createTable(schema.visitQuestion);
        await m.createTable(schema.attachment);
        await m.createTable(schema.vitalReading);
      },
      // v5 (M4a): library, sessions and letters.
      from4To5: (m, schema) async {
        await m.createTable(schema.libraryItem);
        await m.createTable(schema.session);
        await m.createTable(schema.letter);
      },
      // v6 (M5): kick counter, contractions and the backup log.
      from5To6: (m, schema) async {
        await m.createTable(schema.kickSession);
        await m.createTable(schema.contraction);
        await m.createTable(schema.backupLog);
      },
    ),
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
          // Reminder actions write from a second isolate; wait, don't fail.
          ..execute('PRAGMA busy_timeout = 5000')
          ..select('SELECT count(*) FROM sqlite_master');
      },
    );

/// Keeps the database out of iCloud / device backups on iOS. Android does the
/// same through `res/xml` backup rules. The `.navmaas` backup file (M5) is
/// the one way data moves between phones.
Future<void> _excludeFromBackup(Directory dir) async {
  if (!Platform.isIOS) return;
  try {
    await const MethodChannel('navmaas/files')
        .invokeMethod<void>('excludeFromBackup', dir.path);
  } on MissingPluginException {
    // The background isolate behind notification actions has no app
    // channels; the folder was already marked by the app itself.
  }
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}
