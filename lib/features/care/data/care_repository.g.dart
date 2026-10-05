// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(careRepository)
final careRepositoryProvider = CareRepositoryProvider._();

final class CareRepositoryProvider
    extends $FunctionalProvider<CareRepository, CareRepository, CareRepository>
    with $Provider<CareRepository> {
  CareRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'careRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$careRepositoryHash();

  @$internal
  @override
  $ProviderElement<CareRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CareRepository create(Ref ref) {
    return careRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CareRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CareRepository>(value),
    );
  }
}

String _$careRepositoryHash() => r'4c08d788c3bb564f598ae6009f388b776711de20';

/// Care items of the active pregnancy; seeds the template on first read.

@ProviderFor(careItems)
final careItemsProvider = CareItemsProvider._();

/// Care items of the active pregnancy; seeds the template on first read.

final class CareItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CareItem>>,
          List<CareItem>,
          Stream<List<CareItem>>
        >
    with $FutureModifier<List<CareItem>>, $StreamProvider<List<CareItem>> {
  /// Care items of the active pregnancy; seeds the template on first read.
  CareItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'careItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$careItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<CareItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CareItem>> create(Ref ref) {
    return careItems(ref);
  }
}

String _$careItemsHash() => r'a33c773c5b471cb91a955eed59799a5705d5b9b4';
