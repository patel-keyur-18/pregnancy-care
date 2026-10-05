import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checklist_repository.g.dart';

class ChecklistRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Keys of the ticked checklist items for [pregnancyId].
  Stream<Set<String>> watchTicked(String pregnancyId) =>
      (_db.select(_db.checklistTicks)..where(
            (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
          ))
          .watch()
          .map((rows) => {for (final r in rows) r.itemKey});

  Future<void> setTicked(
    String pregnancyId,
    String itemKey, {
    required bool ticked,
  }) => _db
      .into(_db.checklistTicks)
      .insert(
        ChecklistTicksCompanion.insert(
          pregnancyId: pregnancyId,
          itemKey: itemKey,
          deletedAt: Value(ticked ? null : DateTime.now()),
        ),
        onConflict: DoUpdate(
          (_) => ChecklistTicksCompanion(
            deletedAt: Value(ticked ? null : DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
          target: [_db.checklistTicks.pregnancyId, _db.checklistTicks.itemKey],
        ),
      );
}

@riverpod
ChecklistRepository checklistRepository(Ref ref) =>
    ChecklistRepository(ref.watch(appDatabaseProvider));

/// Ticked item keys for the active pregnancy (empty when there is none).
@riverpod
Stream<Set<String>> tickedItems(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const {});
  return ref.watch(checklistRepositoryProvider).watchTicked(id);
}
