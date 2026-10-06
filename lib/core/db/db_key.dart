import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain / Keystore. `first_unlock_this_device`: readable while the phone
/// is locked (notification actions, background audio) and never copied into
/// iCloud or device backups.
const secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

const _dbKeyName = 'navmaas.db_key.v1';

/// The 256-bit database key as 64 hex characters, generated on first run.
Future<String> readOrCreateDbKey(FlutterSecureStorage storage) async {
  final existing = await storage.read(key: _dbKeyName);
  if (existing != null) return existing;
  final random = Random.secure();
  final key = List.generate(
    32,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  await storage.write(key: _dbKeyName, value: key);
  return key;
}

/// Delete all data: the next open creates a new key.
Future<void> deleteDbKey(FlutterSecureStorage storage) =>
    storage.delete(key: _dbKeyName);
