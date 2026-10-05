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
