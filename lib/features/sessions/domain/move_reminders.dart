/// Move breaks (E6, Plan decision 82): a nudge to stand up and walk for 5
/// minutes, every hour or two in her hours on the days she picks, off by
/// default. As nudges they are dropped inside quiet hours and meal windows;
/// unlike other nudges they don't count toward the daily limit (ADR 068).
/// Pure Dart.
library;

import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Move breaks over the next [days] days: on each chosen weekday, every
/// `moveEvery` hours after `moveFrom`, up to and including `moveUntil`.
List<ReminderCandidate> moveCandidates({
  required DateTime now,
  required ReminderSettings settings,
  required AppLocalizations l10n,
  int days = 8,
}) {
  if (!settings.moveOn) return const [];
  final step = settings.moveEvery * 60;
  ReminderCandidate nudge(DateTime at) => ReminderCandidate(
    key: '$moveKeyPrefix${at.toIso8601String()}',
    at: at,
    kind: ReminderKind.nudge,
    title: l10n.reminderMoveTitle,
    body: l10n.reminderMoveBody,
  );
  return [
    for (var d = 0; d < days; d++)
      if (settings.moveDays.contains(
        '${DateTime(now.year, now.month, now.day + d).weekday}',
      ))
        for (
          var m = settings.moveFrom + step;
          m <= settings.moveUntil;
          m += step
        )
          nudge(DateTime(now.year, now.month, now.day + d, 0, m)),
  ];
}
