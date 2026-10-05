// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reminderSettings)
final reminderSettingsProvider = ReminderSettingsProvider._();

final class ReminderSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReminderSettings>,
          ReminderSettings,
          Stream<ReminderSettings>
        >
    with $FutureModifier<ReminderSettings>, $StreamProvider<ReminderSettings> {
  ReminderSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSettingsHash();

  @$internal
  @override
  $StreamProviderElement<ReminderSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ReminderSettings> create(Ref ref) {
    return reminderSettings(ref);
  }
}

String _$reminderSettingsHash() => r'b3984b8fc1d4c802187c956d4f53aae0274e3d7d';
