// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the home-screen widget's snapshot in step with the pregnancy, the
/// planned reminders and "Hide details" (Plan decisions 47 and 49).
/// Publishes only when the snapshot changes.

@ProviderFor(WidgetSync)
final widgetSyncProvider = WidgetSyncProvider._();

/// Keeps the home-screen widget's snapshot in step with the pregnancy, the
/// planned reminders and "Hide details" (Plan decisions 47 and 49).
/// Publishes only when the snapshot changes.
final class WidgetSyncProvider extends $NotifierProvider<WidgetSync, void> {
  /// Keeps the home-screen widget's snapshot in step with the pregnancy, the
  /// planned reminders and "Hide details" (Plan decisions 47 and 49).
  /// Publishes only when the snapshot changes.
  WidgetSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetSyncHash();

  @$internal
  @override
  WidgetSync create() => WidgetSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$widgetSyncHash() => r'd7e218f4225f7989e1e3017b62976d7ae063d151';

/// Keeps the home-screen widget's snapshot in step with the pregnancy, the
/// planned reminders and "Hide details" (Plan decisions 47 and 49).
/// Publishes only when the snapshot changes.

abstract class _$WidgetSync extends $Notifier<void> {
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
