// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_limits.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appLimitsRepository)
final appLimitsRepositoryProvider = AppLimitsRepositoryProvider._();

final class AppLimitsRepositoryProvider
    extends
        $FunctionalProvider<
          AppLimitsRepository,
          AppLimitsRepository,
          AppLimitsRepository
        >
    with $Provider<AppLimitsRepository> {
  AppLimitsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLimitsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLimitsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppLimitsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppLimitsRepository create(Ref ref) {
    return appLimitsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLimitsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLimitsRepository>(value),
    );
  }
}

String _$appLimitsRepositoryHash() =>
    r'b87df5e57780f5513924819906e6fcb0d25d1813';

@ProviderFor(appLimits)
final appLimitsProvider = AppLimitsProvider._();

final class AppLimitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppLimit>>,
          List<AppLimit>,
          Stream<List<AppLimit>>
        >
    with $FutureModifier<List<AppLimit>>, $StreamProvider<List<AppLimit>> {
  AppLimitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLimitsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLimitsHash();

  @$internal
  @override
  $StreamProviderElement<List<AppLimit>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppLimit>> create(Ref ref) {
    return appLimits(ref);
  }
}

String _$appLimitsHash() => r'b9310f52c2dc855eee16a679394811eee9c04836';
