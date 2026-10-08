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
    MoodEntries,
    SymptomEntries,
    SleepLogs,
    WaterLogs,
    AppLimits,
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
      await recoverInterruptedRestore(dir);
      await removeDeletedData(dir);
      await dir.create(recursive: true);
      await _excludeFromBackup(dir);
      final key = await readOrCreateDbKey(secureStorage);
      return encryptedExecutor(File(p.join(dir.path, 'navmaas.db')), key);
    }),
  );

  @override
  int get schemaVersion => 9;

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
      // v7 (M7a): wellbeing — mood, symptoms, sleep and water.
      from6To7: (m, schema) async {
        await m.createTable(schema.moodEntry);
        await m.createTable(schema.symptomEntry);
        await m.createTable(schema.sleepLog);
        await m.createTable(schema.waterLog);
      },
      // v8 (M11a): daily limits on other apps (Android).
      from7To8: (m, schema) => m.createTable(schema.appLimit),
      // v9: how far she has read, so going back keeps her progress.
      from8To9: (m, schema) async {
        await m.addColumn(schema.libraryItem, schema.libraryItem.furthest);
        await m.database.customStatement(
          'UPDATE library_item SET furthest = position',
        );
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

/// Where a restore keeps the data it replaces until the new data opens
/// (ARCHITECTURE §11).
Directory rollbackDirFor(Directory dbDir) =>
    Directory('${dbDir.path}-before-restore');

/// If the app stopped in the middle of a restore's swap, the old data is
/// still in the rollback folder: put it back before opening.
Future<void> recoverInterruptedRestore(Directory dbDir) async {
  final rollback = rollbackDirFor(dbDir);
  if (!rollback.existsSync()) return;
  if (File(p.join(dbDir.path, 'navmaas.db')).existsSync()) return;
  if (dbDir.existsSync()) await dbDir.delete(recursive: true);
  await rollback.rename(dbDir.path);
}

/// Where "Delete all data" moves the database until the new one is open
/// (ARCHITECTURE §13).
Directory deletedDirFor(Directory dbDir) => Directory('${dbDir.path}-deleted');

/// Finishes a "Delete all data" the app stopped in the middle of.
Future<void> removeDeletedData(Directory dbDir) async {
  final deleted = deletedDirFor(dbDir);
  if (deleted.existsSync()) await deleted.delete(recursive: true);
}

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

/// Closes the app's database and opens the one now on disk (after a restore
/// or "Delete all data"). Opening runs the migrations; a database that
/// can't open throws.
Future<void> reopenAppDatabase(Ref ref) async {
  final old = ref.read(appDatabaseProvider);
  ref.invalidate(appDatabaseProvider);
  await old.close();
  await ref.read(appDatabaseProvider).customSelect('SELECT 1').get();
}
