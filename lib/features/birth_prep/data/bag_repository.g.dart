// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bag_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bagRepository)
final bagRepositoryProvider = BagRepositoryProvider._();

final class BagRepositoryProvider
    extends $FunctionalProvider<BagRepository, BagRepository, BagRepository>
    with $Provider<BagRepository> {
  BagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bagRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bagRepositoryHash();

  @$internal
  @override
  $ProviderElement<BagRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BagRepository create(Ref ref) {
    return bagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BagRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BagRepository>(value),
    );
  }
}

String _$bagRepositoryHash() => r'a1d3a213f26301311661733d8675f8bac27fb678';

/// The bag as shown: the template with her ticks, then her own items.

@ProviderFor(bag)
final bagProvider = BagProvider._();

/// The bag as shown: the template with her ticks, then her own items.

final class BagProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BagRow>>,
          List<BagRow>,
          Stream<List<BagRow>>
        >
    with $FutureModifier<List<BagRow>>, $StreamProvider<List<BagRow>> {
  /// The bag as shown: the template with her ticks, then her own items.
  BagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bagProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bagHash();

  @$internal
  @override
  $StreamProviderElement<List<BagRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BagRow>> create(Ref ref) {
    return bag(ref);
  }
}

String _$bagHash() => r'fd13809610c79a6fef03a3f2dc12bf89a6ffdd93';
