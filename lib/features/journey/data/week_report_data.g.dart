// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_report_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Each day's steps from [from] (a date) for [days] days, the last one up to
/// now; nulls without Health access (never asks for it).

@ProviderFor(weekSteps)
final weekStepsProvider = WeekStepsFamily._();

/// Each day's steps from [from] (a date) for [days] days, the last one up to
/// now; nulls without Health access (never asks for it).

final class WeekStepsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<int?>>,
          List<int?>,
          FutureOr<List<int?>>
        >
    with $FutureModifier<List<int?>>, $FutureProvider<List<int?>> {
  /// Each day's steps from [from] (a date) for [days] days, the last one up to
  /// now; nulls without Health access (never asks for it).
  WeekStepsProvider._({
    required WeekStepsFamily super.from,
    required (DateTime, int) super.argument,
  }) : super(
         retry: null,
         name: r'weekStepsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weekStepsHash();

  @override
  String toString() {
    return r'weekStepsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<int?>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<int?>> create(Ref ref) {
    final argument = this.argument as (DateTime, int);
    return weekSteps(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WeekStepsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weekStepsHash() => r'db5db1ab83623a779de48cf3092c23c5eb001616';

/// Each day's steps from [from] (a date) for [days] days, the last one up to
/// now; nulls without Health access (never asks for it).

final class WeekStepsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<int?>>, (DateTime, int)> {
  WeekStepsFamily._()
    : super(
        retry: null,
        name: r'weekStepsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Each day's steps from [from] (a date) for [days] days, the last one up to
  /// now; nulls without Health access (never asks for it).

  WeekStepsProvider call(DateTime from, int days) =>
      WeekStepsProvider._(argument: (from, days), from: this);

  @override
  String toString() => r'weekStepsProvider';
}

@ProviderFor(_moodsFrom)
final _moodsFromProvider = _MoodsFromFamily._();

final class _MoodsFromProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MoodEntry>>,
          List<MoodEntry>,
          Stream<List<MoodEntry>>
        >
    with $FutureModifier<List<MoodEntry>>, $StreamProvider<List<MoodEntry>> {
  _MoodsFromProvider._({
    required _MoodsFromFamily super.from,
    required (String, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'_moodsFromProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_moodsFromHash();

  @override
  String toString() {
    return r'_moodsFromProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<MoodEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MoodEntry>> create(Ref ref) {
    final argument = this.argument as (String, DateTime);
    return _moodsFrom(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _MoodsFromProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_moodsFromHash() => r'80da3e65f24c74106a761a5631d8053f82545c6c';

final class _MoodsFromFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<MoodEntry>>, (String, DateTime)> {
  _MoodsFromFamily._()
    : super(
        retry: null,
        name: r'_moodsFromProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _MoodsFromProvider call(String pregnancyId, DateTime from) =>
      _MoodsFromProvider._(argument: (pregnancyId, from), from: this);

  @override
  String toString() => r'_moodsFromProvider';
}

@ProviderFor(_sleepFrom)
final _sleepFromProvider = _SleepFromFamily._();

final class _SleepFromProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SleepLog>>,
          List<SleepLog>,
          Stream<List<SleepLog>>
        >
    with $FutureModifier<List<SleepLog>>, $StreamProvider<List<SleepLog>> {
  _SleepFromProvider._({
    required _SleepFromFamily super.from,
    required (String, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'_sleepFromProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_sleepFromHash();

  @override
  String toString() {
    return r'_sleepFromProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<SleepLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SleepLog>> create(Ref ref) {
    final argument = this.argument as (String, DateTime);
    return _sleepFrom(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _SleepFromProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_sleepFromHash() => r'ae8ef842f0b1b0a9cd0f922c5b79a16f631eea34';

final class _SleepFromFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SleepLog>>, (String, DateTime)> {
  _SleepFromFamily._()
    : super(
        retry: null,
        name: r'_sleepFromProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _SleepFromProvider call(String pregnancyId, DateTime from) =>
      _SleepFromProvider._(argument: (pregnancyId, from), from: this);

  @override
  String toString() => r'_sleepFromProvider';
}

@ProviderFor(_waterFrom)
final _waterFromProvider = _WaterFromFamily._();

final class _WaterFromProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WaterLog>>,
          List<WaterLog>,
          Stream<List<WaterLog>>
        >
    with $FutureModifier<List<WaterLog>>, $StreamProvider<List<WaterLog>> {
  _WaterFromProvider._({
    required _WaterFromFamily super.from,
    required (String, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'_waterFromProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_waterFromHash();

  @override
  String toString() {
    return r'_waterFromProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<WaterLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WaterLog>> create(Ref ref) {
    final argument = this.argument as (String, DateTime);
    return _waterFrom(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _WaterFromProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_waterFromHash() => r'ad39386c1a937fd58778ce91dd2a952d27d17712';

final class _WaterFromFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<WaterLog>>, (String, DateTime)> {
  _WaterFromFamily._()
    : super(
        retry: null,
        name: r'_waterFromProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _WaterFromProvider call(String pregnancyId, DateTime from) =>
      _WaterFromProvider._(argument: (pregnancyId, from), from: this);

  @override
  String toString() => r'_waterFromProvider';
}

/// "Your week" for pregnancy week [week] of the active pregnancy (E7), or
/// null for a week still to come.

@ProviderFor(weekReportOf)
final weekReportOfProvider = WeekReportOfFamily._();

/// "Your week" for pregnancy week [week] of the active pregnancy (E7), or
/// null for a week still to come.

final class WeekReportOfProvider
    extends $FunctionalProvider<WeekReport?, WeekReport?, WeekReport?>
    with $Provider<WeekReport?> {
  /// "Your week" for pregnancy week [week] of the active pregnancy (E7), or
  /// null for a week still to come.
  WeekReportOfProvider._({
    required WeekReportOfFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'weekReportOfProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weekReportOfHash();

  @override
  String toString() {
    return r'weekReportOfProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<WeekReport?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeekReport? create(Ref ref) {
    final argument = this.argument as int;
    return weekReportOf(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeekReport? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeekReport?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WeekReportOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weekReportOfHash() => r'1551bf3d69b76afee63052bff554b5db70d8b643';

/// "Your week" for pregnancy week [week] of the active pregnancy (E7), or
/// null for a week still to come.

final class WeekReportOfFamily extends $Family
    with $FunctionalFamilyOverride<WeekReport?, int> {
  WeekReportOfFamily._()
    : super(
        retry: null,
        name: r'weekReportOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// "Your week" for pregnancy week [week] of the active pregnancy (E7), or
  /// null for a week still to come.

  WeekReportOfProvider call(int week) =>
      WeekReportOfProvider._(argument: week, from: this);

  @override
  String toString() => r'weekReportOfProvider';
}
