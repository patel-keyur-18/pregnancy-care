// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(audioPlayback)
final audioPlaybackProvider = AudioPlaybackProvider._();

final class AudioPlaybackProvider
    extends
        $FunctionalProvider<
          AsyncValue<AudioPlayback>,
          AudioPlayback,
          FutureOr<AudioPlayback>
        >
    with $FutureModifier<AudioPlayback>, $FutureProvider<AudioPlayback> {
  AudioPlaybackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioPlaybackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioPlaybackHash();

  @$internal
  @override
  $FutureProviderElement<AudioPlayback> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AudioPlayback> create(Ref ref) {
    return audioPlayback(ref);
  }
}

String _$audioPlaybackHash() => r'118af4fd3d49ac867fb7fff165e9451932d7d148';

/// The current playback, then every change.

@ProviderFor(playback)
final playbackProvider = PlaybackProvider._();

/// The current playback, then every change.

final class PlaybackProvider
    extends
        $FunctionalProvider<AsyncValue<Playback>, Playback, Stream<Playback>>
    with $FutureModifier<Playback>, $StreamProvider<Playback> {
  /// The current playback, then every change.
  PlaybackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackHash();

  @$internal
  @override
  $StreamProviderElement<Playback> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Playback> create(Ref ref) {
    return playback(ref);
  }
}

String _$playbackHash() => r'1257c54d4d0c829264d9b224482e953521632aa0';

/// Pauses playback after 10, 20 or 30 minutes (Listen's sleep timer). Kept
/// alive so it still runs after she leaves the Listen screen.

@ProviderFor(SleepTimer)
final sleepTimerProvider = SleepTimerProvider._();

/// Pauses playback after 10, 20 or 30 minutes (Listen's sleep timer). Kept
/// alive so it still runs after she leaves the Listen screen.
final class SleepTimerProvider extends $NotifierProvider<SleepTimer, int?> {
  /// Pauses playback after 10, 20 or 30 minutes (Listen's sleep timer). Kept
  /// alive so it still runs after she leaves the Listen screen.
  SleepTimerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepTimerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepTimerHash();

  @$internal
  @override
  SleepTimer create() => SleepTimer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$sleepTimerHash() => r'513a41ea14e2c9d75b39e1c2d1039a0f91683576';

/// Pauses playback after 10, 20 or 30 minutes (Listen's sleep timer). Kept
/// alive so it still runs after she leaves the Listen screen.

abstract class _$SleepTimer extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
