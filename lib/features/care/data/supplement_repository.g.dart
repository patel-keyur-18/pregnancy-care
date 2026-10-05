// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplement_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supplementRepository)
final supplementRepositoryProvider = SupplementRepositoryProvider._();

final class SupplementRepositoryProvider
    extends
        $FunctionalProvider<
          SupplementRepository,
          SupplementRepository,
          SupplementRepository
        >
    with $Provider<SupplementRepository> {
  SupplementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplementRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplementRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupplementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupplementRepository create(Ref ref) {
    return supplementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplementRepository>(value),
    );
  }
}

String _$supplementRepositoryHash() =>
    r'f20bb1ab189e21e7c9601d612b7b224d30424547';

/// Supplements of the active pregnancy.

@ProviderFor(supplementPlans)
final supplementPlansProvider = SupplementPlansProvider._();

/// Supplements of the active pregnancy.

final class SupplementPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SupplementPlan>>,
          List<SupplementPlan>,
          Stream<List<SupplementPlan>>
        >
    with
        $FutureModifier<List<SupplementPlan>>,
        $StreamProvider<List<SupplementPlan>> {
  /// Supplements of the active pregnancy.
  SupplementPlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplementPlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplementPlansHash();

  @$internal
  @override
  $StreamProviderElement<List<SupplementPlan>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SupplementPlan>> create(Ref ref) {
    return supplementPlans(ref);
  }
}

String _$supplementPlansHash() => r'7c7b5ecf90b0959582241911caedd2b5a16f42b2';
