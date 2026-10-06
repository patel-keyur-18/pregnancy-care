import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/domain/week.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late WellbeingRepository repo;
  late String id;
  final today = DateTime.utc(2026, 10, 5);
  final from = DateTime.utc(2026, 9, 29);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WellbeingRepository(db);
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    id = (await db.select(db.pregnancies).getSingle()).id;
  });
  tearDown(() => db.close());

  test('one mood a day: saving again changes it', () async {
    await repo.setMood(pregnancyId: id, day: today, mood: .tired);
    await repo.setMood(
      pregnancyId: id,
      day: today,
      mood: .calm,
      note: 'Slept well',
    );
    await repo.setMood(
      pregnancyId: id,
      day: today.subtract(const Duration(days: 1)),
      mood: .low,
    );
    final moods = await repo.watchMoods(id, from).first;
    expect(moods, hasLength(2));
    final t = moods.firstWhere((m) => m.day == today);
    expect((t.mood, t.note), (MoodWord.calm, 'Slept well'));
  });

  test('symptoms: a pick-list key or her own name, removable', () async {
    await repo.addSymptom(
      pregnancyId: id,
      kind: .backache,
      severity: .mild,
      at: DateTime(2026, 10, 5, 14, 15),
    );
    await repo.addSymptom(
      pregnancyId: id,
      customName: 'Itchy skin',
      severity: .strong,
      note: 'Evening',
      at: DateTime(2026, 10, 5, 20),
    );
    await repo.addSymptom(
      pregnancyId: id,
      kind: .nausea,
      severity: .moderate,
      at: DateTime(2026, 9, 20),
    );
    final week = await repo.watchSymptoms(id, from: from).first;
    expect(week.map((s) => s.customName ?? s.symptomKey!.name), [
      'Itchy skin',
      'backache',
    ]);
    await repo.removeSymptom(week.first.id);
    expect(await repo.watchSymptoms(id, from: from).first, hasLength(1));
    expect(await repo.watchSymptoms(id).first, hasLength(2));
  });

  test('sleep: one night per wake-up day, replaced on save', () async {
    Future<void> save(int napMinutes) => repo.saveSleep(
      pregnancyId: id,
      day: today,
      bedAt: DateTime(2026, 10, 4, 22, 40),
      wokeAt: DateTime(2026, 10, 5, 6, 25),
      napMinutes: napMinutes,
      rested: .bitTired,
    );
    await save(0);
    await save(30);
    final nights = await repo.watchSleep(id, from).first;
    expect(nights, hasLength(1));
    expect(sleepMinutes(nights.single), 7 * 60 + 45 + 30);
    expect(nights.single.rested, Rested.bitTired);
  });

  test('water: glasses add up per day and never go below zero', () async {
    await repo.addWater(pregnancyId: id, day: today);
    await repo.addWater(pregnancyId: id, day: today);
    await repo.addWater(pregnancyId: id, day: today, delta: -1);
    await repo.addWater(
      pregnancyId: id,
      day: today.subtract(const Duration(days: 1)),
      delta: -1,
    );
    final logs = await repo.watchWater(id, from).first;
    expect({for (final w in logs) w.day.day: w.glasses}, {5: 1, 4: 0});
  });

  test('the week puts each log on its own day, today first', () async {
    await repo.setMood(pregnancyId: id, day: today, mood: .happy);
    await repo.addWater(pregnancyId: id, day: today);
    await repo.addSymptom(
      pregnancyId: id,
      kind: .heartburn,
      severity: .moderate,
      at: DateTime(2026, 10, 3, 21),
    );
    await repo.saveSleep(
      pregnancyId: id,
      day: DateTime.utc(2026, 10, 3),
      bedAt: DateTime(2026, 10, 2, 23),
      wokeAt: DateTime(2026, 10, 3, 6),
    );
    final week = weekOf(
      today,
      moods: await repo.watchMoods(id, from).first,
      symptoms: await repo.watchSymptoms(id, from: from).first,
      sleeps: await repo.watchSleep(id, from).first,
      water: await repo.watchWater(id, from).first,
    );
    expect(week.map((d) => d.day.day), [5, 4, 3, 2, 1, 30, 29]);
    expect((week[0].mood?.mood, week[0].glasses), (MoodWord.happy, 1));
    expect(week[1].isEmpty, isTrue);
    expect(week[2].symptoms.single.symptomKey, SymptomKind.heartburn);
    expect(sleepMinutes(week[2].sleep!), 7 * 60);
  });

  test('sleep average counts naps; none logged is null', () {
    SleepLog night(int hours, int nap) => SleepLog(
      id: '',
      createdAt: today,
      updatedAt: today,
      pregnancyId: id,
      day: today,
      bedAt: DateTime(2026, 10, 4, 22),
      wokeAt: DateTime(2026, 10, 4, 22 + hours),
      napMinutes: nap,
    );
    expect(averageSleepMinutes(const []), isNull);
    expect(averageSleepMinutes([night(7, 0), night(8, 30)]), 7 * 60 + 45);
  });
}
