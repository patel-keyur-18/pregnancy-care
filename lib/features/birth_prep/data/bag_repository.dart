import 'package:drift/drift.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bag_repository.g.dart';

/// One line of the hospital bag as shown: a template item or one of hers.
typedef BagRow = ({
  String? id,
  String? templateKey,
  String label,
  BagSection section,
  bool packed,
});

/// The template in file order with her ticks, then her own items. Ticks on
/// keys the template no longer has are dropped; labels come from the
/// template, so a reworded item keeps its tick.
List<BagRow> mergeBag(List<BagTemplateItem> template, List<BagItem> rows) {
  final ticked = {for (final r in rows) ?r.templateKey: r};
  return [
    for (final t in template)
      (
        id: ticked[t.key]?.id,
        templateKey: t.key,
        label: t.label,
        section: t.section,
        packed: ticked[t.key]?.packed ?? false,
      ),
    for (final r in rows)
      if (r.templateKey == null)
        (
          id: r.id,
          templateKey: null,
          label: r.label ?? '',
          section: r.section,
          packed: r.packed,
        ),
  ];
}

/// Hospital-bag ticks and her own items, per pregnancy (M8a).
class BagRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<List<BagItem>> watch(String pregnancyId) =>
      (_db.select(_db.bagItems)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> setPacked({
    required String pregnancyId,
    required BagRow row,
    required bool packed,
  }) async {
    if (row.templateKey == null) {
      await (_db.update(
        _db.bagItems,
      )..where((t) => t.id.equals(row.id!))).write(
        BagItemsCompanion(packed: Value(packed), updatedAt: Value(clockNow())),
      );
      return;
    }
    await _db
        .into(_db.bagItems)
        .insert(
          BagItemsCompanion.insert(
            pregnancyId: pregnancyId,
            templateKey: Value(row.templateKey),
            section: row.section,
            packed: Value(packed),
          ),
          onConflict: DoUpdate(
            (_) => BagItemsCompanion(
              packed: Value(packed),
              deletedAt: const Value(null),
              updatedAt: Value(clockNow()),
            ),
            target: [_db.bagItems.pregnancyId, _db.bagItems.templateKey],
          ),
        );
  }

  /// A blank label saves nothing.
  Future<void> addOwn({
    required String pregnancyId,
    required String label,
    required BagSection section,
  }) async {
    final l = label.trim();
    if (l.isEmpty) return;
    await _db
        .into(_db.bagItems)
        .insert(
          BagItemsCompanion.insert(
            pregnancyId: pregnancyId,
            label: Value(l),
            section: section,
          ),
        );
  }

  Future<void> deleteOwn(String id) =>
      (_db.update(_db.bagItems)..where((t) => t.id.equals(id))).write(
        BagItemsCompanion(deletedAt: Value(clockNow())),
      );
}

@riverpod
BagRepository bagRepository(Ref ref) =>
    BagRepository(ref.watch(appDatabaseProvider));

/// The bag as shown: the template with her ticks, then her own items.
@riverpod
Stream<List<BagRow>> bag(Ref ref) async* {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) {
    yield const [];
    return;
  }
  final template = await ref.watch(hospitalBagProvider.future);
  yield* ref
      .watch(bagRepositoryProvider)
      .watch(id)
      .map((rows) => mergeBag(template, rows));
}
