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

/// Whether she has given Usage access (re-read when she comes back from
/// Settings).

@ProviderFor(usageAccess)
final usageAccessProvider = UsageAccessProvider._();

/// Whether she has given Usage access (re-read when she comes back from
/// Settings).

final class UsageAccessProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether she has given Usage access (re-read when she comes back from
  /// Settings).
  UsageAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usageAccessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usageAccessHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return usageAccess(ref);
  }
}

String _$usageAccessHash() => r'ec9b3eb941da038befb8a06a5c1d927d8114abfa';

/// The apps on her launcher, by package.

@ProviderFor(installedApps)
final installedAppsProvider = InstalledAppsProvider._();

/// The apps on her launcher, by package.

final class InstalledAppsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, InstalledApp>>,
          Map<String, InstalledApp>,
          FutureOr<Map<String, InstalledApp>>
        >
    with
        $FutureModifier<Map<String, InstalledApp>>,
        $FutureProvider<Map<String, InstalledApp>> {
  /// The apps on her launcher, by package.
  InstalledAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedAppsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, InstalledApp>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, InstalledApp>> create(Ref ref) {
    return installedApps(ref);
  }
}

String _$installedAppsHash() => r'e410920ff245dc169f3cfeeec463127619d3f451';

/// Today's minutes for each app she set a limit on.

@ProviderFor(limitMinutesToday)
final limitMinutesTodayProvider = LimitMinutesTodayProvider._();

/// Today's minutes for each app she set a limit on.

final class LimitMinutesTodayProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  /// Today's minutes for each app she set a limit on.
  LimitMinutesTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'limitMinutesTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$limitMinutesTodayHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return limitMinutesToday(ref);
  }
}

String _$limitMinutesTodayHash() => r'2a11222f2bf810dedbd71ef99945a61623e0e568';
