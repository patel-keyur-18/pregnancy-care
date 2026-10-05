import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/profile_repository.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late SupplementRepository repo;
  late String pregnancyId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = SupplementRepository(db);
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pregnancyId = (await db.select(db.pregnancies).getSingle()).id;
  });
  tearDown(() => db.close());

  test('profile: one row, blanks stored as null', () async {
    final profile = ProfileRepository(db);
    await profile.save(doctorName: 'Dr. Mehta', clinicPhone: '  ');
    await profile.save(doctorName: ' Dr. Rao ', clinicName: 'City Clinic');
    final rows = await db.select(db.profiles).get();
    expect(rows, hasLength(1));
    expect(
      (rows.single.doctorName, rows.single.clinicName, rows.single.clinicPhone),
      ('Dr. Rao', 'City Clinic', null),
    );
  });

  group('reminder settings', () {
    test('defaults: off, 4 a day, quiet 9:30 pm – 7:00 am', () {
      const s = ReminderSettings();
      expect(
        (s.on, s.dailyLimit, s.quietStart, s.quietEnd),
        (false, 4, 1290, 420),
      );
    });
    test('quiet hours across midnight, start inclusive, end exclusive', () {
      const s = ReminderSettings();
      const minutes = [21 * 60, 21 * 60 + 30, 30, 6 * 60 + 59, 7 * 60, 12 * 60];
      expect(
        [for (final m in minutes) s.isQuiet(m)],
        [false, true, true, true, false, false],
      );
    });
    test('quiet hours within one day', () {
      const s = ReminderSettings(quietStart: 13 * 60, quietEnd: 15 * 60);
      expect(
        [s.isQuiet(12 * 60 + 59), s.isQuiet(13 * 60), s.isQuiet(15 * 60)],
        [false, true, false],
      );
    });
  });

  test('save, edit times, remove', () async {
    final id = await repo.save(
      pregnancyId: pregnancyId,
      name: 'Iron',
      doseText: '1 tablet',
      times: [
        (
          id: null,
          minuteOfDay: 21 * 60,
          weekdayMask: 127,
          label: 'after dinner',
        ),
        (id: null, minuteOfDay: 9 * 60, weekdayMask: 127, label: null),
      ],
    );
    var plan = (await repo.watchPlans(pregnancyId).first).single;
    expect(plan.schedules.map((s) => s.minuteOfDay), [540, 1260]);

    final keep = plan.schedules.first;
    await repo.save(
      id: id,
      pregnancyId: pregnancyId,
      name: 'Iron + folic acid',
      times: [
        (id: keep.id, minuteOfDay: 8 * 60, weekdayMask: 0x1F, label: null),
      ],
    );
    plan = (await repo.watchPlans(pregnancyId).first).single;
    expect(plan.supplement.name, 'Iron + folic acid');
    expect(plan.schedules.single.id, keep.id);
    expect(
      (plan.schedules.single.minuteOfDay, plan.schedules.single.weekdayMask),
      (480, 0x1F),
    );

    await repo.remove(id);
    expect(await repo.watchPlans(pregnancyId).first, isEmpty);
  });

  test('slots: weekdays, start day, order; taken keys round-trip', () async {
    await repo.save(
      pregnancyId: pregnancyId,
      name: 'Calcium',
      stock: 2,
      times: [(id: null, minuteOfDay: 13 * 60, weekdayMask: 1, label: null)],
    );
    await repo.save(
      pregnancyId: pregnancyId,
      name: 'Folic acid',
      times: [(id: null, minuteOfDay: 9 * 60, weekdayMask: 127, label: null)],
    );
    final plans = await repo.watchPlans(pregnancyId).first;
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: 8 - today.weekday)); // next Monday
    final tuesday = monday.add(const Duration(days: 1));
    expect(slotsOn(monday, plans).map((s) => s.supplement.name), [
      'Folic acid',
      'Calcium',
    ]);
    expect(slotsOn(tuesday, plans).map((s) => s.supplement.name), [
      'Folic acid',
    ]);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    expect(slotsOn(yesterday, plans), isEmpty, reason: 'added today');

    final calcium = slotsOn(monday, plans).last;
    await repo.setTaken(calcium.schedule.id, calcium.dueAt, taken: true);
    await repo.setTaken(calcium.schedule.id, calcium.dueAt, taken: true);
    final taken = await repo.watchTaken(monday, tuesday).first;
    expect(taken, {calcium.key});
    expect(
      adherence([monday, tuesday], plans, taken).map((d) => (d.due, d.taken)),
      [(2, 1), (1, 0)],
    );

    Future<int?> stock() async =>
        (await repo.watchPlans(pregnancyId).first).first.supplement.stock;
    expect(await stock(), 1, reason: 'taken twice counts once');
    await repo.setTaken(calcium.schedule.id, calcium.dueAt, taken: false);
    expect(await stock(), 2);
    expect(await repo.watchTaken(monday, tuesday).first, isEmpty);
  });
}
