// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupService)
final backupServiceProvider = BackupServiceProvider._();

final class BackupServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<BackupService>,
          BackupService,
          FutureOr<BackupService>
        >
    with $FutureModifier<BackupService>, $FutureProvider<BackupService> {
  BackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupServiceHash();

  @$internal
  @override
  $FutureProviderElement<BackupService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BackupService> create(Ref ref) {
    return backupService(ref);
  }
}

String _$backupServiceHash() => r'0796cf1ccc4b5eb42b0763d789510a6a5f58091d';

/// How big a backup will be, with and without the library.

@ProviderFor(backupSizes)
final backupSizesProvider = BackupSizesProvider._();

/// How big a backup will be, with and without the library.

final class BackupSizesProvider
    extends
        $FunctionalProvider<
          AsyncValue<({int base, int library})>,
          ({int base, int library}),
          FutureOr<({int base, int library})>
        >
    with
        $FutureModifier<({int base, int library})>,
        $FutureProvider<({int base, int library})> {
  /// How big a backup will be, with and without the library.
  BackupSizesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupSizesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupSizesHash();

  @$internal
  @override
  $FutureProviderElement<({int base, int library})> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({int base, int library})> create(Ref ref) {
    return backupSizes(ref);
  }
}

String _$backupSizesHash() => r'734844e6cff4e30debcaecccbd8d85d5a4fcb872';

@ProviderFor(shareFile)
final shareFileProvider = ShareFileProvider._();

final class ShareFileProvider
    extends $FunctionalProvider<ShareFile, ShareFile, ShareFile>
    with $Provider<ShareFile> {
  ShareFileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareFileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareFileHash();

  @$internal
  @override
  $ProviderElement<ShareFile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareFile create(Ref ref) {
    return shareFile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareFile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareFile>(value),
    );
  }
}

String _$shareFileHash() => r'e3ed85e950092d3035d4032cb88901e503539f53';
