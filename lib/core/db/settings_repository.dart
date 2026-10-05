import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
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
            updatedAt: Value(DateTime.now()),
            deletedAt: const Value(null),
          ),
          target: [_db.settings.key],
        ),
      );

  /// Soft-deletes [key]; `put` brings it back.
  Future<void> remove(String key) =>
      (_db.update(_db.settings)..where((t) => t.key.equals(key))).write(
        SettingsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
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
