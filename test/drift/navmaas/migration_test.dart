import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v10.dart' as v10;
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;
import 'generated/schema_v8.dart' as v8;
import 'generated/schema_v9.dart' as v9;

// After changing tables: bump `schemaVersion`, write the migration, then run
// `dart run drift_dev make-migrations` to dump the new schema and helpers.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('tables match the latest schema snapshot', () async {
    final latest = GeneratedHelper.versions.last;
    final db = AppDatabase(NativeDatabase.memory());
    expect(db.schemaVersion, latest, reason: 'run make-migrations');
    await db.close();

    final schema = await verifier.schemaAt(latest);
    final fresh = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(fresh, latest);
    await fresh.close();
  });

  // Every older schema must migrate to every newer one. Runs from v2 on.
  const versions = GeneratedHelper.versions;
  for (final (i, from) in versions.indexed) {
    for (final to in versions.skip(i + 1)) {
      test('migrates v$from → v$to', () async {
        final schema = await verifier.schemaAt(from);
        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, to);
        await db.close();
      });
    }
  }

  test('v1 → v2 keeps the pregnancy and adds checklist ticks', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old
        .into(old.pregnancy)
        .insert(
          v1.PregnancyCompanion.insert(
            id: 'p1',
            createdAt: '2026-10-05T00:00:00.000',
            updatedAt: '2026-10-05T00:00:00.000',
            status: 'active',
            datingMethod: 'lmp',
            startDate: '2026-04-15',
            dueDate: '2027-01-20',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    final p = await db.select(db.pregnancies).getSingle();
    expect((p.id, p.dueDate), ('p1', DateTime.utc(2027, 1, 20)));
    expect(await db.select(db.checklistTicks).get(), isEmpty);
    await db.close();
  });
  test('v6 → v7 keeps her logs and adds empty wellbeing tables', () async {
    final schema = await verifier.schemaAt(6);
    final old = v6.DatabaseAtV6(schema.newConnection());
    const at = '2026-10-05T00:00:00.000';
    await old
        .into(old.pregnancy)
        .insert(
          v6.PregnancyCompanion.insert(
            id: 'p1',
            createdAt: at,
            updatedAt: at,
            status: 'active',
            datingMethod: 'lmp',
            startDate: '2026-04-15',
            dueDate: '2027-01-20',
          ),
        );
    await old
        .into(old.kickSession)
        .insert(
          v6.KickSessionCompanion.insert(
            id: 'k1',
            createdAt: at,
            updatedAt: at,
            pregnancyId: 'p1',
            startedAt: at,
            endedAt: at,
            count: 10,
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 7);
    expect((await db.select(db.kickSessions).getSingle()).count, 10);
    expect(await db.select(db.moodEntries).get(), isEmpty);
    expect(await db.select(db.symptomEntries).get(), isEmpty);
    expect(await db.select(db.sleepLogs).get(), isEmpty);
    expect(await db.select(db.waterLogs).get(), isEmpty);
    await db.close();
  });

  test('v7 → v8 keeps her wellbeing logs and adds empty app limits', () async {
    final schema = await verifier.schemaAt(7);
    final old = v7.DatabaseAtV7(schema.newConnection());
    const at = '2026-10-05T00:00:00.000';
    await old
        .into(old.pregnancy)
        .insert(
          v7.PregnancyCompanion.insert(
            id: 'p1',
            createdAt: at,
            updatedAt: at,
            status: 'active',
            datingMethod: 'lmp',
            startDate: '2026-04-15',
            dueDate: '2027-01-20',
          ),
        );
    await old
        .into(old.waterLog)
        .insert(
          v7.WaterLogCompanion.insert(
            id: 'w1',
            createdAt: at,
            updatedAt: at,
            pregnancyId: 'p1',
            day: '2026-10-05',
            glasses: 6,
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    expect((await db.select(db.waterLogs).getSingle()).glasses, 6);
    expect(await db.select(db.appLimits).get(), isEmpty);
    await db.close();
  });

  test('v8 → v9 starts how far she has read at where she left off', () async {
    final schema = await verifier.schemaAt(8);
    final old = v8.DatabaseAtV8(schema.newConnection());
    const at = '2026-10-05T00:00:00.000';
    await old
        .into(old.libraryItem)
        .insert(
          v8.LibraryItemCompanion.insert(
            id: 'b1',
            createdAt: at,
            updatedAt: at,
            kind: 'pdf',
            title: 'Stories',
            fileName: 'b1.pdf',
            position: const Value(1),
            total: const Value(2),
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);
    final item = await db.select(db.libraryItems).getSingle();
    expect((item.position, item.furthest, item.total), (1, 1, 2));
    await db.close();
  });

  test('v9 → v10 keeps the library and adds empty links', () async {
    final schema = await verifier.schemaAt(9);
    final old = v9.DatabaseAtV9(schema.newConnection());
    const at = '2026-10-05T00:00:00.000';
    await old
        .into(old.libraryItem)
        .insert(
          v9.LibraryItemCompanion.insert(
            id: 'a1',
            createdAt: at,
            updatedAt: at,
            kind: 'audio',
            title: 'Om',
            fileName: 'a1.mp3',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 10);
    expect((await db.select(db.libraryItems).getSingle()).title, 'Om');
    expect(await db.select(db.mediaLinks).get(), isEmpty);
    await db.close();
  });

  test('v10 → v11 keeps her letters, with no voice notes yet', () async {
    final schema = await verifier.schemaAt(10);
    final old = v10.DatabaseAtV10(schema.newConnection());
    const at = '2026-10-05T00:00:00.000';
    await old
        .into(old.pregnancy)
        .insert(
          v10.PregnancyCompanion.insert(
            id: 'p1',
            createdAt: at,
            updatedAt: at,
            status: 'active',
            datingMethod: 'lmp',
            startDate: '2026-04-15',
            dueDate: '2027-01-20',
          ),
        );
    await old
        .into(old.letter)
        .insert(
          v10.LetterCompanion.insert(
            id: 'l1',
            createdAt: at,
            updatedAt: at,
            pregnancyId: 'p1',
            body: 'Dear little one',
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 11);
    final letter = await db.select(db.letters).getSingle();
    expect(
      (letter.body, letter.voiceFile, letter.voiceSec),
      ('Dear little one', null, null),
    );
    await db.close();
  });
}
