import 'dart:io';

import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/db_key.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_all_data.g.dart';

/// Me → "Delete all data" (ARCHITECTURE §13): the database, photos,
/// library, settings and both keys. Backup files saved elsewhere aren't
/// touched. Faked in widget tests.
typedef DeleteAllData = Future<void> Function();

/// Wipes [dbDir] and [scratch] (backup work folders), and empties [caches]
/// (copies the file picker left). The database moves aside first, so the
/// app's open database keeps working until [reopen] swaps in a new, empty
/// one under a new key. If the app stops part-way, the next open finishes.
Future<void> wipeData({
  required Directory dbDir,
  required List<Directory> scratch,
  required List<Directory> caches,
  required Future<void> Function() deleteKeys,
  required Future<void> Function() reopen,
}) async {
  final deleted = deletedDirFor(dbDir);
  if (deleted.existsSync()) await deleted.delete(recursive: true);
  if (dbDir.existsSync()) await dbDir.rename(deleted.path);
  await deleteKeys();
  await reopen();
  for (final d in [deleted, rollbackDirFor(dbDir), ...scratch]) {
    if (d.existsSync()) await d.delete(recursive: true);
  }
  for (final d in caches) {
    if (!d.existsSync()) continue;
    for (final e in d.listSync()) {
      await e.delete(recursive: true);
    }
  }
}

// Kept alive: it outlives the database it replaces.
@Riverpod(keepAlive: true)
DeleteAllData deleteAllData(Ref ref) => () async {
  // Nothing may ring for data that's gone, snoozed reminders included.
  await ref.read(reminderSchedulerProvider).cancelAll();
  if (ref.exists(audioPlaybackProvider)) {
    await (await ref.read(audioPlaybackProvider.future)).pause();
  }
  final support = await getApplicationSupportDirectory();
  final work = p.join(support.path, 'backup-work');
  await wipeData(
    dbDir: Directory(p.join(support.path, 'db')),
    scratch: [
      for (final suffix in ['', '-incoming', '-restore'])
        Directory('$work$suffix'),
    ],
    caches: [await getTemporaryDirectory()],
    deleteKeys: () async {
      await deleteDbKey(secureStorage);
      await deleteAttachmentKey(secureStorage);
    },
    reopen: () => reopenAppDatabase(ref),
  );
};
