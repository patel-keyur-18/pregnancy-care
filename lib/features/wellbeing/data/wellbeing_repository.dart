import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/wellbeing/domain/week.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wellbeing_repository.g.dart';

const _day = DateOnlyConverter();

/// Mood, symptoms, sleep and water (M7). A log for her and her doctor:
/// nothing here scores or judges what she wrote.
class WellbeingRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Today's check-in; saving again the same day changes it.
  Future<void> setMood({
    required String pregnancyId,
    required DateTime day,
    required MoodWord mood,
    String? note,
  }) => _db
      .into(_db.moodEntries)
      .insert(
        MoodEntriesCompanion.insert(
          pregnancyId: pregnancyId,
          day: day,
          mood: mood,
          note: Value(note),
        ),
        onConflict: DoUpdate(
          (_) => MoodEntriesCompanion(
            mood: Value(mood),
            note: Value(note),
            deletedAt: const Value(null),
            updatedAt: Value(clockNow()),
          ),
          target: [_db.moodEntries.pregnancyId, _db.moodEntries.day],
        ),
      );

  Future<void> addSymptom({
    required String pregnancyId,
    required Severity severity,
    SymptomKind? kind,
    String? customName,
    String? note,
    DateTime? at,
  }) {
    assert((kind == null) != (customName == null), 'a key or her own name');
    return _db
        .into(_db.symptomEntries)
        .insert(
          SymptomEntriesCompanion.insert(
            pregnancyId: pregnancyId,
            loggedAt: at ?? clockNow(),
            symptomKey: Value(kind),
            customName: Value(customName),
            severity: severity,
            note: Value(note),
          ),
        );
  }

  Future<void> removeSymptom(String id) =>
      (_db.update(_db.symptomEntries)..where((t) => t.id.equals(id))).write(
        SymptomEntriesCompanion(
          deletedAt: Value(clockNow()),
          updatedAt: Value(clockNow()),
        ),
      );

  /// The night that ended on [day]; saving again replaces it.
  Future<void> saveSleep({
    required String pregnancyId,
    required DateTime day,
    required DateTime bedAt,
    required DateTime wokeAt,
    int napMinutes = 0,
    Rested? rested,
  }) => _db
      .into(_db.sleepLogs)
      .insert(
        SleepLogsCompanion.insert(
          pregnancyId: pregnancyId,
          day: day,
          bedAt: bedAt,
          wokeAt: wokeAt,
          napMinutes: Value(napMinutes),
          rested: Value(rested),
        ),
        onConflict: DoUpdate(
          (_) => SleepLogsCompanion(
            bedAt: Value(bedAt),
            wokeAt: Value(wokeAt),
            napMinutes: Value(napMinutes),
            rested: Value(rested),
            deletedAt: const Value(null),
            updatedAt: Value(clockNow()),
          ),
          target: [_db.sleepLogs.pregnancyId, _db.sleepLogs.day],
        ),
      );

  /// Adds [delta] glasses (−1 takes one away) to [day], never below zero.
  Future<void> addWater({
    required String pregnancyId,
    required DateTime day,
    int delta = 1,
  }) => _db.transaction(() async {
    final row =
        await (_db.select(_db.waterLogs)..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.day.equalsValue(day),
            ))
            .getSingleOrNull();
    final glasses = ((row?.glasses ?? 0) + delta).clamp(0, 99);
    await _db
        .into(_db.waterLogs)
        .insert(
          WaterLogsCompanion.insert(
            pregnancyId: pregnancyId,
            day: day,
            glasses: glasses,
          ),
          onConflict: DoUpdate(
            (_) => WaterLogsCompanion(
              glasses: Value(glasses),
              updatedAt: Value(clockNow()),
            ),
            target: [_db.waterLogs.pregnancyId, _db.waterLogs.day],
          ),
        );
  });

  Stream<List<MoodEntry>> watchMoods(String pregnancyId, DateTime from) =>
      (_db.select(_db.moodEntries)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.day.isBiggerOrEqualValue(_day.toSql(from)),
          ))
          .watch();

  /// Symptoms logged from the local start of [from], newest first.
  Stream<List<SymptomEntry>> watchSymptoms(
    String pregnancyId, {
    DateTime? from,
    int? limit,
  }) {
    final q = _db.select(_db.symptomEntries)
      ..where(
        (t) =>
            t.pregnancyId.equals(pregnancyId) &
            t.deletedAt.isNull() &
            (from == null
                ? const Constant(true)
                : t.loggedAt.isBiggerOrEqualValue(localDay(from))),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Stream<List<SleepLog>> watchSleep(String pregnancyId, DateTime from) =>
      (_db.select(_db.sleepLogs)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.day.isBiggerOrEqualValue(_day.toSql(from)),
          ))
          .watch();

  Stream<List<WaterLog>> watchWater(String pregnancyId, DateTime from) =>
      (_db.select(_db.waterLogs)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.day.isBiggerOrEqualValue(_day.toSql(from)),
          ))
          .watch();
}

@riverpod
WellbeingRepository wellbeingRepository(Ref ref) =>
    WellbeingRepository(ref.watch(appDatabaseProvider));

/// First day of the 7-day view (today and the 6 before it).
DateTime _weekStart(Ref ref) => addDays(ref.watch(todayProvider), -6);

@riverpod
Stream<List<MoodEntry>> weekMoods(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(wellbeingRepositoryProvider).watchMoods(id, _weekStart(ref));
}

@riverpod
Stream<List<SymptomEntry>> weekSymptoms(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref
      .watch(wellbeingRepositoryProvider)
      .watchSymptoms(id, from: _weekStart(ref));
}

@riverpod
Stream<List<SleepLog>> weekSleep(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(wellbeingRepositoryProvider).watchSleep(id, _weekStart(ref));
}

@riverpod
Stream<List<WaterLog>> weekWater(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(wellbeingRepositoryProvider).watchWater(id, _weekStart(ref));
}

/// The last 7 days, today first.
@riverpod
List<WellbeingDay> wellbeingWeek(Ref ref) => weekOf(
  ref.watch(todayProvider),
  moods: ref.watch(weekMoodsProvider).value ?? const [],
  symptoms: ref.watch(weekSymptomsProvider).value ?? const [],
  sleeps: ref.watch(weekSleepProvider).value ?? const [],
  water: ref.watch(weekWaterProvider).value ?? const [],
);

/// Her latest symptom logs (newest first), to put her usual ones first.
@riverpod
Stream<List<SymptomEntry>> recentSymptoms(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(wellbeingRepositoryProvider).watchSymptoms(id, limit: 100);
}

/// Daily water goal in glasses (Plan decision 41: default 8, 4–16).
@riverpod
Stream<int> waterGoal(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.waterGoal)
    .map((v) => int.tryParse(v ?? '') ?? defaultWaterGoal);

/// The day (`yyyy-MM-dd`) Today's wellbeing card was closed, if any.
@riverpod
Stream<String?> wellbeingCardHidden(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.wellbeingCardHidden);

/// Whether today's glasses have reached the goal (skips today's water
/// nudges). Changes only when it flips, so each glass doesn't re-plan.
@riverpod
bool waterGoalReached(Ref ref) =>
    ref.watch(wellbeingWeekProvider).first.glasses >=
    (ref.watch(waterGoalProvider).value ?? defaultWaterGoal);

const defaultWaterGoal = 8;
const minWaterGoal = 4;
const maxWaterGoal = 16;
