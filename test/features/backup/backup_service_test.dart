import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/backup/data/backup_file.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/screen_rest/data/app_limits.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// A light key derivation keeps the tests quick (the header carries it).
const KdfParams _kdf = (memoryKib: 64, iterations: 1, parallelism: 1);

/// One phone: its own folder, database key and attachment key, and the
/// app's database provider (so a restore swaps it the way the app does).
class _Phone {
  new(this.root, String dbKey)
    : keyStore = {'db': dbKey, 'attach': List.filled(32, dbKey.codeUnitAt(0))};

  final Directory root;
  final Map<String, Object> keyStore;
  late final ProviderContainer container;
  late final DeviceBackupService service;
  bool failNextReopen = false;

  Directory get dataDir => Directory(p.join(root.path, 'db'));
  File get dbFile => File(p.join(dataDir.path, 'navmaas.db'));
  String get dbKey => keyStore['db']! as String;
  List<int> get attachKey => keyStore['attach']! as List<int>;
  AppDatabase get db => container.read(appDatabaseProvider);
  AttachmentStore get attachments => AttachmentStore(
    directory: Directory(p.join(dataDir.path, 'attachments')),
    key: () async => attachKey,
  );
  LibraryRepository get library => LibraryRepository(
    db,
    directory: () async => Directory(p.join(dataDir.path, 'library')),
  );

  static Future<_Phone> create(String name, String dbKey) async {
    final root = await Directory.systemTemp.createTemp('navmaas_$name');
    final phone = _Phone(root, dbKey);
    await phone.dataDir.create(recursive: true);
    phone
      ..container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(encryptedExecutor(phone.dbFile, dbKey));
            ref.onDispose(db.close);
            return db;
          }),
        ],
      )
      ..service = DeviceBackupService(
        database: () => phone.container.read(appDatabaseProvider),
        dataDir: phone.dataDir,
        workDir: Directory(p.join(root.path, 'backup-work')),
        keys: (
          dbKey: () async => dbKey,
          attachmentKey: () async => phone.attachKey,
          setAttachmentKey: (key) async => phone.keyStore['attach'] = key,
        ),
        // The same steps as the app's provider.
        reopen: () async {
          final old = phone.container.read(appDatabaseProvider);
          phone.container.invalidate(appDatabaseProvider);
          await old.close();
          if (phone.failNextReopen) {
            phone.failNextReopen = false;
            throw StateError('disk full');
          }
          await phone.db.customSelect('SELECT 1').get();
        },
        kdf: _kdf,
      );
    return phone;
  }

  Future<void> dispose() async {
    await db.close();
    container.dispose();
    await root.delete(recursive: true);
  }
}

Future<String> _pregnancy(AppDatabase db, DateTime lmp) async {
  await PregnancyRepository(db).saveDating(method: .lmp, date: lmp);
  return (await db.select(db.pregnancies).getSingle()).id;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late _Phone a;
  late _Phone b;
  final photo = Uint8List.fromList(List.generate(2000, (i) => i % 251));

  setUp(() async {
    // Phone A: a pregnancy, a visit with a photo, a book.
    a = await _Phone.create('a', 'aa' * 32);
    final id = await _pregnancy(a.db, DateTime.utc(2026, 4, 15));
    await SettingsRepository(a.db).put(SettingKeys.firstName, 'Meera');
    final visits = VisitRepository(a.db);
    final visit = await visits.saveAppointment(
      pregnancyId: id,
      at: DateTime(2026, 10, 20, 11),
      doctor: 'Dr Rao',
    );
    await visits.addAttachment(a.attachments, visit, photo, 'image/jpeg');
    await a.library.import('stories.txt', Stream.value(utf8.encode('Once')));
    // … and a day of wellbeing logs (M7).
    final wellbeing = WellbeingRepository(a.db);
    final day = DateTime.utc(2026, 10, 5);
    await wellbeing.setMood(pregnancyId: id, day: day, mood: .calm);
    await wellbeing.addSymptom(
      pregnancyId: id,
      kind: .backache,
      severity: .mild,
    );
    await wellbeing.saveSleep(
      pregnancyId: id,
      day: day,
      bedAt: DateTime(2026, 10, 4, 22, 40),
      wokeAt: DateTime(2026, 10, 5, 6, 25),
    );
    await wellbeing.addWater(pregnancyId: id, day: day);
    await AppLimitsRepository(a.db).save(
      package: 'com.google.android.youtube',
      label: 'YouTube',
      minutes: 30,
    );
    // Phone B: a different pregnancy and its own book.
    b = await _Phone.create('b', 'bb' * 32);
    await _pregnancy(b.db, DateTime.utc(2026, 6, 2));
    await b.library.import('b-only.txt', Stream.value(utf8.encode('Mine')));
  });

  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  test('a backup from one phone restores on another', () async {
    final made = await a.service.create(
      password: 'correct horse',
      includeLibrary: true,
    );
    expect(p.basename(made.file.path), startsWith('navmaas-backup-'));
    expect(made.file.path, endsWith('.navmaas'));
    expect(made.photos, 1);
    // pregnancy, care items? no; appointment, attachment, library item.
    expect(made.entries, greaterThanOrEqualTo(4));
    final logged = await a.db.select(a.db.backupLog).getSingle();
    expect(
      (logged.kind, logged.sizeBytes, logged.includesLibrary),
      (BackupKind.backup, made.sizeBytes, true),
    );
    final header = await b.service.inspect(made.file);
    expect((header.appVersion, header.schemaVersion), (appVersion, 12));

    final restored = await b.service.restore(made.file, 'correct horse');
    expect((restored.entries, restored.photos), (made.entries, made.photos));

    // B now has A's data …
    final pregnancy = await b.db.select(b.db.pregnancies).getSingle();
    expect(pregnancy.lmp, DateTime.utc(2026, 4, 15));
    expect(
      await SettingsRepository(b.db).watch(SettingKeys.firstName).first,
      'Meera',
    );
    // … its photo, sealed with A's key, which B now holds …
    final attachment = await b.db.select(b.db.attachments).getSingle();
    expect(await b.attachments.read(attachment.fileName), photo);
    expect(b.attachKey, a.attachKey);
    // … and its book.
    final items = await b.library.watchItems().first;
    expect(items.single.title, 'stories');
    expect(await (await b.library.file(items.single)).readAsString(), 'Once');
    // … and its wellbeing logs.
    expect(
      (await b.db.select(b.db.moodEntries).getSingle()).mood,
      MoodWord.calm,
    );
    expect(
      (await b.db.select(b.db.symptomEntries).getSingle()).symptomKey,
      SymptomKind.backache,
    );
    expect(await b.db.select(b.db.sleepLogs).get(), hasLength(1));
    expect((await b.db.select(b.db.waterLogs).getSingle()).glasses, 1);
    // … and its app limits.
    expect((await b.db.select(b.db.appLimits).getSingle()).minutes, 30);
    // The database is under B's own key, not A's.
    final raw = sqlite3.open(b.dbFile.path);
    addTearDown(raw.close);
    raw.execute('''PRAGMA key = "x'${'bb' * 32}'"''');
    expect(raw.select('SELECT count(*) AS n FROM pregnancy').first['n'], 1);
    // The restore is logged (the backup's own row came after its
    // snapshot); nothing is left behind.
    expect((await b.db.select(b.db.backupLog).get()).map((r) => r.kind), [
      BackupKind.restore,
    ]);
    expect(
      Directory(p.join(b.root.path, 'backup-work-restore')).existsSync(),
      isFalse,
    );
    expect(rollbackDirFor(b.dataDir).existsSync(), isFalse);
  });

  test('without books and audio: this phone keeps its own', () async {
    final made = await a.service.create(
      password: 'correct horse',
      includeLibrary: false,
    );
    await b.service.restore(made.file, 'correct horse');
    // A's book is listed, but its file isn't here: "re-import file".
    final items = await b.library.watchItems().first;
    expect(items.single.title, 'stories');
    expect((await b.library.file(items.single)).existsSync(), isFalse);
    // B's own file is still in its library folder.
    final kept = Directory(p.join(b.dataDir.path, 'library')).listSync();
    expect(kept, hasLength(1));
    expect(File(kept.single.path).readAsStringSync(), 'Mine');
  });

  test('voice letters go in only when she includes them', () async {
    final voice = Directory(p.join(a.dataDir.path, 'voice'));
    File(p.join(voice.path, 'note.bin'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    expect((await a.service.sizes()).voice, 3);

    var made = await a.service.create(
      password: 'correct horse',
      includeLibrary: false,
    );
    await b.service.restore(made.file, 'correct horse');
    expect(Directory(p.join(b.dataDir.path, 'voice')).existsSync(), isFalse);

    made = await a.service.create(
      password: 'correct horse',
      includeLibrary: false,
      includeVoice: true,
    );
    await b.service.restore(made.file, 'correct horse');
    expect(
      File(p.join(b.dataDir.path, 'voice', 'note.bin')).readAsBytesSync(),
      [1, 2, 3],
    );
  });

  test('a wrong password changes nothing', () async {
    final made = await a.service.create(
      password: 'correct horse',
      includeLibrary: true,
    );
    final before = await b.db.select(b.db.pregnancies).getSingle();
    await expectLater(
      b.service.restore(made.file, 'wrong horse'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.error,
          'error',
          BackupError.wrongPassword,
        ),
      ),
    );
    expect(await b.db.select(b.db.pregnancies).getSingle(), before);
    expect(b.attachKey, isNot(a.attachKey));
  });

  test('a backup from a newer Navmaas is refused', () async {
    final out = File(p.join(a.root.path, 'new.navmaas'));
    await writeBackup(
      out: out,
      header: BackupHeader(
        createdAt: DateTime.utc(2027),
        appVersion: '2.0.0',
        schemaVersion: 99,
        includesLibrary: false,
        kdf: _kdf,
      ),
      password: 'correct horse',
      files: const [],
      manifest: const {},
    );
    await expectLater(
      b.service.restore(out, 'correct horse'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.error,
          'error',
          BackupError.tooNew,
        ),
      ),
    );
    expect(await b.db.select(b.db.pregnancies).get(), hasLength(1));
  });

  // Backups from before M5 (schema 5), M7 (schema 6), M11 (schema 7),
  // reading progress (schema 8), links (schema 9), voice letters (schema 10)
  // and birth prep (schema 11).
  const birthPrepTables = ['avoid_food', 'bag_item', 'birth_plan_answer'];
  const wellbeingTables = [
    'mood_entry',
    'symptom_entry',
    'sleep_log',
    'water_log',
  ];
  for (final (version, dropped) in [
    (
      5,
      [
        'kick_session',
        'contraction',
        'backup_log',
        ...wellbeingTables,
        'app_limit',
        'media_link',
        ...birthPrepTables,
      ],
    ),
    (6, [...wellbeingTables, 'app_limit', 'media_link', ...birthPrepTables]),
    (7, ['app_limit', 'media_link', ...birthPrepTables]),
    (8, ['media_link', ...birthPrepTables]),
    (9, ['media_link', ...birthPrepTables]),
    (10, birthPrepTables),
    (11, birthPrepTables),
  ]) {
    test('a schema $version backup is migrated when it opens', () async {
      for (final t in dropped) {
        await a.db.customStatement('DROP TABLE $t');
      }
      // v9 added how far she has read.
      if (version < 9) {
        await a.db.customStatement(
          'ALTER TABLE library_item DROP COLUMN furthest',
        );
      }
      // v11 added a letter's voice note.
      if (version < 11) {
        for (final column in ['voice_file', 'voice_sec']) {
          await a.db.customStatement('ALTER TABLE letter DROP COLUMN $column');
        }
      }
      // v12 added a blood-sugar reading's context and note.
      for (final column in ['context', 'note']) {
        await a.db.customStatement(
          'ALTER TABLE vital_reading DROP COLUMN $column',
        );
      }
      await a.db.customStatement('PRAGMA user_version = $version');
      final file = File(p.join(a.root.path, 'old.navmaas'));
      final snapshot = File(p.join(a.root.path, 'old.db'));
      await a.db.customStatement("VACUUM INTO '${snapshot.path}'");
      await writeBackup(
        out: file,
        header: BackupHeader(
          createdAt: DateTime.utc(2026, 10),
          appVersion: '0.9.0',
          schemaVersion: version,
          includesLibrary: false,
          kdf: _kdf,
        ),
        password: 'correct horse',
        files: [(name: 'navmaas.db', file: snapshot)],
        manifest: {
          'dbKey': a.dbKey,
          'attachmentKey': base64.encode(a.attachKey),
        },
      );
      await b.service.restore(file, 'correct horse');
      expect(
        (await b.db.select(b.db.pregnancies).getSingle()).lmp,
        DateTime.utc(2026, 4, 15),
      );
      // The tables it didn't have are there, and empty (the backup log
      // already holds this restore).
      for (final t in dropped.where((t) => t != 'backup_log')) {
        final n = await b.db
            .customSelect('SELECT count(*) AS n FROM $t')
            .getSingle();
        expect(n.read<int>('n'), 0, reason: t);
      }
    });
  }

  test('if the new data fails to open, the old data comes back', () async {
    final made = await a.service.create(
      password: 'correct horse',
      includeLibrary: true,
    );
    final oldKey = b.attachKey;
    b.failNextReopen = true;
    await expectLater(
      b.service.restore(made.file, 'correct horse'),
      throwsA(isA<BackupException>()),
    );
    final pregnancy = await b.db.select(b.db.pregnancies).getSingle();
    expect(pregnancy.lmp, DateTime.utc(2026, 6, 2));
    expect(b.attachKey, oldKey);
    expect((await b.library.watchItems().first).single.title, 'b only');
    expect(rollbackDirFor(b.dataDir).existsSync(), isFalse);
  });

  test('an interrupted swap is put back when the app next opens', () async {
    // The app stopped after moving the data aside, before the new data.
    await b.db.close();
    await b.dataDir.rename(rollbackDirFor(b.dataDir).path);
    await recoverInterruptedRestore(b.dataDir);
    expect(b.dbFile.existsSync(), isTrue);
    expect(rollbackDirFor(b.dataDir).existsSync(), isFalse);
    b.container.invalidate(appDatabaseProvider);
    final pregnancy = await b.db.select(b.db.pregnancies).getSingle();
    expect(pregnancy.lmp, DateTime.utc(2026, 6, 2));
  });

  test('restores the backup this phone just made', () async {
    final made = await a.service.create(
      password: 'correct horse',
      includeLibrary: false,
    );
    await PregnancyRepository(a.db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 6, 2));
    await a.service.restore(made.file, 'correct horse');
    expect(
      (await a.db.select(a.db.pregnancies).getSingle()).lmp,
      DateTime.utc(2026, 4, 15),
    );
  });
}
