// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Today" as a calendar date. Override in tests for a fixed day; the app
/// refreshes it when it comes back to the foreground.

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// "Today" as a calendar date. Override in tests for a fixed day; the app
/// refreshes it when it comes back to the foreground.

final class TodayProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// "Today" as a calendar date. Override in tests for a fixed day; the app
  /// refreshes it when it comes back to the foreground.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return today(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$todayHash() => r'c5a40ffe017712dff79bc46c4cacaac32e6cc79c';

/// The current time, for time-of-day wording such as the greeting. Fixed in
/// tests; refreshed with [todayProvider] when the app resumes.

@ProviderFor(now)
final nowProvider = NowProvider._();

/// The current time, for time-of-day wording such as the greeting. Fixed in
/// tests; refreshed with [todayProvider] when the app resumes.

final class NowProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// The current time, for time-of-day wording such as the greeting. Fixed in
  /// tests; refreshed with [todayProvider] when the app resumes.
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$nowHash() => r'810d768cae31a46f26690d5f1bef273aed5eb51d';
