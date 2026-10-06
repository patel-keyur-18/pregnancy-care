// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_limit_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the Android app-limit check's rules in step with the reminder
/// plan, the calm-notification settings, her limits and tracking (Plan
/// decision 53). Sends them only when they change; Android only.

@ProviderFor(AppLimitSync)
final appLimitSyncProvider = AppLimitSyncProvider._();

/// Keeps the Android app-limit check's rules in step with the reminder
/// plan, the calm-notification settings, her limits and tracking (Plan
/// decision 53). Sends them only when they change; Android only.
final class AppLimitSyncProvider extends $NotifierProvider<AppLimitSync, void> {
  /// Keeps the Android app-limit check's rules in step with the reminder
  /// plan, the calm-notification settings, her limits and tracking (Plan
  /// decision 53). Sends them only when they change; Android only.
  AppLimitSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLimitSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLimitSyncHash();

  @$internal
  @override
  AppLimitSync create() => AppLimitSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appLimitSyncHash() => r'7721aa0092267faf976eaf21bbd61aa37f453468';

/// Keeps the Android app-limit check's rules in step with the reminder
/// plan, the calm-notification settings, her limits and tracking (Plan
/// decision 53). Sends them only when they change; Android only.

abstract class _$AppLimitSync extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
