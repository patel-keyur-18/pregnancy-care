import 'package:navmaas/core/db/app_database.dart';

/// A supplement with its live schedules.
typedef SupplementPlan = ({
  Supplement supplement,
  List<SupplementSchedule> schedules,
});

/// One scheduled dose on one day.
class DoseSlot {
  const new({
    required this.supplement,
    required this.schedule,
    required this.dueAt,
  });

  final Supplement supplement;
  final SupplementSchedule schedule;

  /// Local date and time of the dose.
  final DateTime dueAt;

  /// Identifies the slot in notification payloads.
  String get key => '${schedule.id}@${dueAt.toIso8601String()}';
}

/// Doses due on local calendar [day] (time of day ignored), earliest first.
/// A supplement only has doses from the day it was added.
List<DoseSlot> slotsOn(DateTime day, Iterable<SupplementPlan> plans) {
  final date = DateTime(day.year, day.month, day.day);
  final bit = 1 << (date.weekday - 1);
  return [
    for (final p in plans)
      if (!_dateOf(p.supplement.createdAt).isAfter(date))
        for (final s in p.schedules)
          if (s.weekdayMask & bit != 0)
            DoseSlot(
              supplement: p.supplement,
              schedule: s,
              // Built from parts so a DST change never shifts the time.
              dueAt: DateTime(
                date.year,
                date.month,
                date.day,
                s.minuteOfDay ~/ 60,
                s.minuteOfDay % 60,
              ),
            ),
  ]..sort((a, b) {
    final t = a.dueAt.compareTo(b.dueAt);
    return t != 0 ? t : a.supplement.name.compareTo(b.supplement.name);
  });
}

/// Doses due and taken on each of [days].
List<({DateTime day, int due, int taken})> adherence(
  Iterable<DateTime> days,
  Iterable<SupplementPlan> plans,
  Set<String> takenKeys,
) => [
  for (final day in days)
    () {
      final slots = slotsOn(day, plans);
      return (
        day: day,
        due: slots.length,
        taken: slots.where((s) => takenKeys.contains(s.key)).length,
      );
    }(),
];

DateTime _dateOf(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}
