import 'package:navmaas/core/reminders/reminder_settings.dart';

/// A screen-free window in local time.
typedef RestWindow = ({DateTime start, DateTime end});

/// The rest window [now] falls in, or else the next one to start (bedtime
/// rest and meal times, whichever are on). Null when every rule is off.
RestWindow? nextRestWindow(ReminderSettings s, DateTime now) {
  final windows = <RestWindow>[
    for (var d = -1; d <= 1; d++) ...[
      if (s.quietOn)
        (
          start: _at(now, d, s.quietStart),
          // Crosses midnight when it ends "earlier" than it starts.
          end: _at(now, s.quietEnd <= s.quietStart ? d + 1 : d, s.quietEnd),
        ),
      if (s.mealOn)
        for (final m in s.mealStarts)
          (
            start: _at(now, d, m),
            end: _at(now, d, m + ReminderSettings.mealMinutes),
          ),
    ],
  ];
  RestWindow? next;
  for (final w in windows) {
    if (!now.isBefore(w.start) && now.isBefore(w.end)) return w;
    if (w.start.isAfter(now) &&
        (next == null || w.start.isBefore(next.start))) {
      next = w;
    }
  }
  return next;
}

DateTime _at(DateTime now, int days, int minute) =>
    DateTime(now.year, now.month, now.day + days, 0, minute);
