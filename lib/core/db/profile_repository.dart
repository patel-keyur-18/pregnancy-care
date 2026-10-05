import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repository.g.dart';

/// The single doctor / clinic row.
class ProfileRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<Profile?> watch() =>
      (_db.select(_db.profiles)
            ..where((t) => t.deletedAt.isNull())
            ..limit(1))
          .watchSingleOrNull();

  /// Saves the doctor details; blank fields are stored as empty (null).
  Future<void> save({
    String? doctorName,
    String? clinicName,
    String? clinicPhone,
    String? clinicAddress,
  }) {
    Value<String?> v(String? s) =>
        Value(s == null || s.trim().isEmpty ? null : s.trim());
    final row = ProfilesCompanion(
      doctorName: v(doctorName),
      clinicName: v(clinicName),
      clinicPhone: v(clinicPhone),
      clinicAddress: v(clinicAddress),
      updatedAt: Value(DateTime.now()),
    );
    return _db.transaction(() async {
      final current = await watch().first;
      if (current == null) {
        await _db.into(_db.profiles).insert(row);
      } else {
        await (_db.update(
          _db.profiles,
        )..where((t) => t.id.equals(current.id))).write(row);
      }
    });
  }
}

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<Profile?> profile(Ref ref) =>
    ref.watch(profileRepositoryProvider).watch();
