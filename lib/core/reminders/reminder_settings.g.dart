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

String _$reminderSettingsHash() => r'a8339af058d4b493ab7991383aa74d048aaacc56';
