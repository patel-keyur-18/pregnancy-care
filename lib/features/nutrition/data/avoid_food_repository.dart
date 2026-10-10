import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'avoid_food_repository.g.dart';

/// Foods she avoids, with her own reason (M8a). Her list; the app adds no
/// food guidance of its own.
class AvoidFoodRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<List<AvoidFood>> watch(String pregnancyId) =>
      (_db.select(_db.avoidFoods)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Adds (no [id]) or edits. A blank name saves nothing; a blank reason
  /// clears it.
  Future<void> save({
    required String pregnancyId,
    required String name,
    String? id,
    String? reason,
  }) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final r = reason?.trim();
    final why = Value(r == null || r.isEmpty ? null : r);
    if (id == null) {
      await _db
          .into(_db.avoidFoods)
          .insert(
            AvoidFoodsCompanion.insert(
              pregnancyId: pregnancyId,
              name: n,
              reason: why,
            ),
          );
    } else {
      await (_db.update(_db.avoidFoods)..where((t) => t.id.equals(id))).write(
        AvoidFoodsCompanion(
          name: Value(n),
          reason: why,
          updatedAt: Value(clockNow()),
        ),
      );
    }
  }

  Future<void> delete(String id) {
    final now = clockNow();
    return (_db.update(_db.avoidFoods)..where((t) => t.id.equals(id))).write(
      AvoidFoodsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}

@riverpod
AvoidFoodRepository avoidFoodRepository(Ref ref) =>
    AvoidFoodRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<AvoidFood>> avoidFoods(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(avoidFoodRepositoryProvider).watch(id);
}
