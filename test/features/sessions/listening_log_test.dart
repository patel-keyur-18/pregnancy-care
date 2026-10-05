import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/features/sessions/data/listening_log.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';

Playback _p(String? item, {required bool playing}) => (
  itemId: item,
  playing: playing,
  completed: false,
  position: Duration.zero,
  duration: null,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('counts only playing time, from one minute, per item', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // A pregnancy row for the foreign key.
    final pregnancy = await db
        .into(db.pregnancies)
        .insertReturning(
          PregnanciesCompanion.insert(
            status: PregnancyStatus.active,
            datingMethod: .lmp,
            startDate: DateTime.utc(2026, 4, 15),
            dueDate: DateTime.utc(2027, 1, 20),
          ),
        );
    for (final id in ['om', 'raag']) {
      await db
          .into(db.libraryItems)
          .insert(
            LibraryItemsCompanion.insert(
              id: Value(id),
              kind: LibraryKind.audio,
              title: id,
              fileName: '$id.mp3',
            ),
          );
    }
    var now = DateTime(2026, 10, 5, 21);
    final logger = ListeningLogger(
      SessionRepository(db),
      pregnancyId: () => pregnancy.id,
      clock: () => now,
    );
    Future<List<Session>> logged() => db.select(db.sessions).get();

    await logger.onPlayback(_p('om', playing: true));
    now = now.add(const Duration(seconds: 40));
    await logger.onPlayback(_p('om', playing: false));
    expect(await logged(), isEmpty, reason: 'under a minute');

    now = now.add(const Duration(minutes: 30)); // paused: not counted
    await logger.onPlayback(_p('om', playing: true));
    now = now.add(const Duration(seconds: 50));
    await logger.onPlayback(_p('om', playing: true)); // a position tick
    expect((await logged()).single.durationSec, 90);

    now = now.add(const Duration(minutes: 5));
    await logger.onPlayback(_p('raag', playing: true)); // switched item
    final rows = await logged();
    expect(rows.single.durationSec, 390);
    expect(rows.single.startedAt, DateTime(2026, 10, 5, 21));
    expect(rows.single.libraryItemId, 'om');
    expect(rows.single.type, SessionType.listening);
  });
}
