// Backs up and restores on a real phone: the keychain, files and the
// database swap underneath the app. A restore replaces data, so it only
// runs on an empty install (the simulator, or before onboarding):
//   flutter test integration_test/backup_test.dart -d <device>
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/features/backup/data/backup_file.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('back up, wrong password, restore', (_) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    AppDatabase db() => container.read(appDatabaseProvider);
    if ((await db().select(db().pregnancies).get()).isNotEmpty) {
      markTestSkipped('Only on an empty install: restoring replaces data');
      return;
    }
    final before = db();
    await PregnancyRepository(before)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    final service = await container.read(backupServiceProvider.future);
    final made = await service.create(
      password: 'correct horse',
      includeLibrary: false,
    );
    expect(made.sizeBytes, greaterThan(1000));

    // Changed after the backup.
    await PregnancyRepository(before)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 6, 2));
    await expectLater(
      service.restore(made.file, 'wrong horse'),
      throwsA(isA<BackupException>()),
    );
    expect(
      (await before.select(before.pregnancies).getSingle()).lmp,
      DateTime.utc(2026, 6, 2),
    );

    await service.restore(made.file, 'correct horse');
    final after = db();
    expect(after, isNot(same(before)));
    expect(
      (await after.select(after.pregnancies).getSingle()).lmp,
      DateTime.utc(2026, 4, 15),
    );

    // Leave the install empty again.
    await after.delete(after.backupLog).go();
    await after.delete(after.pregnancies).go();
  });
}
