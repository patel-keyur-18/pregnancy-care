import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vitals_repository.g.dart';

/// Weight and blood-pressure logs. Recorded only, never interpreted.
class VitalsRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Readings of [kind], oldest first.
  Stream<List<VitalReading>> watch(String pregnancyId, VitalKind kind) =>
      (_db.select(_db.vitalReadings)
            ..where(
              (t) =>
                  t.pregnancyId.equals(pregnancyId) &
                  t.kind.equalsValue(kind) &
                  t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.at)]))
          .watch();

  Future<void> add({
    required String pregnancyId,
    required VitalKind kind,
    required double value1,
    double? value2,
    DateTime? at,
  }) => _db
      .into(_db.vitalReadings)
      .insert(
        VitalReadingsCompanion.insert(
          pregnancyId: pregnancyId,
          kind: kind,
          value1: value1,
          value2: Value(value2),
          at: at ?? DateTime.now(),
        ),
      );
}

@riverpod
VitalsRepository vitalsRepository(Ref ref) =>
    VitalsRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<VitalReading>> vitals(Ref ref, VitalKind kind) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(vitalsRepositoryProvider).watch(id, kind);
}
