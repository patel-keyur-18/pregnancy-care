import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/delete_all_data.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('navmaas_wipe'));
  tearDown(() => root.deleteSync(recursive: true));

  File put(String path) => File(p.join(root.path, path))
    ..createSync(recursive: true)
    ..writeAsStringSync('hers');

  test('wipes the data, the work folders, the caches and the keys', () async {
    final db = Directory(p.join(root.path, 'db'));
    put('db/navmaas.db');
    put('db/attachments/a.bin');
    put('db/library/book.pdf');
    put('db-before-restore/navmaas.db');
    put('backup-work/navmaas-backup.navmaas');
    put('backup-work-incoming/picked.navmaas');
    put('cache/file_picker/book.pdf');
    final cache = Directory(p.join(root.path, 'cache'));
    final steps = <String>[];

    await wipeData(
      dbDir: db,
      scratch: [
        Directory(p.join(root.path, 'backup-work')),
        Directory(p.join(root.path, 'backup-work-incoming')),
        Directory(p.join(root.path, 'backup-work-restore')),
      ],
      caches: [cache],
      deleteKeys: () async => steps.add('keys'),
      reopen: () async {
        // The old data is out of the way before the new database opens.
        steps.add('reopen: db ${db.existsSync() ? 'there' : 'gone'}');
        put('db/navmaas.db');
      },
    );

    expect(steps, ['keys', 'reopen: db gone']);
    expect(
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => p.relative(f.path, from: root.path)),
      ['db/navmaas.db'],
      reason: 'only the new, empty database is left',
    );
    expect(cache.existsSync(), isTrue);
  });

  test('a wipe the app stopped part-way through is finished on open', () async {
    final db = Directory(p.join(root.path, 'db'));
    put('db-deleted/navmaas.db');
    await removeDeletedData(db);
    expect(deletedDirFor(db).existsSync(), isFalse);
  });
}
