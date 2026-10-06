import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_log.g.dart';

/// When she last made a backup on this phone, or null.
@riverpod
Stream<DateTime?> lastBackup(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.backupLog)
        ..where((t) => t.kind.equalsValue(BackupKind.backup))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(1))
      .watchSingleOrNull()
      .map((row) => row?.createdAt);
}
