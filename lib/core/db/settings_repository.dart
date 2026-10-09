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

  /// Walk: the walk she started and hasn't finished (`WalkDraft` JSON).
  static const walkDraft = 'walk_draft';

  /// Weekly backup reminder: 1 (Monday) to 7 (Sunday, the default), or 0
  /// for off.
  static const backupDay = 'backup_day';

  /// Backups include voice letters (E3; default off, remembered).
  static const backupVoice = 'backup_voice';

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

  /// Wellbeing (M7): daily water goal in glasses (default 8), water
  /// reminders (default off) every `water_every` hours (2 or 3, default 2),
  /// and the day (`yyyy-MM-dd`) Today's "How are you today?" card was hidden.
  static const waterGoal = 'water_goal';
  static const waterRemind = 'water_remind';
  static const waterEvery = 'water_every';
  static const wellbeingCardHidden = 'wellbeing_card_hidden';

  /// Home-screen widget (M10): "Hide details on widget" in Me (Plan
  /// decision 47; off unless set).
  static const widgetHide = 'widget_hide';

  /// App lock (M10b, Plan decision 48): on or off (default off), and the
  /// minutes away before it locks again (1, 5 or 15; default 1).
  static const appLock = 'app_lock';
  static const appLockAfter = 'app_lock_after';
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

/// "Hide details on widget" (Me → Your data). Unless she has set it, it
/// follows app lock: off, or on while app lock is on (Plan decision 47).
@Riverpod(keepAlive: true)
Stream<bool> widgetHideDetails(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watchAll()
    .map(
      (s) => switch (s[SettingKeys.widgetHide]) {
        final v? => v == 'true',
        null => s[SettingKeys.appLock] == 'true',
      },
    )
    .distinct();

/// App lock: on, and the minutes away before it locks again.
typedef AppLockSettings = ({bool on, int after});

/// App lock's choices of minutes away (Plan decision 48).
const appLockMinutes = [1, 5, 15];

@Riverpod(keepAlive: true)
Stream<AppLockSettings> appLockSettings(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watchAll()
    .map(
      (s) => (
        on: s[SettingKeys.appLock] == 'true',
        after: int.tryParse(s[SettingKeys.appLockAfter] ?? '') ?? 1,
      ),
    )
    .distinct();

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

/// "Include voice letters" in backups (E3; default off).
@riverpod
Stream<bool> backupVoice(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.backupVoice)
    .map((v) => v == 'true');
