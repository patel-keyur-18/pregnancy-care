import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/db_key.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('encryption at rest', () {
    late Directory dir;
    late File file;
    final key = 'ab' * 32;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('navmaas_db');
      file = File(p.join(dir.path, 'navmaas.db'));
      final db = AppDatabase(encryptedExecutor(file, key));
      await PregnancyRepository(db)
          .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
      await SettingsRepository(db).put(SettingKeys.firstName, 'Asha');
      await db.close();
    });

    tearDown(() => dir.delete(recursive: true));

    test('file has no SQLite header and no plaintext', () {
      final bytes = file.readAsBytesSync();
      final text = latin1.decode(bytes);
      expect(text.startsWith('SQLite format 3'), isFalse);
      for (final plain in ['CREATE TABLE', 'pregnancy', 'Asha', '2027-01-20']) {
        expect(text.contains(plain), isFalse, reason: plain);
      }
    });

    test('cannot be read without the key', () {
      final raw = sqlite3.open(file.path);
      addTearDown(raw.close);
      expect(
        () => raw.select('SELECT count(*) FROM sqlite_master'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('cannot be opened with a wrong key', () async {
      final db = AppDatabase(encryptedExecutor(file, 'cd' * 32));
      addTearDown(db.close);
      await expectLater(db.select(db.pregnancies).get(), throwsA(anything));
    });

    test('reads back with the right key', () async {
      final db = AppDatabase(encryptedExecutor(file, key));
      addTearDown(db.close);
      final row = await db.select(db.pregnancies).getSingle();
      expect(row.dueDate, DateTime.utc(2027, 1, 20));
    });
  });

  test('db key: 256-bit, generated once, then reused', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final first = await readOrCreateDbKey(storage);
    expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(await readOrCreateDbKey(storage), first);
  });

  group('repositories', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('saveDating creates one active pregnancy, then re-dates it', () async {
      final repo = PregnancyRepository(db);
      await repo.saveDating(
        method: .lmp,
        date: DateTime.utc(2026, 4, 15),
        cycleLength: 30,
      );
      var row = (await repo.watchActive().first)!;
      expect(row.status, PregnancyStatus.active);
      expect(row.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect((row.lmp, row.cycleLength), (DateTime.utc(2026, 4, 15), 30));
      expect(row.startDate, DateTime.utc(2026, 4, 17));
      final id = row.id;

      await repo.saveDating(
        method: .ivf,
        date: DateTime.utc(2026, 5, 2),
        embryoDay: 3,
      );
      final rows = await db.select(db.pregnancies).get();
      expect(rows, hasLength(1));
      row = rows.single;
      expect(row.id, id);
      expect((row.lmp, row.cycleLength), (null, null));
      expect((row.anchorDate, row.embryoDay), (DateTime.utc(2026, 5, 2), 3));
      expect(row.dueDate, DateTime.utc(2027, 1, 20));
    });

    test('settings upsert by key', () async {
      final repo = SettingsRepository(db);
      await repo.put(SettingKeys.themeMode, 'dark');
      await repo.put(SettingKeys.themeMode, 'light');
      expect(await repo.watch(SettingKeys.themeMode).first, 'light');
      expect(await db.select(db.settings).get(), hasLength(1));
    });

    test('settings remove soft-deletes; put brings the key back', () async {
      final repo = SettingsRepository(db);
      await repo.put(SettingKeys.firstName, 'Meera');
      await repo.remove(SettingKeys.firstName);
      expect(await repo.watch(SettingKeys.firstName).first, isNull);
      expect((await db.select(db.settings).getSingle()).deletedAt, isNotNull);
      await repo.put(SettingKeys.firstName, 'Asha');
      expect(await repo.watch(SettingKeys.firstName).first, 'Asha');
    });
  });
}
