// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the OS schedule in step with supplements, taken doses and the
/// calm-notification settings. Re-plans on any change and on resume. Its
/// state is the plan, which the home-screen widget shows the next of.

@ProviderFor(ReminderSync)
final reminderSyncProvider = ReminderSyncProvider._();

/// Keeps the OS schedule in step with supplements, taken doses and the
/// calm-notification settings. Re-plans on any change and on resume. Its
/// state is the plan, which the home-screen widget shows the next of.
final class ReminderSyncProvider
    extends $NotifierProvider<ReminderSync, List<PlannedReminder>> {
  /// Keeps the OS schedule in step with supplements, taken doses and the
  /// calm-notification settings. Re-plans on any change and on resume. Its
  /// state is the plan, which the home-screen widget shows the next of.
  ReminderSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSyncHash();

  @$internal
  @override
  ReminderSync create() => ReminderSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PlannedReminder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PlannedReminder>>(value),
    );
  }
}

String _$reminderSyncHash() => r'ef9a98228fcabaf1731d57970cea4c6381cfd80e';

/// Keeps the OS schedule in step with supplements, taken doses and the
/// calm-notification settings. Re-plans on any change and on resume. Its
/// state is the plan, which the home-screen widget shows the next of.

abstract class _$ReminderSync extends $Notifier<List<PlannedReminder>> {
  List<PlannedReminder> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<PlannedReminder>, List<PlannedReminder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PlannedReminder>, List<PlannedReminder>>,
              List<PlannedReminder>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Doses taken from today for the next 8 days (the planning window).

@ProviderFor(_upcomingTaken)
final _upcomingTakenProvider = _UpcomingTakenProvider._();

/// Doses taken from today for the next 8 days (the planning window).

final class _UpcomingTakenProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Doses taken from today for the next 8 days (the planning window).
  _UpcomingTakenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_upcomingTakenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_upcomingTakenHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return _upcomingTaken(ref);
  }
}

String _$_upcomingTakenHash() => r'b8cb530fd23526676350f25a2b34fad9af2d5eef';
