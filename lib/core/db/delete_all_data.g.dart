// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_all_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteAllData)
final deleteAllDataProvider = DeleteAllDataProvider._();

final class DeleteAllDataProvider
    extends $FunctionalProvider<DeleteAllData, DeleteAllData, DeleteAllData>
    with $Provider<DeleteAllData> {
  DeleteAllDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAllDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAllDataHash();

  @$internal
  @override
  $ProviderElement<DeleteAllData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteAllData create(Ref ref) {
    return deleteAllData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteAllData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteAllData>(value),
    );
  }
}

String _$deleteAllDataHash() => r'27009f4792e6856f293ab2e4d6e833b7e816e73b';
