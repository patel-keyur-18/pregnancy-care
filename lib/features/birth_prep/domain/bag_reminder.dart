import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The one-off "Pack the hospital bag" reminder she set (M8a), if still
/// ahead. It follows the calm rules like any other reminder.
List<ReminderCandidate> bagCandidates({
  required DateTime now,
  required DateTime? at,
  required AppLocalizations l10n,
}) => [
  if (at != null && at.isAfter(now))
    ReminderCandidate(
      key: 'bag:${at.toIso8601String()}',
      at: at,
      kind: ReminderKind.careItem,
      title: l10n.reminderBagTitle,
      body: l10n.reminderBagBody,
    ),
];
