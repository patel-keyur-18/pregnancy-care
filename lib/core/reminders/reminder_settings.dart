import 'package:navmaas/core/db/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_settings.g.dart';

/// Calm-notification settings (Me → Calm notifications). Times are minutes
/// after midnight; quiet hours may cross midnight.
class ReminderSettings {
  const new({
    this.on = false,
    this.dailyLimit = 4,
    this.quietStart = 21 * 60 + 30,
    this.quietEnd = 7 * 60,
  });

  factory fromSettings(Map<String, String> s) => ReminderSettings(
    on: s[SettingKeys.remindersOn] == 'true',
    dailyLimit: int.tryParse(s[SettingKeys.dailyLimit] ?? '') ?? 4,
    quietStart: int.tryParse(s[SettingKeys.quietStart] ?? '') ?? 21 * 60 + 30,
    quietEnd: int.tryParse(s[SettingKeys.quietEnd] ?? '') ?? 7 * 60,
  );

  static const minLimit = 1;
  static const maxLimit = 8;

  final bool on;
  final int dailyLimit;
  final int quietStart;
  final int quietEnd;

  /// Whether [minute] (after midnight) falls inside quiet hours.
  bool isQuiet(int minute) => quietStart <= quietEnd
      ? minute >= quietStart && minute < quietEnd
      : minute >= quietStart || minute < quietEnd;
}

@Riverpod(keepAlive: true)
Stream<ReminderSettings> reminderSettings(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watchAll()
    .map(ReminderSettings.fromSettings);
