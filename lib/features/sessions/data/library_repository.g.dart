// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(libraryRepository)
final libraryRepositoryProvider = LibraryRepositoryProvider._();

final class LibraryRepositoryProvider
    extends
        $FunctionalProvider<
          LibraryRepository,
          LibraryRepository,
          LibraryRepository
        >
    with $Provider<LibraryRepository> {
  LibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<LibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LibraryRepository create(Ref ref) {
    return libraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryRepository>(value),
    );
  }
}

String _$libraryRepositoryHash() => r'2ccc6473ad0ea427ab79dc91b21b1e488c4d408b';

@ProviderFor(libraryItems)
final libraryItemsProvider = LibraryItemsProvider._();

final class LibraryItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LibraryItem>>,
          List<LibraryItem>,
          Stream<List<LibraryItem>>
        >
    with
        $FutureModifier<List<LibraryItem>>,
        $StreamProvider<List<LibraryItem>> {
  LibraryItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<LibraryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LibraryItem>> create(Ref ref) {
    return libraryItems(ref);
  }
}

String _$libraryItemsHash() => r'84537481bfdc92f60d49785ccc3f8c4d5bf5d1c1';

@ProviderFor(pickFile)
final pickFileProvider = PickFileProvider._();

final class PickFileProvider
    extends $FunctionalProvider<PickFile, PickFile, PickFile>
    with $Provider<PickFile> {
  PickFileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pickFileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pickFileHash();

  @$internal
  @override
  $ProviderElement<PickFile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PickFile create(Ref ref) {
    return pickFile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickFile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickFile>(value),
    );
  }
}

String _$pickFileHash() => r'd9fc74fe30d30638f69c8b0fda2c4142c05bbfca';
