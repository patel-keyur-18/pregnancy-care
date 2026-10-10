// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nourishly.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nourishlySource)
final nourishlySourceProvider = NourishlySourceProvider._();

final class NourishlySourceProvider
    extends
        $FunctionalProvider<NourishlySource, NourishlySource, NourishlySource>
    with $Provider<NourishlySource> {
  NourishlySourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nourishlySourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nourishlySourceHash();

  @$internal
  @override
  $ProviderElement<NourishlySource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NourishlySource create(Ref ref) {
    return nourishlySource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NourishlySource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NourishlySource>(value),
    );
  }
}

String _$nourishlySourceHash() => r'05a9ddecbea24875b34cc87e00b677fc11f59875';
