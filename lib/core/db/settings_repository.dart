import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository.g.dart';

abstract final class SettingKeys {
  static const themeMode = 'theme_mode';
  static const firstName = 'first_name';
}

class SettingsRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<String?> watch(String key) =>
      (_db.select(_db.settings)
            ..where((t) => t.key.equals(key) & t.deletedAt.isNull()))
          .watchSingleOrNull()
          .map((row) => row?.value);

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
}

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<String?> firstName(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(SettingKeys.firstName);
