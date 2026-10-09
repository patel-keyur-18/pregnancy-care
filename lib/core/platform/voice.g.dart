// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A new recorder for each letter screen.

@ProviderFor(newVoiceRecorder)
final newVoiceRecorderProvider = NewVoiceRecorderProvider._();

/// A new recorder for each letter screen.

final class NewVoiceRecorderProvider
    extends
        $FunctionalProvider<
          VoiceRecorder Function(),
          VoiceRecorder Function(),
          VoiceRecorder Function()
        >
    with $Provider<VoiceRecorder Function()> {
  /// A new recorder for each letter screen.
  NewVoiceRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newVoiceRecorderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newVoiceRecorderHash();

  @$internal
  @override
  $ProviderElement<VoiceRecorder Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoiceRecorder Function() create(Ref ref) {
    return newVoiceRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceRecorder Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceRecorder Function()>(value),
    );
  }
}

String _$newVoiceRecorderHash() => r'f55c85184c58df18863e7dd14ea4c998ae901f5a';

/// A new player for each letter screen.

@ProviderFor(newVoicePlayer)
final newVoicePlayerProvider = NewVoicePlayerProvider._();

/// A new player for each letter screen.

final class NewVoicePlayerProvider
    extends
        $FunctionalProvider<
          VoicePlayer Function(),
          VoicePlayer Function(),
          VoicePlayer Function()
        >
    with $Provider<VoicePlayer Function()> {
  /// A new player for each letter screen.
  NewVoicePlayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newVoicePlayerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newVoicePlayerHash();

  @$internal
  @override
  $ProviderElement<VoicePlayer Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoicePlayer Function() create(Ref ref) {
    return newVoicePlayer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoicePlayer Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoicePlayer Function()>(value),
    );
  }
}

String _$newVoicePlayerHash() => r'7498fb48bc1302ae2482540dfbcfa695ecbdf21e';

@ProviderFor(keepScreenOn)
final keepScreenOnProvider = KeepScreenOnProvider._();

final class KeepScreenOnProvider
    extends $FunctionalProvider<KeepScreenOn, KeepScreenOn, KeepScreenOn>
    with $Provider<KeepScreenOn> {
  KeepScreenOnProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keepScreenOnProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keepScreenOnHash();

  @$internal
  @override
  $ProviderElement<KeepScreenOn> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeepScreenOn create(Ref ref) {
    return keepScreenOn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeepScreenOn value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeepScreenOn>(value),
    );
  }
}

String _$keepScreenOnHash() => r'ef8779e6c34f54fccf9a0f41e06691f40136a50d';

/// The private temporary folder for a recording or a voice note being
/// played (OS backups skip it). Emptied when the letter screen closes and
/// when the app starts, so no plain copy outlives its use.

@ProviderFor(voiceTempDir)
final voiceTempDirProvider = VoiceTempDirProvider._();

/// The private temporary folder for a recording or a voice note being
/// played (OS backups skip it). Emptied when the letter screen closes and
/// when the app starts, so no plain copy outlives its use.

final class VoiceTempDirProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// The private temporary folder for a recording or a voice note being
  /// played (OS backups skip it). Emptied when the letter screen closes and
  /// when the app starts, so no plain copy outlives its use.
  VoiceTempDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceTempDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceTempDirHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return voiceTempDir(ref);
  }
}

String _$voiceTempDirHash() => r'2553baed2622bfe792e70ba7b68cb77aad13847d';
