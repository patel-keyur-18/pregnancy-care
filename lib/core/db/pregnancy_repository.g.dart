// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pregnancy_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pregnancyRepository)
final pregnancyRepositoryProvider = PregnancyRepositoryProvider._();

final class PregnancyRepositoryProvider
    extends
        $FunctionalProvider<
          PregnancyRepository,
          PregnancyRepository,
          PregnancyRepository
        >
    with $Provider<PregnancyRepository> {
  PregnancyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pregnancyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pregnancyRepositoryHash();

  @$internal
  @override
  $ProviderElement<PregnancyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PregnancyRepository create(Ref ref) {
    return pregnancyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PregnancyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PregnancyRepository>(value),
    );
  }
}

String _$pregnancyRepositoryHash() =>
    r'053072432f4ed820fce0c4dc994813cbb5bfd2ce';

/// Kept alive: the router's onboarding redirect depends on it.

@ProviderFor(activePregnancy)
final activePregnancyProvider = ActivePregnancyProvider._();

/// Kept alive: the router's onboarding redirect depends on it.

final class ActivePregnancyProvider
    extends
        $FunctionalProvider<
          AsyncValue<Pregnancy?>,
          Pregnancy?,
          Stream<Pregnancy?>
        >
    with $FutureModifier<Pregnancy?>, $StreamProvider<Pregnancy?> {
  /// Kept alive: the router's onboarding redirect depends on it.
  ActivePregnancyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePregnancyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePregnancyHash();

  @$internal
  @override
  $StreamProviderElement<Pregnancy?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Pregnancy?> create(Ref ref) {
    return activePregnancy(ref);
  }
}

String _$activePregnancyHash() => r'8c3eefc20aee8b3c43e34d30da1bb89d3e86f23f';

/// The newest pregnancy in any status. Kept alive for the router.

@ProviderFor(latestPregnancy)
final latestPregnancyProvider = LatestPregnancyProvider._();

/// The newest pregnancy in any status. Kept alive for the router.

final class LatestPregnancyProvider
    extends
        $FunctionalProvider<
          AsyncValue<Pregnancy?>,
          Pregnancy?,
          Stream<Pregnancy?>
        >
    with $FutureModifier<Pregnancy?>, $StreamProvider<Pregnancy?> {
  /// The newest pregnancy in any status. Kept alive for the router.
  LatestPregnancyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestPregnancyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestPregnancyHash();

  @$internal
  @override
  $StreamProviderElement<Pregnancy?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Pregnancy?> create(Ref ref) {
    return latestPregnancy(ref);
  }
}

String _$latestPregnancyHash() => r'569ea0e08fa7cf554901277bffd345c7ab366bd3';
