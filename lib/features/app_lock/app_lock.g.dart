// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether Navmaas is locked (M10b, Plan decision 48). With app lock on it
/// starts locked, and locks again once she has been away for the minutes
/// she chose. Notification actions run without the app, so they keep
/// working; a notification or widget tap navigates underneath the lock.

@ProviderFor(AppLock)
final appLockProvider = AppLockProvider._();

/// Whether Navmaas is locked (M10b, Plan decision 48). With app lock on it
/// starts locked, and locks again once she has been away for the minutes
/// she chose. Notification actions run without the app, so they keep
/// working; a notification or widget tap navigates underneath the lock.
final class AppLockProvider extends $NotifierProvider<AppLock, bool> {
  /// Whether Navmaas is locked (M10b, Plan decision 48). With app lock on it
  /// starts locked, and locks again once she has been away for the minutes
  /// she chose. Notification actions run without the app, so they keep
  /// working; a notification or widget tap navigates underneath the lock.
  AppLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockHash();

  @$internal
  @override
  AppLock create() => AppLock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appLockHash() => r'e5b23a6f7f0ff0b4c1b356b33e3490ef34ace3ce';

/// Whether Navmaas is locked (M10b, Plan decision 48). With app lock on it
/// starts locked, and locks again once she has been away for the minutes
/// she chose. Notification actions run without the app, so they keep
/// working; a notification or widget tap navigates underneath the lock.

abstract class _$AppLock extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
