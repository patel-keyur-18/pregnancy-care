import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Reminders that protect her data. They keep running while pregnancy
/// tracking is paused or ended.
///
/// iPhone build expiry: the day before at 10:00, "back up, then run it from
/// Xcode again" (ARCHITECTURE §12).
List<ReminderCandidate> buildExpiryCandidates({
  required DateTime? expiry,
  required AppLocalizations l10n,
}) {
  if (expiry == null) return const [];
  final local = expiry.toLocal();
  return [
    ReminderCandidate(
      key: 'build-expiry@${expiry.toIso8601String()}',
      at: DateTime(local.year, local.month, local.day - 1, 10),
      kind: ReminderKind.buildExpiry,
      title: l10n.reminderBuildTitle,
      body: l10n.reminderBuildBody,
    ),
  ];
}
