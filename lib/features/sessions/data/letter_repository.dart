import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'letter_repository.g.dart';

/// Letters to baby, kept in the encrypted database.
class LetterRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Newest first.
  Stream<List<Letter>> watch(String pregnancyId) =>
      (_db.select(_db.letters)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Adds a letter, or rewrites letter [id].
  Future<void> save(String pregnancyId, String body, {String? id}) async {
    if (id == null) {
      await _db
          .into(_db.letters)
          .insert(
            LettersCompanion.insert(
              pregnancyId: pregnancyId,
              body: body.trim(),
            ),
          );
      return;
    }
    await (_db.update(_db.letters)..where((t) => t.id.equals(id))).write(
      LettersCompanion(body: Value(body.trim()), updatedAt: Value(clockNow())),
    );
  }

  Future<void> remove(String id) =>
      (_db.update(_db.letters)..where((t) => t.id.equals(id))).write(
        LettersCompanion(deletedAt: Value(clockNow())),
      );
}

@riverpod
LetterRepository letterRepository(Ref ref) =>
    LetterRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<Letter>> letters(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(letterRepositoryProvider).watch(id);
}
