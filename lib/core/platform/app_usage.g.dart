// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_usage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appUsage)
final appUsageProvider = AppUsageProvider._();

final class AppUsageProvider
    extends $FunctionalProvider<AppUsage, AppUsage, AppUsage>
    with $Provider<AppUsage> {
  AppUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUsageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUsageHash();

  @$internal
  @override
  $ProviderElement<AppUsage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUsage create(Ref ref) {
    return appUsage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUsage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUsage>(value),
    );
  }
}

String _$appUsageHash() => r'133a7146b2cb2e81cb69a30f1a77c2e6da22a18f';
