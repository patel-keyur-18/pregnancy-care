// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listening_log.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Started by the Listen screen; kept alive so audio that goes on playing
/// after she leaves it is still counted.

@ProviderFor(listeningLog)
final listeningLogProvider = ListeningLogProvider._();

/// Started by the Listen screen; kept alive so audio that goes on playing
/// after she leaves it is still counted.

final class ListeningLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<ListeningLogger>,
          ListeningLogger,
          FutureOr<ListeningLogger>
        >
    with $FutureModifier<ListeningLogger>, $FutureProvider<ListeningLogger> {
  /// Started by the Listen screen; kept alive so audio that goes on playing
  /// after she leaves it is still counted.
  ListeningLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listeningLogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listeningLogHash();

  @$internal
  @override
  $FutureProviderElement<ListeningLogger> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ListeningLogger> create(Ref ref) {
    return listeningLog(ref);
  }
}

String _$listeningLogHash() => r'46a70e173572911f3829f4716447a4cb33d58375';
