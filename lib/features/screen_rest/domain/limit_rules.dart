/// What the Android app-limit check needs to follow the calm rules (Plan
/// decision 53, ADR 050). The check runs natively every 15 minutes; this
/// tells it, for the week ahead, when a notice may go out (outside quiet
/// hours and meal windows, so a notice waits for a window to end), how many
/// more notifications each day has room for under the daily limit, and
/// each app's ready-made notice. Pure Dart.
library;

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// One app's limit, as the rules need it.
typedef LimitRule = ({String package, String label, int minutes});

/// The rules as JSON. With reminders off, or no active pregnancy (the notice
/// speaks of baby time), no day has room, so no notice goes out.
String limitRules({
  required DateTime now,
  required ReminderSettings settings,
  required bool active,
  required List<PlannedReminder> planned,
  required List<LimitRule> limits,
  required AppLocalizations l10n,
  int days = 7,
}) {
  final allowed = settings.on && active;
  return jsonEncode({
    'v': 1,
    'channel': l10n.reminderChannel,
    'channelDescription': l10n.reminderChannelDescription,
    'limits': [
      for (final l in limits)
        {
          'package': l.package,
          'minutes': l.minutes,
          'title': l10n.appLimitNoticeTitle,
          'body': l10n.appLimitNoticeBody(l.minutes, l.label),
        },
    ],
    'days': [
      if (allowed)
        for (var d = 0; d < days; d++)
          _day(DateTime(now.year, now.month, now.day + d), settings, planned),
    ],
  });
}

Map<String, Object> _day(
  DateTime day,
  ReminderSettings settings,
  List<PlannedReminder> planned,
) {
  bool open(int minute) =>
      !settings.isQuiet(minute) && settings.mealEnd(minute) == null;
  final windows = <List<int>>[];
  int? start;
  for (var m = 0; m <= 24 * 60; m++) {
    final isOpen = m < 24 * 60 && open(m);
    if (isOpen && start == null) start = m;
    if (!isOpen && start != null) {
      windows.add([
        DateTime(day.year, day.month, day.day, 0, start).millisecondsSinceEpoch,
        DateTime(day.year, day.month, day.day, 0, m).millisecondsSinceEpoch,
      ]);
      start = null;
    }
  }
  final count = planned
      .where(
        (p) =>
            p.at.year == day.year &&
            p.at.month == day.month &&
            p.at.day == day.day,
      )
      .length;
  return {
    'date': DateFormat('yyyy-MM-dd').format(day),
    'room': (settings.dailyLimit - count).clamp(0, settings.dailyLimit),
    'open': windows,
  };
}
