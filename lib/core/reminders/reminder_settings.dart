import 'package:flutter/foundation.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_settings.g.dart';

/// Calm-notification settings (Me → Calm notifications) and the Screen Rest
/// rules that shape reminders. Times are minutes after midnight; quiet hours
/// may cross midnight.
@immutable
class ReminderSettings {
  const new({
    this.on = false,
    this.dailyLimit = 4,
    this.quietOn = true,
    this.quietStart = 21 * 60 + 30,
    this.quietEnd = 7 * 60,
    this.mealOn = true,
    this.mealLunch = 13 * 60,
    this.mealDinner = 20 * 60,
    this.windDownOn = false,
    this.windDownAt = 21 * 60,
    this.waterOn = false,
    this.waterEvery = 2,
    this.bagAt,
  });

  factory fromSettings(Map<String, String> s) {
    int minutes(String key, int fallback) =>
        int.tryParse(s[key] ?? '') ?? fallback;
    return ReminderSettings(
      on: s[SettingKeys.remindersOn] == 'true',
      dailyLimit: minutes(SettingKeys.dailyLimit, 4),
      quietOn: s[SettingKeys.quietOn] != 'false',
      quietStart: minutes(SettingKeys.quietStart, 21 * 60 + 30),
      quietEnd: minutes(SettingKeys.quietEnd, 7 * 60),
      mealOn: s[SettingKeys.mealRest] != 'false',
      mealLunch: minutes(SettingKeys.mealLunch, 13 * 60),
      mealDinner: minutes(SettingKeys.mealDinner, 20 * 60),
      windDownOn: s[SettingKeys.windDown] == 'true',
      windDownAt: minutes(SettingKeys.windDownAt, 21 * 60),
      waterOn: s[SettingKeys.waterRemind] == 'true',
      waterEvery: s[SettingKeys.waterEvery] == '3' ? 3 : 2,
      bagAt: DateTime.tryParse(s[SettingKeys.bagRemindAt] ?? ''),
    );
  }

  static const minLimit = 1;
  static const maxLimit = 8;

  /// Each meal window lasts this long from its start.
  static const mealMinutes = 45;

  final bool on;
  final int dailyLimit;

  /// Screen Rest → Bedtime rest: quiet hours apply.
  final bool quietOn;
  final int quietStart;
  final int quietEnd;

  /// Screen Rest → Meal times: two windows that hold reminders.
  final bool mealOn;
  final int mealLunch;
  final int mealDinner;

  /// Screen Rest → Wind-down audio: a nudge at [windDownAt].
  final bool windDownOn;
  final int windDownAt;

  /// Wellbeing → Water reminders (default off): a nudge every [waterEvery]
  /// hours (2 or 3) in the day (Plan decision 41).
  final bool waterOn;
  final int waterEvery;

  /// Hospital bag → "Remind me to pack" (M8a): one reminder, or null.
  final DateTime? bagAt;

  List<int> get mealStarts => [mealLunch, mealDinner];

  /// Water nudges run from the end of quiet hours to their start (7:00 am to
  /// 9:30 pm when bedtime rest is off).
  int get waterFrom => quietOn ? quietEnd : 7 * 60;
  int get waterUntil => quietOn ? quietStart : 21 * 60 + 30;

  /// Whether [minute] (after midnight) falls inside quiet hours.
  bool isQuiet(int minute) =>
      quietOn &&
      (quietStart <= quietEnd
          ? minute >= quietStart && minute < quietEnd
          : minute >= quietStart || minute < quietEnd);

  /// The end of the meal window [minute] falls in, or null.
  int? mealEnd(int minute) {
    if (!mealOn) return null;
    for (final start in mealStarts) {
      if (minute >= start && minute < start + mealMinutes) {
        return start + mealMinutes;
      }
    }
    return null;
  }

  Object get _fields => (
    on,
    dailyLimit,
    quietOn,
    quietStart,
    quietEnd,
    mealOn,
    mealLunch,
    mealDinner,
    windDownOn,
    windDownAt,
    waterOn,
    waterEvery,
    bagAt,
  );

  // Equal values don't re-plan reminders when an unrelated setting changes.
  @override
  bool operator ==(Object other) =>
      other is ReminderSettings && other._fields == _fields;

  @override
  int get hashCode => _fields.hashCode;
}

@Riverpod(keepAlive: true)
Stream<ReminderSettings> reminderSettings(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watchAll()
    .map(ReminderSettings.fromSettings)
    .distinct();
