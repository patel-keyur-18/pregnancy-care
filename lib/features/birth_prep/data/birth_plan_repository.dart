import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'birth_plan_repository.g.dart';

/// Her birth-plan answers in her own words, one per prompt (M8a).
class BirthPlanRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Prompt key → her answer.
  Stream<Map<String, String>> watch(String pregnancyId) =>
      (_db.select(_db.birthPlanAnswers)..where(
            (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
          ))
          .watch()
          .map((rows) => {for (final r in rows) r.promptKey: r.answer});

  /// A blank answer clears the prompt.
  Future<void> save({
    required String pregnancyId,
    required String promptKey,
    required String answer,
  }) {
    final a = answer.trim();
    final gone = Value(a.isEmpty ? clockNow() : null);
    return _db
        .into(_db.birthPlanAnswers)
        .insert(
          BirthPlanAnswersCompanion.insert(
            pregnancyId: pregnancyId,
            promptKey: promptKey,
            answer: a,
            deletedAt: gone,
          ),
          onConflict: DoUpdate(
            (_) => BirthPlanAnswersCompanion(
              answer: Value(a),
              deletedAt: gone,
              updatedAt: Value(clockNow()),
            ),
            target: [
              _db.birthPlanAnswers.pregnancyId,
              _db.birthPlanAnswers.promptKey,
            ],
          ),
        );
  }
}

@riverpod
BirthPlanRepository birthPlanRepository(Ref ref) =>
    BirthPlanRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<Map<String, String>> birthPlanAnswers(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const {});
  return ref.watch(birthPlanRepositoryProvider).watch(id);
}
