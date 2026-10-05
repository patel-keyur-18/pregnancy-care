import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Prefix of dose-slot reminder keys; "Taken" acts on these.
const doseKeyPrefix = 'dose:';

/// "1 tablet · after breakfast", or "" when neither is set.
String doseLine(DoseSlot slot) => [
  slot.supplement.doseText,
  slot.schedule.label ?? '',
].where((s) => s.isNotEmpty).join(' · ');

/// Reminders for doses not yet taken over the next [days] days, plus a
/// refill reminder at 10:00 for supplements at or below their refill level.
List<ReminderCandidate> supplementCandidates({
  required DateTime now,
  required List<SupplementPlan> plans,
  required Set<String> takenKeys,
  required AppLocalizations l10n,
  int days = 8,
}) {
  final out = <ReminderCandidate>[];
  for (var d = 0; d < days; d++) {
    for (final slot in slotsOn(
      DateTime(now.year, now.month, now.day + d),
      plans,
    )) {
      if (takenKeys.contains(slot.key)) continue;
      final line = doseLine(slot);
      out.add(
        ReminderCandidate(
          key: '$doseKeyPrefix${slot.key}',
          at: slot.dueAt,
          kind: ReminderKind.supplement,
          title: slot.supplement.name,
          body: line.isEmpty ? l10n.reminderTimeFor : line,
        ),
      );
    }
  }
  for (final p in plans) {
    final s = p.supplement;
    final (stock, refillAt) = (s.stock, s.refillAt);
    if (stock == null || refillAt == null || stock > refillAt) continue;
    final at = DateTime(
      now.year,
      now.month,
      now.day + (now.hour < 10 ? 0 : 1),
      10,
    );
    out.add(
      ReminderCandidate(
        key: 'refill:${s.id}@${at.toIso8601String()}',
        at: at,
        kind: ReminderKind.supplement,
        title: l10n.reminderRefillTitle(s.name),
        body: l10n.reminderRefillBody(stock),
      ),
    );
  }
  return out;
}

/// The schedule id and due time inside a dose reminder key.
({String scheduleId, DateTime dueAt})? parseDoseKey(String key) {
  if (!key.startsWith(doseKeyPrefix)) return null;
  final at = key.lastIndexOf('@');
  if (at < 0) return null;
  final dueAt = DateTime.tryParse(key.substring(at + 1));
  if (dueAt == null) return null;
  return (scheduleId: key.substring(doseKeyPrefix.length, at), dueAt: dueAt);
}
