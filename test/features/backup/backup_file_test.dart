import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/backup/data/backup_file.dart';

/// Small pieces and a light key derivation keep the tests quick; the real
/// settings are in the header, so the code path is the same.
const _chunk = 1024;
final _header = BackupHeader(
  createdAt: DateTime.utc(2026, 10, 3, 15, 42),
  appVersion: '1.0.0',
  schemaVersion: 6,
  includesLibrary: true,
  kdf: (memoryKib: 64, iterations: 1, parallelism: 1),
  chunkSize: _chunk,
);

void main() {
  late Directory tmp;
  late File backup;
  final rng = Random(7);
  Uint8List bytes(int n) =>
      Uint8List.fromList(List.generate(n, (_) => rng.nextInt(256)));

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('navmaas_backup');
    backup = File('${tmp.path}/b.navmaas');
  });
  tearDown(() => tmp.delete(recursive: true));

  /// Writes a backup of three files (one spanning several pieces).
  Future<Map<String, Uint8List>> make() async {
    final contents = {
      'navmaas.db': bytes(5000),
      'attachments/ab12.bin': bytes(300),
      'library/0199.mp3': bytes(_chunk * 3), // ends exactly on a piece
    };
    final files = <BackupSource>[];
    for (final MapEntry(:key, :value) in contents.entries) {
      final f = File('${tmp.path}/src/$key');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(value);
      files.add((name: key, file: f));
    }
    await writeBackup(
      out: backup,
      header: _header,
      password: 'correct horse',
      files: files,
      manifest: {'entries': 12},
    );
    return contents;
  }

  Future<Map<String, Object?>> open([String password = 'correct horse']) =>
      readBackup(
        file: backup,
        password: password,
        into: Directory('${tmp.path}/out'),
      );

  Matcher fails(BackupError error) =>
      throwsA(isA<BackupException>().having((e) => e.error, 'error', error));

  /// The body's pieces: [start, end) byte ranges after the header.
  Future<List<(int, int)>> pieces() async {
    final all = await backup.readAsBytes();
    final headerLength = ByteData.sublistView(all, 8, 12).getUint32(0);
    var at = 12 + headerLength;
    final out = <(int, int)>[];
    while (at < all.length) {
      final end = min(at + _chunk + 28, all.length);
      out.add((at, end));
      at = end;
    }
    return out;
  }

  test('round trip: files and manifest come back exactly', () async {
    final contents = await make();
    final header = await readBackupHeader(backup);
    expect(header.createdAt, DateTime.utc(2026, 10, 3, 15, 42));
    expect((header.appVersion, header.schemaVersion), ('1.0.0', 6));
    expect(header.includesLibrary, isTrue);
    expect(header.salt, hasLength(16));

    expect(await open(), {'entries': 12});
    for (final MapEntry(:key, :value) in contents.entries) {
      expect(await File('${tmp.path}/out/$key').readAsBytes(), value);
    }
    // Encrypted: none of the database's bytes appear in the file.
    final raw = await backup.readAsBytes();
    expect(
      utf8.decode(raw, allowMalformed: true).contains('ab12.bin'),
      isFalse,
    );
  });

  test('a new salt every time', () async {
    await make();
    final first = (await readBackupHeader(backup)).salt;
    await make();
    expect((await readBackupHeader(backup)).salt, isNot(first));
  });

  test('wrong password', () async {
    await make();
    await expectLater(open('wrong horse'), fails(BackupError.wrongPassword));
  });

  test('cut short, mid-piece or on a piece boundary', () async {
    await make();
    final all = await backup.readAsBytes();
    final ranges = await pieces();
    await backup.writeAsBytes(all.sublist(0, all.length - 10));
    await expectLater(open(), fails(BackupError.damaged));
    // Drop the last piece entirely: the new last one isn't flagged last.
    await backup.writeAsBytes(all.sublist(0, ranges.last.$1));
    await expectLater(open(), fails(BackupError.damaged));
  });

  test('pieces swapped', () async {
    await make();
    final all = await backup.readAsBytes();
    final r = await pieces();
    final (a, b) = (r[1], r[2]);
    final swapped = [
      ...all.sublist(0, a.$1),
      ...all.sublist(b.$1, b.$2),
      ...all.sublist(a.$1, a.$2),
      ...all.sublist(b.$2),
    ];
    await backup.writeAsBytes(swapped);
    await expectLater(open(), fails(BackupError.damaged));
  });

  test('a byte changed in the body', () async {
    await make();
    final all = await backup.readAsBytes();
    final r = await pieces();
    all[r[3].$1 + 40] ^= 1;
    await backup.writeAsBytes(all);
    await expectLater(open(), fails(BackupError.damaged));
  });

  test('the header edited (it is authenticated)', () async {
    await make();
    final text = latin1.decode(await backup.readAsBytes());
    await backup.writeAsBytes(
      latin1.encode(
        text.replaceFirst('"appVersion":"1.0.0"', '"appVersion":"1.0.1"'),
      ),
    );
    await expectLater(open(), fails(BackupError.wrongPassword));
  });

  test('not a backup; a newer format', () async {
    await backup.writeAsString('%PDF-1.4 just a book');
    await expectLater(readBackupHeader(backup), fails(BackupError.notABackup));
    await make();
    final all = await backup.readAsBytes();
    all[7] = backupFormat + 1;
    await backup.writeAsBytes(all);
    await expectLater(readBackupHeader(backup), fails(BackupError.tooNew));
  });

  test('names that could escape the folder are refused', () async {
    final f = File('${tmp.path}/x')..writeAsStringSync('x');
    for (final name in ['../x', '/etc/x', 'a/b/c', 'a/../x', '.hidden']) {
      await expectLater(
        writeBackup(
          out: backup,
          header: _header,
          password: 'p',
          files: [(name: name, file: f)],
          manifest: const {},
        ),
        throwsArgumentError,
        reason: name,
      );
    }
  });

  test('a 500 MB library streams within the memory budget', () async {
    // ARCHITECTURE §1: a 500 MB library backs up in under 50 MB of RAM.
    const size = 500 << 20;
    final big = File('${tmp.path}/src/library/big.mp3');
    await big.parent.create(recursive: true);
    final sink = big.openWrite();
    final block = bytes(1 << 20);
    for (var i = 0; i < size >> 20; i++) {
      sink.add(block);
    }
    await sink.close();

    final baseline = ProcessInfo.currentRss;
    var peak = baseline;
    final sampler = Timer.periodic(const Duration(milliseconds: 20), (_) {
      peak = max(peak, ProcessInfo.currentRss);
    });
    try {
      await writeBackup(
        out: backup,
        header: BackupHeader(
          createdAt: DateTime.utc(2026, 10, 3),
          appVersion: '1.0.0',
          schemaVersion: 6,
          includesLibrary: true,
          kdf: (memoryKib: 64, iterations: 1, parallelism: 1),
        ),
        password: 'correct horse',
        files: [(name: 'library/big.mp3', file: big)],
        manifest: const {},
      );
      await big.delete();
      await open();
    } finally {
      sampler.cancel();
    }
    expect(await File('${tmp.path}/out/library/big.mp3').length(), size);
    expect(
      peak - baseline,
      lessThan(50 << 20),
      reason: 'peak +${(peak - baseline) >> 20} MB',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
