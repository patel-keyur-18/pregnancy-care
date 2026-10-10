import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nourishly.g.dart';

/// Nourishly's share file (ADR 061), as text: through `navmaas/nourishly`
/// (`NourishlyShare.kt`, `AppDelegate.swift`). Null when Nourishly isn't
/// installed, sharing is off, or Navmaas may not read it. Faked in tests.
abstract interface class NourishlySource {
  Future<String?> readShare();
}

class ChannelNourishly implements NourishlySource {
  static const _channel = MethodChannel('navmaas/nourishly');

  @override
  Future<String?> readShare() => _channel.invokeMethod<String>('readShare');
}

@Riverpod(keepAlive: true)
NourishlySource nourishlySource(Ref ref) => ChannelNourishly();
