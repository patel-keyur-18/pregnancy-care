import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

String _time(DateTime t) => formatMinuteOfDay(t.hour * 60 + t.minute);

/// Visits: the evening before (7 pm) and 2 hours before. The next visit's
/// reminder mentions the questions waiting for it.
List<ReminderCandidate> visitCandidates({
  required DateTime now,
  required List<Appointment> appointments,
  required int questionsWaiting,
  required AppLocalizations l10n,
}) {
  final upcoming = appointments.where((a) => a.at.isAfter(now)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final (i, a) in upcoming.indexed) ...[
      ReminderCandidate(
        key: 'visit-eve:${a.id}@${a.at.toIso8601String()}',
        at: DateTime(a.at.year, a.at.month, a.at.day - 1, 19),
        kind: ReminderKind.appointment,
        title: l10n.reminderVisitTomorrow(_time(a.at)),
        body: l10n.reminderVisitBody(i == 0 ? questionsWaiting : 0),
      ),
      ReminderCandidate(
        key: 'visit-soon:${a.id}@${a.at.toIso8601String()}',
        at: a.at.subtract(const Duration(hours: 2)),
        kind: ReminderKind.appointment,
        title: l10n.reminderVisitSoon(_time(a.at)),
        body: [a.doctor, a.place].nonNulls.join(' · '),
      ),
    ],
  ];
}

/// Care items: the evening before a booked one; a gentle note at 10:00 when
/// an unbooked one's week window opens.
List<ReminderCandidate> careCandidates({
  required DateTime now,
  required List<CareItem> items,
  required DateTime pregnancyStart,
  required AppLocalizations l10n,
}) {
  final start = localDay(pregnancyStart);
  final out = <ReminderCandidate>[];
  for (final item in items) {
    if (item.doneAt != null) continue;
    final at = item.scheduledAt;
    if (at != null) {
      if (at.isAfter(now)) {
        out.add(
          ReminderCandidate(
            key: 'care-eve:${item.id}@${at.toIso8601String()}',
            at: DateTime(at.year, at.month, at.day - 1, 19),
            kind: ReminderKind.careItem,
            title: l10n.reminderCareTomorrow(item.title, _time(at)),
            body: item.notes ?? '',
          ),
        );
      }
      continue;
    }
    out.add(
      ReminderCandidate(
        key: 'care-window:${item.id}',
        at: DateTime(
          start.year,
          start.month,
          start.day + item.fromWeek * 7,
          10,
        ),
        kind: ReminderKind.careItem,
        title: l10n.reminderCareWindow(item.title, item.fromWeek, item.toWeek),
        body: l10n.reminderCareWindowBody,
      ),
    );
  }
  return out;
}
