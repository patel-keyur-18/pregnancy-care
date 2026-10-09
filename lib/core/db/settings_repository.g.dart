// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'3f50af93b926c10969b8df7db297dfaa78f9ebf0';

@ProviderFor(firstName)
final firstNameProvider = FirstNameProvider._();

final class FirstNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  FirstNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstNameHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return firstName(ref);
  }
}

String _$firstNameHash() => r'ddb13adbb9ff01a86abd472055c0e7745f59ad81';

/// "Night reading after 9 pm" (Me → Appearance); on unless switched off.

@ProviderFor(nightReading)
final nightReadingProvider = NightReadingProvider._();

/// "Night reading after 9 pm" (Me → Appearance); on unless switched off.

final class NightReadingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// "Night reading after 9 pm" (Me → Appearance); on unless switched off.
  NightReadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nightReadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nightReadingHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return nightReading(ref);
  }
}

String _$nightReadingHash() => r'e2fb78068998232c10315df9286526204102de4a';

/// "Hide details on widget" (Me → Your data). Unless she has set it, it
/// follows app lock: off, or on while app lock is on (Plan decision 47).

@ProviderFor(widgetHideDetails)
final widgetHideDetailsProvider = WidgetHideDetailsProvider._();

/// "Hide details on widget" (Me → Your data). Unless she has set it, it
/// follows app lock: off, or on while app lock is on (Plan decision 47).

final class WidgetHideDetailsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// "Hide details on widget" (Me → Your data). Unless she has set it, it
  /// follows app lock: off, or on while app lock is on (Plan decision 47).
  WidgetHideDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetHideDetailsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetHideDetailsHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return widgetHideDetails(ref);
  }
}

String _$widgetHideDetailsHash() => r'cecc88cf0693916a178216367273eb38a0d7a1ed';

@ProviderFor(appLockSettings)
final appLockSettingsProvider = AppLockSettingsProvider._();

final class AppLockSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppLockSettings>,
          AppLockSettings,
          Stream<AppLockSettings>
        >
    with $FutureModifier<AppLockSettings>, $StreamProvider<AppLockSettings> {
  AppLockSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockSettingsHash();

  @$internal
  @override
  $StreamProviderElement<AppLockSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppLockSettings> create(Ref ref) {
    return appLockSettings(ref);
  }
}

String _$appLockSettingsHash() => r'ccd1eb6330aac8e8f89f1eed379398e3802fab8b';

/// The daily step goal she set on the Walk screen.

@ProviderFor(stepGoal)
final stepGoalProvider = StepGoalProvider._();

/// The daily step goal she set on the Walk screen.

final class StepGoalProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// The daily step goal she set on the Walk screen.
  StepGoalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stepGoalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stepGoalHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return stepGoal(ref);
  }
}

String _$stepGoalHash() => r'301ea04d8b2ba445c22737247c10053feccbd2b6';

/// The weekly backup reminder's day (`DateTime.monday` … `DateTime.sunday`),
/// or 0 when off. Sunday by default (Plan decision 32).

@ProviderFor(backupDay)
final backupDayProvider = BackupDayProvider._();

/// The weekly backup reminder's day (`DateTime.monday` … `DateTime.sunday`),
/// or 0 when off. Sunday by default (Plan decision 32).

final class BackupDayProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// The weekly backup reminder's day (`DateTime.monday` … `DateTime.sunday`),
  /// or 0 when off. Sunday by default (Plan decision 32).
  BackupDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupDayHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return backupDay(ref);
  }
}

String _$backupDayHash() => r'124a1d5139936cf7d2bdfc973750c96e30322828';

/// "Include voice letters" in backups (E3; default off).

@ProviderFor(backupVoice)
final backupVoiceProvider = BackupVoiceProvider._();

/// "Include voice letters" in backups (E3; default off).

final class BackupVoiceProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// "Include voice letters" in backups (E3; default off).
  BackupVoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupVoiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupVoiceHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return backupVoice(ref);
  }
}

String _$backupVoiceHash() => r'58f4065aadba959c3edebfb09355b5e7405274ac';
