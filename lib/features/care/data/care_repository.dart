import 'package:drift/drift.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'care_repository.g.dart';

/// Tests, scans and vaccines for a pregnancy (from the India care template).
class CareRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Adds any template items this pregnancy doesn't have yet.
  Future<void> ensureTemplate(
    String pregnancyId,
    List<CareTemplateItem> template,
  ) => _db.batch((b) {
    b.insertAll(_db.careItems, [
      for (final t in template)
        CareItemsCompanion.insert(
          pregnancyId: pregnancyId,
          templateKey: Value(t.key),
          kind: t.kind,
          title: t.title,
          fromWeek: t.fromWeek,
          toWeek: t.toWeek,
        ),
    ], mode: InsertMode.insertOrIgnore);
  });

  Stream<List<CareItem>> watchItems(String pregnancyId) =>
      (_db.select(_db.careItems)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.fromWeek),
              (t) => OrderingTerm.asc(t.toWeek),
            ]))
          .watch();

  Future<void> book(String id, DateTime? at) =>
      _update(id, CareItemsCompanion(scheduledAt: Value(at)));

  Future<void> markDone(String id, {required bool done}) =>
      _update(id, CareItemsCompanion(doneAt: Value(done ? clockNow() : null)));

  Future<void> setNotes(String id, String notes) => _update(
    id,
    CareItemsCompanion(
      notes: Value(notes.trim().isEmpty ? null : notes.trim()),
    ),
  );

  Future<void> _update(String id, CareItemsCompanion row) =>
      (_db.update(_db.careItems)..where((t) => t.id.equals(id))).write(
        row.copyWith(updatedAt: Value(clockNow())),
      );
}

@riverpod
CareRepository careRepository(Ref ref) =>
    CareRepository(ref.watch(appDatabaseProvider));

/// Care items of the active pregnancy; seeds the template on first read.
@riverpod
Stream<List<CareItem>> careItems(Ref ref) async* {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) {
    yield const [];
    return;
  }
  final repo = ref.watch(careRepositoryProvider);
  await repo.ensureTemplate(id, await ref.watch(careTemplateProvider.future));
  yield* repo.watchItems(id);
}
