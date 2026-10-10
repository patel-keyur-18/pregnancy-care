import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/nutrition/data/avoid_food_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late String pregnancyId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pregnancyId = (await db.select(db.pregnancies).getSingle()).id;
  });
  tearDown(() => db.close());

  test(
    'foods she avoids: add with a reason, edit, remove; blanks refused',
    () async {
      final repo = AvoidFoodRepository(db);
      await repo.save(
        pregnancyId: pregnancyId,
        name: ' Papaya ',
        reason: "doctor's advice",
      );
      await repo.save(pregnancyId: pregnancyId, name: '  ');
      var list = await repo.watch(pregnancyId).first;
      expect(list.map((f) => (f.name, f.reason)), [
        ('Papaya', "doctor's advice"),
      ]);
      await repo.save(
        id: list.single.id,
        pregnancyId: pregnancyId,
        name: 'Raw papaya',
        reason: ' ',
      );
      list = await repo.watch(pregnancyId).first;
      expect(list.map((f) => (f.name, f.reason)), [('Raw papaya', null)]);
      await repo.delete(list.single.id);
      expect(await repo.watch(pregnancyId).first, isEmpty);
    },
  );

  test('removing a food stamps when it changed', () async {
    final repo = AvoidFoodRepository(db);
    await repo.save(pregnancyId: pregnancyId, name: 'Papaya');
    final id = (await repo.watch(pregnancyId).first).single.id;
    final later = DateTime(2026, 10, 6, 8);
    clockNow = () => later;
    addTearDown(() => clockNow = DateTime.now);
    await repo.delete(id);
    final row = await db.select(db.avoidFoods).getSingle();
    expect(row.deletedAt, later);
    expect(row.updatedAt, later);
  });
}
