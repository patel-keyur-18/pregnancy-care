import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

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
}
