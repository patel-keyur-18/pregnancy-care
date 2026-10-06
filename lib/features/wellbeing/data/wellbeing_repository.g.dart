// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wellbeing_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wellbeingRepository)
final wellbeingRepositoryProvider = WellbeingRepositoryProvider._();

final class WellbeingRepositoryProvider
    extends
        $FunctionalProvider<
          WellbeingRepository,
          WellbeingRepository,
          WellbeingRepository
        >
    with $Provider<WellbeingRepository> {
  WellbeingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wellbeingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wellbeingRepositoryHash();

  @$internal
  @override
  $ProviderElement<WellbeingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WellbeingRepository create(Ref ref) {
    return wellbeingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WellbeingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WellbeingRepository>(value),
    );
  }
}

String _$wellbeingRepositoryHash() =>
    r'0de6ce114c1bad4a879f864f8af523026861b9a6';

@ProviderFor(weekMoods)
final weekMoodsProvider = WeekMoodsProvider._();

final class WeekMoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MoodEntry>>,
          List<MoodEntry>,
          Stream<List<MoodEntry>>
        >
    with $FutureModifier<List<MoodEntry>>, $StreamProvider<List<MoodEntry>> {
  WeekMoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekMoodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekMoodsHash();

  @$internal
  @override
  $StreamProviderElement<List<MoodEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MoodEntry>> create(Ref ref) {
    return weekMoods(ref);
  }
}

String _$weekMoodsHash() => r'4816dc10d8b93feef4accaf64db9f19f13f6792b';

@ProviderFor(weekSymptoms)
final weekSymptomsProvider = WeekSymptomsProvider._();

final class WeekSymptomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SymptomEntry>>,
          List<SymptomEntry>,
          Stream<List<SymptomEntry>>
        >
    with
        $FutureModifier<List<SymptomEntry>>,
        $StreamProvider<List<SymptomEntry>> {
  WeekSymptomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekSymptomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekSymptomsHash();

  @$internal
  @override
  $StreamProviderElement<List<SymptomEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SymptomEntry>> create(Ref ref) {
    return weekSymptoms(ref);
  }
}

String _$weekSymptomsHash() => r'80126cc16ad8f31064e831f8a38e78c5ecea6806';

@ProviderFor(weekSleep)
final weekSleepProvider = WeekSleepProvider._();

final class WeekSleepProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SleepLog>>,
          List<SleepLog>,
          Stream<List<SleepLog>>
        >
    with $FutureModifier<List<SleepLog>>, $StreamProvider<List<SleepLog>> {
  WeekSleepProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekSleepProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekSleepHash();

  @$internal
  @override
  $StreamProviderElement<List<SleepLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SleepLog>> create(Ref ref) {
    return weekSleep(ref);
  }
}

String _$weekSleepHash() => r'493122313c2287cd491b4ebbd5896b21d880231a';

@ProviderFor(weekWater)
final weekWaterProvider = WeekWaterProvider._();

final class WeekWaterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WaterLog>>,
          List<WaterLog>,
          Stream<List<WaterLog>>
        >
    with $FutureModifier<List<WaterLog>>, $StreamProvider<List<WaterLog>> {
  WeekWaterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekWaterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekWaterHash();

  @$internal
  @override
  $StreamProviderElement<List<WaterLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WaterLog>> create(Ref ref) {
    return weekWater(ref);
  }
}

String _$weekWaterHash() => r'46caa24557e4d4679ef8118bb3eb678577af2a8f';

/// The last 7 days, today first.

@ProviderFor(wellbeingWeek)
final wellbeingWeekProvider = WellbeingWeekProvider._();

/// The last 7 days, today first.

final class WellbeingWeekProvider
    extends
        $FunctionalProvider<
          List<WellbeingDay>,
          List<WellbeingDay>,
          List<WellbeingDay>
        >
    with $Provider<List<WellbeingDay>> {
  /// The last 7 days, today first.
  WellbeingWeekProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wellbeingWeekProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wellbeingWeekHash();

  @$internal
  @override
  $ProviderElement<List<WellbeingDay>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<WellbeingDay> create(Ref ref) {
    return wellbeingWeek(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<WellbeingDay> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<WellbeingDay>>(value),
    );
  }
}

String _$wellbeingWeekHash() => r'ef77dae59a15f8d2391b3752954e5a9cb6992309';

/// Her latest symptom logs (newest first), to put her usual ones first.

@ProviderFor(recentSymptoms)
final recentSymptomsProvider = RecentSymptomsProvider._();

/// Her latest symptom logs (newest first), to put her usual ones first.

final class RecentSymptomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SymptomEntry>>,
          List<SymptomEntry>,
          Stream<List<SymptomEntry>>
        >
    with
        $FutureModifier<List<SymptomEntry>>,
        $StreamProvider<List<SymptomEntry>> {
  /// Her latest symptom logs (newest first), to put her usual ones first.
  RecentSymptomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSymptomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSymptomsHash();

  @$internal
  @override
  $StreamProviderElement<List<SymptomEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SymptomEntry>> create(Ref ref) {
    return recentSymptoms(ref);
  }
}

String _$recentSymptomsHash() => r'5e86d1854ec14677f7ab22a5fb92b19e963d36bb';

/// Daily water goal in glasses (Plan decision 41: default 8, 4–16).

@ProviderFor(waterGoal)
final waterGoalProvider = WaterGoalProvider._();

/// Daily water goal in glasses (Plan decision 41: default 8, 4–16).

final class WaterGoalProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Daily water goal in glasses (Plan decision 41: default 8, 4–16).
  WaterGoalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waterGoalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waterGoalHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return waterGoal(ref);
  }
}

String _$waterGoalHash() => r'7655166fb13d5987b94470ef2012c4a7e4718b74';
