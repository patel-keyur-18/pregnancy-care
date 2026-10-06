import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_limits.g.dart';

/// Daily limits on other apps (M11, Android only; Plan decisions 51–53).
class AppLimitsRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Live limits, by app name.
  Stream<List<AppLimit>> watch() =>
      (_db.select(_db.appLimits)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.label.lower())]))
          .watch();

  /// Sets [package]'s limit (a removed one comes back).
  Future<void> save({
    required String package,
    required String label,
    required int minutes,
  }) => _db
      .into(_db.appLimits)
      .insert(
        AppLimitsCompanion.insert(
          package: package,
          label: label,
          minutes: minutes,
        ),
        onConflict: DoUpdate(
          (_) => AppLimitsCompanion(
            label: Value(label),
            minutes: Value(minutes),
            updatedAt: Value(clockNow()),
            deletedAt: const Value(null),
          ),
          target: [_db.appLimits.package],
        ),
      );

  Future<void> remove(String package) =>
      (_db.update(
        _db.appLimits,
      )..where((t) => t.package.equals(package))).write(
        AppLimitsCompanion(
          deletedAt: Value(clockNow()),
          updatedAt: Value(clockNow()),
        ),
      );
}

@riverpod
AppLimitsRepository appLimitsRepository(Ref ref) =>
    AppLimitsRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
Stream<List<AppLimit>> appLimits(Ref ref) =>
    ref.watch(appLimitsRepositoryProvider).watch();

/// The minutes a day she can pick per app (Plan decision 52).
const appLimitMinutes = [15, 30, 45, 60, 90, 120];
const defaultAppLimit = 30;
