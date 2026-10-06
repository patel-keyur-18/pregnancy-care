import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_repository.g.dart';

/// Reading, listening, walk, exercise and breathing sessions.
class SessionRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Logs a session and returns its id.
  Future<String> log({
    required String pregnancyId,
    required SessionType type,
    required DateTime startedAt,
    required int durationSec,
    String? libraryItemId,
    String? routineKey,
    int? steps,
  }) async =>
      (await _db
              .into(_db.sessions)
              .insertReturning(
                SessionsCompanion.insert(
                  pregnancyId: pregnancyId,
                  type: type,
                  startedAt: startedAt,
                  durationSec: durationSec,
                  libraryItemId: Value(libraryItemId),
                  routineKey: Value(routineKey),
                  steps: Value(steps),
                ),
              ))
          .id;

  /// Updates a session that is still going (listening grows as she plays).
  Future<void> setDuration(String id, int durationSec) =>
      (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
        SessionsCompanion(
          durationSec: Value(durationSec),
          updatedAt: Value(clockNow()),
        ),
      );

  /// Sessions started in [from, to), oldest first.
  Stream<List<Session>> watchBetween(
    String pregnancyId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.sessions)
            ..where(
              (t) =>
                  t.pregnancyId.equals(pregnancyId) &
                  t.deletedAt.isNull() &
                  t.startedAt.isBiggerOrEqualValue(from) &
                  t.startedAt.isSmallerThanValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .watch();
}

@riverpod
SessionRepository sessionRepository(Ref ref) =>
    SessionRepository(ref.watch(appDatabaseProvider));

/// The active pregnancy's sessions started in [from, to) (local times).
@riverpod
Stream<List<Session>> sessionsBetween(Ref ref, DateTime from, DateTime to) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(sessionRepositoryProvider).watchBetween(id, from, to);
}
