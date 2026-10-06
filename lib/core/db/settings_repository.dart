import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository.g.dart';

abstract final class SettingKeys {
  static const themeMode = 'theme_mode';
  static const firstName = 'first_name';
  static const remindersOn = 'reminders_on';
  static const dailyLimit = 'daily_limit';
  static const quietStart = 'quiet_start';
  static const quietEnd = 'quiet_end';

  /// Set once the app has offered reminders after the first supplement.
  static const remindersOffered = 'reminders_offered';

  /// Reader opens in night colours after 9 pm (default on).
  static const nightReading = 'night_reading';

  /// Walk: daily step goal (default 6,000).
  static const stepGoal = 'step_goal';

  /// Weekly backup reminder: 1 (Monday) to 7 (Sunday, the default), or 0
  /// for off.
  static const backupDay = 'backup_day';

  /// Screen Rest rules (ARCHITECTURE §8). Bedtime rest switches quiet hours
  /// on or off (default on).
  static const quietOn = 'quiet_on';

  /// Meal times (default on): `meal_lunch` / `meal_dinner` start each
  /// 45-minute window (default 1:00 pm and 8:00 pm).
  static const mealRest = 'meal_rest';
  static const mealLunch = 'meal_lunch';
  static const mealDinner = 'meal_dinner';

  /// Eye-rest nudge while reading (default on).
  static const eyeRest = 'eye_rest';

  /// Wind-down audio nudge (default off) at `wind_down_at` (default 9 pm).
  static const windDown = 'wind_down';
  static const windDownAt = 'wind_down_at';

  /// Time in Navmaas today: the day (`yyyy-MM-dd`) and its seconds.
  static const useDay = 'use_day';
  static const useSeconds = 'use_seconds';
}

class SettingsRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<String?> watch(String key) =>
      (_db.select(_db.settings)
            ..where((t) => t.key.equals(key) & t.deletedAt.isNull()))
          .watchSingleOrNull()
          .map((row) => row?.value);

  /// Every live setting as key → value, read once.
  Future<Map<String, String>> getAll() async => {
    for (final r in await (_db.select(
      _db.settings,
    )..where((t) => t.deletedAt.isNull())).get())
      r.key: r.value,
  };

  /// Every live setting as key → value.
  Stream<Map<String, String>> watchAll() =>
      (_db.select(_db.settings)..where((t) => t.deletedAt.isNull()))
          .watch()
          .map((rows) => {for (final r in rows) r.key: r.value});

  Future<void> put(String key, String value) => _db
      .into(_db.settings)
      .insert(
        SettingsCompanion.insert(key: key, value: value),
        onConflict: DoUpdate(
          (_) => SettingsCompanion(
            value: Value(value),
            updatedAt: Value(clockNow()),
            deletedAt: const Value(null),
          ),
          target: [_db.settings.key],
        ),
      );

  /// Soft-deletes [key]; `put` brings it back.
  Future<void> remove(String key) =>
      (_db.update(_db.settings)..where((t) => t.key.equals(key))).write(
        SettingsCompanion(
          deletedAt: Value(clockNow()),
          updatedAt: Value(clockNow()),
        ),
      );
}

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<String?> firstName(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(SettingKeys.firstName);

/// "Night reading after 9 pm" (Me → Appearance); on unless switched off.
@riverpod
Stream<bool> nightReading(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.nightReading)
    .map((v) => v != 'false');

/// The daily step goal she set on the Walk screen.
@riverpod
Stream<int> stepGoal(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.stepGoal)
    .map((v) => int.tryParse(v ?? '') ?? defaultStepGoal);

const defaultStepGoal = 6000;

/// The weekly backup reminder's day (`DateTime.monday` … `DateTime.sunday`),
/// or 0 when off. Sunday by default (Plan decision 32).
@riverpod
Stream<int> backupDay(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.backupDay)
    .map((v) => int.tryParse(v ?? '') ?? DateTime.sunday);
