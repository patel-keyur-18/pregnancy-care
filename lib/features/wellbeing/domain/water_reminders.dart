/// Water reminders (Plan decision 41): gentle nudges every 2 or 3 hours in
/// the day, off by default. As nudges they are dropped inside quiet hours
/// and meal windows, rank last under the daily limit and never join the
/// digest (ADR 038). Pure Dart.
library;

import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Key prefix of a water nudge.
const waterKeyPrefix = 'water@';

/// Water nudges over the next [days] days, every `waterEvery` hours from
/// the end of quiet hours. Today's are skipped once [goalReached].
List<ReminderCandidate> waterCandidates({
  required DateTime now,
  required ReminderSettings settings,
  required bool goalReached,
  required AppLocalizations l10n,
  int days = 8,
}) {
  if (!settings.waterOn) return const [];
  final step = settings.waterEvery * 60;
  ReminderCandidate nudge(DateTime at) => ReminderCandidate(
    key: '$waterKeyPrefix${at.toIso8601String()}',
    at: at,
    kind: ReminderKind.nudge,
    title: l10n.reminderWaterTitle,
    body: l10n.reminderWaterBody,
  );
  return [
    for (var d = goalReached ? 1 : 0; d < days; d++)
      for (
        var m = settings.waterFrom + step;
        m < settings.waterUntil;
        m += step
      )
        nudge(DateTime(now.year, now.month, now.day + d, 0, m)),
  ];
}
