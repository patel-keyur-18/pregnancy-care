import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pregnancy_repository.g.dart';

class PregnancyRepository {
  const new(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$PregnanciesTable, Pregnancy> _active() =>
      _db.select(_db.pregnancies)
        ..where(
          (t) =>
              t.status.equalsValue(PregnancyStatus.active) &
              t.deletedAt.isNull(),
        )
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(1);

  Stream<Pregnancy?> watchActive() => _active().watchSingleOrNull();

  /// The newest pregnancy, whatever its status: the router shows a calm
  /// "tracking stopped" page when it isn't active.
  Stream<Pregnancy?> watchLatest() =>
      (_db.select(_db.pregnancies)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .watchSingleOrNull();

  /// Me → "Pause or end pregnancy tracking", and Resume. Anything but
  /// active stops baby content and pregnancy reminders at once, because
  /// every feature reads only the active pregnancy.
  Future<void> setStatus(String id, PregnancyStatus status) =>
      (_db.update(_db.pregnancies)..where((t) => t.id.equals(id))).write(
        PregnanciesCompanion(
          status: Value(status),
          updatedAt: Value(clockNow()),
        ),
      );

  /// Creates the active pregnancy, or re-dates it if one exists.
  Future<void> saveDating({
    required DatingMethod method,
    required DateTime date,
    int cycleLength = 28,
    int embryoDay = 5,
  }) {
    final start = pregnancyStart(
      method: method,
      date: date,
      cycleLength: cycleLength,
      embryoDay: embryoDay,
    );
    final isLmp = method == DatingMethod.lmp;
    final row = PregnanciesCompanion(
      datingMethod: Value(method),
      lmp: Value(isLmp ? date : null),
      cycleLength: Value(isLmp ? cycleLength : null),
      anchorDate: Value(isLmp ? null : date),
      embryoDay: Value(method == DatingMethod.ivf ? embryoDay : null),
      startDate: Value(start),
      dueDate: Value(addDays(start, pregnancyLengthDays)),
      updatedAt: Value(clockNow()),
    );
    return _db.transaction(() async {
      final current = await _active().getSingleOrNull();
      if (current == null) {
        await _db
            .into(_db.pregnancies)
            .insert(row.copyWith(status: const Value(PregnancyStatus.active)));
      } else {
        await (_db.update(
          _db.pregnancies,
        )..where((t) => t.id.equals(current.id))).write(row);
      }
    });
  }

  /// Me → Exercise: "Doctor cleared me for exercise" and "High-risk
  /// pregnancy". Exercise routines stay locked until cleared; high risk
  /// hides the routines marked for extra caution. Walking is always open.
  Future<void> setFlags(String id, {bool? exerciseCleared, bool? highRisk}) =>
      (_db.update(_db.pregnancies)..where((t) => t.id.equals(id))).write(
        PregnanciesCompanion(
          exerciseCleared: Value.absentIfNull(exerciseCleared),
          highRisk: Value.absentIfNull(highRisk),
          updatedAt: Value(clockNow()),
        ),
      );
}

@riverpod
PregnancyRepository pregnancyRepository(Ref ref) =>
    PregnancyRepository(ref.watch(appDatabaseProvider));

/// Kept alive: the router's onboarding redirect depends on it.
@Riverpod(keepAlive: true)
Stream<Pregnancy?> activePregnancy(Ref ref) =>
    ref.watch(pregnancyRepositoryProvider).watchActive();

/// The newest pregnancy in any status. Kept alive for the router.
@Riverpod(keepAlive: true)
Stream<Pregnancy?> latestPregnancy(Ref ref) =>
    ref.watch(pregnancyRepositoryProvider).watchLatest();
