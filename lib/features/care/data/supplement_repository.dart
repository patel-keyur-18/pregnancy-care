import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supplement_repository.g.dart';

/// One time of day for a supplement, as edited on the form.
typedef DoseTime = ({
  String? id,
  int minuteOfDay,
  int weekdayMask,
  String? label,
});

class SupplementRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Live supplements with their live schedules, by name.
  Stream<List<SupplementPlan>> watchPlans(String pregnancyId) {
    final query =
        _db.select(_db.supplements).join([
            leftOuterJoin(
              _db.supplementSchedules,
              _db.supplementSchedules.supplementId.equalsExp(
                    _db.supplements.id,
                  ) &
                  _db.supplementSchedules.deletedAt.isNull(),
            ),
          ])
          ..where(
            _db.supplements.pregnancyId.equals(pregnancyId) &
                _db.supplements.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(_db.supplements.name)]);
    return query.watch().map((rows) {
      final plans = <String, SupplementPlan>{};
      for (final row in rows) {
        final s = row.readTable(_db.supplements);
        final plan = plans.putIfAbsent(
          s.id,
          () => (supplement: s, schedules: <SupplementSchedule>[]),
        );
        final schedule = row.readTableOrNull(_db.supplementSchedules);
        if (schedule != null) plan.schedules.add(schedule);
      }
      for (final p in plans.values) {
        p.schedules.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
      }
      return plans.values.toList();
    });
  }

  /// Creates or updates a supplement and replaces its times.
  Future<String> save({
    required String pregnancyId,
    required String name,
    required List<DoseTime> times,
    String? id,
    String doseText = '',
    String? notes,
    int? stock,
    int? refillAt,
  }) => _db.transaction(() async {
    final now = DateTime.now();
    final row = SupplementsCompanion(
      pregnancyId: Value(pregnancyId),
      name: Value(name.trim()),
      doseText: Value(doseText.trim()),
      notes: Value(notes == null || notes.trim().isEmpty ? null : notes.trim()),
      stock: Value(stock),
      refillAt: Value(refillAt),
      updatedAt: Value(now),
    );
    final supplementId =
        id ?? (await _db.into(_db.supplements).insertReturning(row)).id;
    if (id != null) {
      await (_db.update(
        _db.supplements,
      )..where((t) => t.id.equals(id))).write(row);
    }
    final kept = {for (final t in times) ?t.id};
    await (_db.update(_db.supplementSchedules)..where(
          (t) =>
              t.supplementId.equals(supplementId) &
              t.deletedAt.isNull() &
              t.id.isNotIn(kept),
        ))
        .write(SupplementSchedulesCompanion(deletedAt: Value(now)));
    for (final t in times) {
      final schedule = SupplementSchedulesCompanion(
        supplementId: Value(supplementId),
        minuteOfDay: Value(t.minuteOfDay),
        weekdayMask: Value(t.weekdayMask),
        label: Value(
          t.label == null || t.label!.trim().isEmpty ? null : t.label!.trim(),
        ),
        updatedAt: Value(now),
      );
      if (t.id == null) {
        await _db.into(_db.supplementSchedules).insert(schedule);
      } else {
        await (_db.update(
          _db.supplementSchedules,
        )..where((s) => s.id.equals(t.id!))).write(schedule);
      }
    }
    return supplementId;
  });

  /// Removes a supplement and its times (soft delete; logs stay).
  Future<void> remove(String id) => _db.transaction(() async {
    final gone = Value<DateTime?>(DateTime.now());
    await (_db.update(_db.supplements)..where((t) => t.id.equals(id))).write(
      SupplementsCompanion(deletedAt: gone),
    );
    await (_db.update(_db.supplementSchedules)
          ..where((t) => t.supplementId.equals(id)))
        .write(SupplementSchedulesCompanion(deletedAt: gone));
  });

  /// Keys (`DoseSlot.key`) of doses taken with a due time in [from, to).
  Stream<Set<String>> watchTaken(DateTime from, DateTime to) =>
      (_db.select(_db.doseLogs)..where(
            (t) =>
                t.deletedAt.isNull() &
                t.status.equalsValue(DoseStatus.taken) &
                t.dueAt.isBiggerOrEqualValue(from) &
                t.dueAt.isSmallerThanValue(to),
          ))
          .watch()
          .map(
            (rows) => {
              for (final r in rows)
                '${r.scheduleId}@${r.dueAt.toLocal().toIso8601String()}',
            },
          );

  /// Marks one dose taken or not; each change moves the stock by one.
  Future<void> setTaken(
    String scheduleId,
    DateTime dueAt, {
    required bool taken,
  }) => _db.transaction(() async {
    final existing =
        await (_db.select(_db.doseLogs)..where(
              (t) => t.scheduleId.equals(scheduleId) & t.dueAt.equals(dueAt),
            ))
            .getSingleOrNull();
    final wasTaken = existing != null && existing.deletedAt == null;
    if (wasTaken == taken) return;
    final now = DateTime.now();
    if (existing == null) {
      await _db
          .into(_db.doseLogs)
          .insert(
            DoseLogsCompanion.insert(
              scheduleId: scheduleId,
              dueAt: dueAt,
              status: DoseStatus.taken,
              takenAt: Value(now),
            ),
          );
    } else {
      await (_db.update(
        _db.doseLogs,
      )..where((t) => t.id.equals(existing.id))).write(
        DoseLogsCompanion(
          deletedAt: Value(taken ? null : now),
          takenAt: Value(taken ? now : null),
          updatedAt: Value(now),
        ),
      );
    }
    final supplementId = (await (_db.select(
      _db.supplementSchedules,
    )..where((t) => t.id.equals(scheduleId))).getSingle()).supplementId;
    await _db.customUpdate(
      'UPDATE supplement SET stock = MAX(stock + ?, 0) '
      'WHERE id = ? AND stock IS NOT NULL',
      variables: [
        Variable.withInt(taken ? -1 : 1),
        Variable.withString(supplementId),
      ],
      updates: {_db.supplements},
    );
  });
}

@riverpod
SupplementRepository supplementRepository(Ref ref) =>
    SupplementRepository(ref.watch(appDatabaseProvider));

/// Supplements of the active pregnancy.
@riverpod
Stream<List<SupplementPlan>> supplementPlans(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(supplementRepositoryProvider).watchPlans(id);
}

/// Keys of doses taken with due times in [from, to) (local dates).
@riverpod
Stream<Set<String>> takenDoses(Ref ref, DateTime from, DateTime to) =>
    ref.watch(supplementRepositoryProvider).watchTaken(from, to);
