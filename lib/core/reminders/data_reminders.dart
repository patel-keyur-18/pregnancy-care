/// Reminders that protect her data. They keep running while pregnancy
/// tracking is paused or ended.
library;

import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The weekly backup reminder: [day] (1–7, 0 for off) at 10:00 over the
/// next week. Skipped when she backed up in the 6 days before it, or when
/// the build-expiry reminder (which also says "back up") is that day.
List<ReminderCandidate> backupCandidates({
  required DateTime now,
  required int day,
  required DateTime? lastBackup,
  required DateTime? expiry,
  required AppLocalizations l10n,
  int days = 8,
}) {
  if (day < DateTime.monday || day > DateTime.sunday) return const [];
  final e = expiry?.toLocal();
  final expiryEve = e == null ? null : DateTime(e.year, e.month, e.day - 1, 10);
  final out = <ReminderCandidate>[];
  for (var d = 0; d < days; d++) {
    final at = DateTime(now.year, now.month, now.day + d, 10);
    if (at.weekday != day || at == expiryEve) continue;
    if (lastBackup != null &&
        at.difference(lastBackup) <= const Duration(days: 6)) {
      continue;
    }
    out.add(
      ReminderCandidate(
        key: 'backup@${at.toIso8601String()}',
        at: at,
        kind: ReminderKind.backup,
        title: l10n.reminderBackupTitle,
        body: l10n.reminderBackupBody,
      ),
    );
  }
  return out;
}

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
