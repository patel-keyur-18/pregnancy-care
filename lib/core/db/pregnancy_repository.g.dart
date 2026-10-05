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

@ProviderFor(activePregnancy)
final activePregnancyProvider = ActivePregnancyProvider._();

final class ActivePregnancyProvider
    extends
        $FunctionalProvider<
          AsyncValue<Pregnancy?>,
          Pregnancy?,
          Stream<Pregnancy?>
        >
    with $FutureModifier<Pregnancy?>, $StreamProvider<Pregnancy?> {
  ActivePregnancyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePregnancyProvider',
        isAutoDispose: true,
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

String _$activePregnancyHash() => r'eac283cfb489d7edfc0f8cf9ff897110b26aeb13';
