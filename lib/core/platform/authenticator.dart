import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'authenticator.g.dart';

/// Face ID, Touch ID or fingerprint, falling back to the phone's passcode
/// (app lock, Plan decision 48). Behind an interface so tests use a fake.
abstract interface class Authenticator {
  /// Whether the phone has a screen lock app lock can use.
  Future<bool> canLock();

  /// Asks her to unlock; true once she has. A cancel or a failure is false.
  Future<bool> unlock(String reason);
}

class LocalAuthenticator implements Authenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> canLock() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object catch (e) {
      debugPrint('Navmaas: app lock unavailable ($e)');
      return false;
    }
  }

  @override
  Future<bool> unlock(String reason) async {
    try {
      // Not biometric-only: a failed face or finger falls back to the
      // passcode, which the system offers.
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      debugPrint('Navmaas: not unlocked (${e.code.name})');
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
Authenticator authenticator(Ref ref) => LocalAuthenticator();
