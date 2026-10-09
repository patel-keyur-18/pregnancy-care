import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:navmaas/core/db/db_key.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachment_store.g.dart';

const _attachmentKeyName = 'navmaas.attachments_key.v1';

/// Prescription photos and reports, encrypted with AES-256-GCM under their
/// own key (ARCHITECTURE §13). Files live in the private `db/attachments/`
/// folder, which OS backups skip. Format: 12-byte nonce, ciphertext, 16-byte
/// tag.
class AttachmentStore {
  new({required this.directory, required this.key});

  final Directory directory;

  /// The 256-bit key, read lazily from secure storage.
  final Future<List<int>> Function() key;
  final _cipher = AesGcm.with256bits();

  /// Encrypts [bytes] into a new file and returns its name.
  Future<String> save(Uint8List bytes) async {
    final box = await _cipher.encrypt(bytes, secretKey: SecretKey(await key()));
    final name = '${_randomName()}.bin';
    await directory.create(recursive: true);
    await File(p.join(directory.path, name))
        .writeAsBytes(box.concatenation(), flush: true);
    return name;
  }

  /// Decrypts a file written by [save]; throws if it was tampered with.
  Future<Uint8List> read(String name) async {
    final data = await File(p.join(directory.path, name)).readAsBytes();
    final box = SecretBox.fromConcatenation(
      data,
      nonceLength: 12,
      macLength: 16,
    );
    return Uint8List.fromList(
      await _cipher.decrypt(box, secretKey: SecretKey(await key())),
    );
  }

  Future<void> delete(String name) async {
    final f = File(p.join(directory.path, name));
    if (f.existsSync()) await f.delete();
  }

  static String _randomName() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// The attachment key (32 random bytes, hex), created on first use.
Future<List<int>> readOrCreateAttachmentKey(
  FlutterSecureStorage storage,
) async {
  var hex = await storage.read(key: _attachmentKeyName);
  if (hex == null) {
    final r = Random.secure();
    hex = List.generate(
      32,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await storage.write(key: _attachmentKeyName, value: hex);
  }
  return [
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}

/// Replaces the attachment key: a restore brings the backup's photos and
/// the key they were sealed with.
Future<void> writeAttachmentKey(FlutterSecureStorage storage, List<int> key) =>
    storage.write(
      key: _attachmentKeyName,
      value: key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );

/// Delete all data: the next photo creates a new key.
Future<void> deleteAttachmentKey(FlutterSecureStorage storage) =>
    storage.delete(key: _attachmentKeyName);

@Riverpod(keepAlive: true)
Future<AttachmentStore> attachmentStore(Ref ref) async {
  final support = await getApplicationSupportDirectory();
  return AttachmentStore(
    directory: Directory(p.join(support.path, 'db', 'attachments')),
    key: () => readOrCreateAttachmentKey(secureStorage),
  );
}

/// Voice letters (E3), sealed like attachments with the same key, in their
/// own `db/voice/` folder (skipped by OS backups; in a `.navmaas` backup only
/// when "Include voice letters" is on).
@Riverpod(keepAlive: true)
Future<AttachmentStore> voiceStore(Ref ref) async {
  final support = await getApplicationSupportDirectory();
  return AttachmentStore(
    directory: Directory(p.join(support.path, 'db', 'voice')),
    key: () => readOrCreateAttachmentKey(secureStorage),
  );
}
