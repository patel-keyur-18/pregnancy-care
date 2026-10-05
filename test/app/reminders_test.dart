import 'dart:ui' show Locale;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/care/domain/supplement_reminders.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

import '../helpers.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

Future<(AppDatabase, String)> _db() async {
  final db = AppDatabase(NativeDatabase.memory());
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  return (db, (await db.select(db.pregnancies).getSingle()).id);
}

/// Adds Iron at 21:00 daily, back-dated so tests don't depend on today.
Future<void> _addIron(
  AppDatabase db,
  String pregnancyId, {
  int? stock,
  int? refillAt,
}) async {
  await SupplementRepository(db).save(
    pregnancyId: pregnancyId,
    name: 'Iron',
    doseText: '1 tablet',
    stock: stock,
    refillAt: refillAt,
    times: [
      (id: null, minuteOfDay: 21 * 60, weekdayMask: 127, label: 'after dinner'),
    ],
  );
  await db
      .update(db.supplements)
      .write(SupplementsCompanion(createdAt: Value(DateTime(2026))));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('supplement candidates', () {
    test('one per untaken dose with dose and label; refill at 10:00', () async {
      final (db, id) = await _db();
      addTearDown(db.close);
      await _addIron(db, id, stock: 3, refillAt: 5);
      final plans = await SupplementRepository(db).watchPlans(id).first;
      final now = DateTime.now();
      final today = slotsOn(now, plans).single;

      final all = supplementCandidates(
        now: now,
        plans: plans,
        takenKeys: {},
        l10n: l10n,
        days: 2,
      );
      final doses = all.where((c) => c.key.startsWith(doseKeyPrefix)).toList();
      expect(doses, hasLength(2));
      expect(
        (doses.first.title, doses.first.body),
        ('Iron', '1 tablet · after dinner'),
      );
      final refill = all.singleWhere((c) => c.key.startsWith('refill:'));
      expect(
        (refill.title, refill.body, refill.at.hour),
        ('Iron: refill soon', '3 doses left', 10),
      );

      final afterTaking = supplementCandidates(
        now: now,
        plans: plans,
        takenKeys: {today.key},
        l10n: l10n,
        days: 2,
      ).where((c) => c.key.startsWith(doseKeyPrefix));
      expect(afterTaking, hasLength(1));
      expect(parseDoseKey(doses.first.key), (
        scheduleId: today.schedule.id,
        dueAt: today.dueAt,
      ));
    });
  });

  group('notification actions', () {
    test('"Taken" logs every dose in the reminder', () async {
      final (db, id) = await _db();
      addTearDown(db.close);
      await _addIron(db, id, stock: 10);
      final repo = SupplementRepository(db);
      final slot = slotsOn(
        DateTime.now(),
        await repo.watchPlans(id).first,
      ).single;
      final payload = ReminderPayload(
        keys: ['$doseKeyPrefix${slot.key}', 'refill:x@y'],
        title: 'Iron',
        body: '1 tablet',
        actions: true,
      );
      await applyReminderAction(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: ReminderAction.taken,
          payload: payload.toJson(),
        ),
        supplements: repo,
        scheduler: FakeScheduler(),
      );
      final day = DateTime(slot.dueAt.year, slot.dueAt.month, slot.dueAt.day);
      expect(
        await repo.watchTaken(day, day.add(const Duration(days: 1))).first,
        {slot.key},
      );
      expect((await repo.watchPlans(id).first).single.supplement.stock, 9);
    });

    test('"Snooze" re-shows the same reminder', () async {
      final scheduler = FakeScheduler();
      const payload = ReminderPayload(
        keys: ['dose:a@b'],
        title: 'Iron',
        body: '1 tablet',
        actions: true,
      );
      final (db, _) = await _db();
      addTearDown(db.close);
      await applyReminderAction(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: ReminderAction.snooze,
          payload: payload.toJson(),
        ),
        supplements: SupplementRepository(db),
        scheduler: scheduler,
      );
      expect(scheduler.snoozed.single.toJson(), payload.toJson());
    });
  });

  testWidgets('the app keeps the OS schedule in step with settings', (
    tester,
  ) async {
    final scheduler = FakeScheduler();
    final db = await pumpApp(
      tester,
      scheduler: scheduler,
      seed: (db) async {
        await PregnancyRepository(db)
            .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
        final id = (await db.select(db.pregnancies).getSingle()).id;
        await _addIron(db, id);
      },
    );
    expect(
      scheduler.scheduled,
      isEmpty,
      reason: 'reminders are off by default',
    );

    await tester.runAsync(
      () => SettingsRepository(db).put(SettingKeys.remindersOn, 'true'),
    );
    await tester.pumpAndSettle();
    expect(scheduler.scheduled, isNotEmpty);
    expect(scheduler.scheduled.first.items.single.title, 'Iron');
    expect(scheduler.scheduled.first.at.hour, 21);

    await tester.runAsync(
      () => SettingsRepository(db).put(SettingKeys.remindersOn, 'false'),
    );
    await tester.pumpAndSettle();
    expect(scheduler.scheduled, isEmpty);
  });
}
