import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_usage.g.dart';

/// An app on her phone she could set a limit on.
typedef InstalledApp = ({String package, String label, Uint8List? icon});

/// Android's Usage access and the app-limit check (M11, ADR 050), through
/// the `navmaas/usage` channel (`MainActivity.kt`). On iPhone there is
/// nothing: Family Controls needs a paid membership. Faked in tests.
abstract interface class AppUsage {
  /// Whether this phone can have app limits (Android only).
  bool get supported;

  /// Whether she has given Navmaas Usage access.
  Future<bool> hasAccess();

  /// Opens the system's Usage access settings.
  Future<void> openAccessSettings();

  /// The apps on her launcher, other than Navmaas, by name.
  Future<List<InstalledApp>> apps();

  /// Minutes each of [packages] has been in the foreground today.
  Future<Map<String, int>> minutesToday(List<String> packages);

  /// Hands the check its rules (`limitRules`); it runs every 15 minutes
  /// while [limits] is above zero and stops otherwise.
  Future<void> setRules(String rules, {required int limits});
}

class ChannelAppUsage implements AppUsage {
  static const _channel = MethodChannel('navmaas/usage');

  @override
  bool get supported => Platform.isAndroid;

  @override
  Future<bool> hasAccess() async =>
      supported && (await _channel.invokeMethod<bool>('hasAccess') ?? false);

  @override
  Future<void> openAccessSettings() =>
      _channel.invokeMethod<void>('openAccessSettings');

  @override
  Future<List<InstalledApp>> apps() async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>('apps');
    return [
      for (final a in list ?? const <Map<Object?, Object?>>[])
        (
          package: a['package']! as String,
          label: a['label']! as String,
          icon: a['icon'] as Uint8List?,
        ),
    ];
  }

  @override
  Future<Map<String, int>> minutesToday(List<String> packages) async {
    final m = await _channel.invokeMapMethod<String, int>('minutesToday', {
      'packages': packages,
    });
    return m ?? const {};
  }

  @override
  Future<void> setRules(String rules, {required int limits}) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('setRules', {
        'rules': rules,
        'limits': limits,
      });
    } on PlatformException catch (e) {
      debugPrint('Navmaas: app-limit check not set ($e)');
    }
  }
}

@Riverpod(keepAlive: true)
AppUsage appUsage(Ref ref) => ChannelAppUsage();
