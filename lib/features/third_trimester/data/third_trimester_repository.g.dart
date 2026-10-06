// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'third_trimester_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(thirdTrimesterRepository)
final thirdTrimesterRepositoryProvider = ThirdTrimesterRepositoryProvider._();

final class ThirdTrimesterRepositoryProvider
    extends
        $FunctionalProvider<
          ThirdTrimesterRepository,
          ThirdTrimesterRepository,
          ThirdTrimesterRepository
        >
    with $Provider<ThirdTrimesterRepository> {
  ThirdTrimesterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thirdTrimesterRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thirdTrimesterRepositoryHash();

  @$internal
  @override
  $ProviderElement<ThirdTrimesterRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ThirdTrimesterRepository create(Ref ref) {
    return thirdTrimesterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThirdTrimesterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThirdTrimesterRepository>(value),
    );
  }
}

String _$thirdTrimesterRepositoryHash() =>
    r'6b28a4d9010f232117aa06585b199dcc671d1212';

/// The active pregnancy's kick sessions, newest first.

@ProviderFor(kickSessions)
final kickSessionsProvider = KickSessionsProvider._();

/// The active pregnancy's kick sessions, newest first.

final class KickSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KickSession>>,
          List<KickSession>,
          Stream<List<KickSession>>
        >
    with
        $FutureModifier<List<KickSession>>,
        $StreamProvider<List<KickSession>> {
  /// The active pregnancy's kick sessions, newest first.
  KickSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kickSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kickSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<KickSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<KickSession>> create(Ref ref) {
    return kickSessions(ref);
  }
}

String _$kickSessionsHash() => r'85a5ade9b76c32e4b39423e418d5c0ea94bc5655';

/// The active pregnancy's contractions since [from], newest first.

@ProviderFor(contractionsSince)
final contractionsSinceProvider = ContractionsSinceFamily._();

/// The active pregnancy's contractions since [from], newest first.

final class ContractionsSinceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Contraction>>,
          List<Contraction>,
          Stream<List<Contraction>>
        >
    with
        $FutureModifier<List<Contraction>>,
        $StreamProvider<List<Contraction>> {
  /// The active pregnancy's contractions since [from], newest first.
  ContractionsSinceProvider._({
    required ContractionsSinceFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'contractionsSinceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contractionsSinceHash();

  @override
  String toString() {
    return r'contractionsSinceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Contraction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Contraction>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return contractionsSince(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContractionsSinceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contractionsSinceHash() => r'b978894b8be3746712eec49b95cd7d45d784bb79';

/// The active pregnancy's contractions since [from], newest first.

final class ContractionsSinceFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Contraction>>, DateTime> {
  ContractionsSinceFamily._()
    : super(
        retry: null,
        name: r'contractionsSinceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The active pregnancy's contractions since [from], newest first.

  ContractionsSinceProvider call(DateTime from) =>
      ContractionsSinceProvider._(argument: from, from: this);

  @override
  String toString() => r'contractionsSinceProvider';
}
