import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/platform/authenticator.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock.g.dart';

/// Whether Navmaas is locked (M10b, Plan decision 48). With app lock on it
/// starts locked, and locks again once she has been away for the minutes
/// she chose. Notification actions run without the app, so they keep
/// working; a notification or widget tap navigates underneath the lock.
@Riverpod(keepAlive: true)
class AppLock extends _$AppLock {
  DateTime? _leftAt;

  @override
  bool build() {
    // A fresh open locks as soon as the setting is known.
    ref.listen(appLockSettingsProvider, (previous, next) {
      if (previous?.value == null && (next.value?.on ?? false)) state = true;
    });
    return ref.read(appLockSettingsProvider).value?.on ?? false;
  }

  /// She left Navmaas (the app is hidden).
  void left() => _leftAt ??= clockNow();

  /// She came back: locks if she was away long enough.
  void returned() {
    final left = _leftAt;
    _leftAt = null;
    final settings = ref.read(appLockSettingsProvider).value;
    if (left == null || settings == null || !settings.on) return;
    if (clockNow().difference(left) >= Duration(minutes: settings.after)) {
      state = true;
    }
  }

  /// Asks the phone to unlock; unlocks Navmaas if she did.
  Future<void> unlock(String reason) async {
    if (await ref.read(authenticatorProvider).unlock(reason)) state = false;
  }
}
