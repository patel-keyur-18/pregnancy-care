/// Screen Rest's own gentle nudges (ARCHITECTURE §7): a notice as each meal
/// window starts and the wind-down nudge. Pure Dart.
library;

import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Meal-time notices and wind-down nudges over the next [days] days.
List<ReminderCandidate> restCandidates({
  required DateTime now,
  required ReminderSettings settings,
  required AppLocalizations l10n,
  int days = 8,
}) => [
  for (var d = 0; d < days; d++) ...[
    if (settings.mealOn)
      for (final start in settings.mealStarts)
        _nudge(
          mealKeyPrefix,
          DateTime(now.year, now.month, now.day + d, 0, start),
          l10n.reminderMealTitle,
          l10n.reminderMealBody,
        ),
    if (settings.windDownOn)
      _nudge(
        windDownKeyPrefix,
        DateTime(now.year, now.month, now.day + d, 0, settings.windDownAt),
        l10n.reminderWindDownTitle,
        l10n.reminderWindDownBody,
      ),
  ],
];

ReminderCandidate _nudge(
  String prefix,
  DateTime at,
  String title,
  String body,
) => ReminderCandidate(
  key: '$prefix${at.toIso8601String()}',
  at: at,
  kind: ReminderKind.nudge,
  title: title,
  body: body,
);
