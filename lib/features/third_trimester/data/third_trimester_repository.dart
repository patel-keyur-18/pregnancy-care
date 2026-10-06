import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'third_trimester_repository.g.dart';

/// Kick-counter sessions and timed contractions: logs to show the doctor
/// (Plan §5.3). Nothing here judges them.
class ThirdTrimesterRepository {
  const new(this._db);

  final AppDatabase _db;

  Future<void> saveKicks({
    required String pregnancyId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int count,
  }) => _db
      .into(_db.kickSessions)
      .insert(
        KickSessionsCompanion.insert(
          pregnancyId: pregnancyId,
          startedAt: startedAt,
          endedAt: endedAt,
          count: count,
        ),
      );

  /// Newest first.
  Stream<List<KickSession>> watchKicks(String pregnancyId) =>
      (_db.select(_db.kickSessions)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch();

  Future<void> saveContraction({
    required String pregnancyId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) => _db
      .into(_db.contractions)
      .insert(
        ContractionsCompanion.insert(
          pregnancyId: pregnancyId,
          startedAt: startedAt,
          endedAt: endedAt,
        ),
      );

  /// Contractions started at or after [from], newest first.
  Stream<List<Contraction>> watchContractions(
    String pregnancyId,
    DateTime from,
  ) =>
      (_db.select(_db.contractions)
            ..where(
              (t) =>
                  t.pregnancyId.equals(pregnancyId) &
                  t.deletedAt.isNull() &
                  t.startedAt.isBiggerOrEqualValue(from),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch();
}

@riverpod
ThirdTrimesterRepository thirdTrimesterRepository(Ref ref) =>
    ThirdTrimesterRepository(ref.watch(appDatabaseProvider));

/// The active pregnancy's kick sessions, newest first.
@riverpod
Stream<List<KickSession>> kickSessions(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(thirdTrimesterRepositoryProvider).watchKicks(id);
}

/// The active pregnancy's contractions since [from], newest first.
@riverpod
Stream<List<Contraction>> contractionsSince(Ref ref, DateTime from) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref
      .watch(thirdTrimesterRepositoryProvider)
      .watchContractions(id, from);
}
