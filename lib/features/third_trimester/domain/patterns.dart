/// Her own patterns from the kick counter and contraction timer. Averages
/// only: nothing here says whether something is fine or urgent (Plan §5.3).
library;

import 'package:navmaas/core/db/app_database.dart';

/// The two-hour window (start hour, 0, 2, … 22) with the most movements per
/// minute, once there are at least three sessions; null before that.
int? mostActiveWindow(List<KickSession> sessions) {
  if (sessions.length < 3) return null;
  final kicks = <int, int>{};
  final minutes = <int, double>{};
  for (final s in sessions) {
    final window = s.startedAt.toLocal().hour ~/ 2 * 2;
    final length = s.endedAt.difference(s.startedAt).inSeconds / 60;
    kicks[window] = (kicks[window] ?? 0) + s.count;
    // A single tap has no length; count it as one minute.
    minutes[window] = (minutes[window] ?? 0) + (length < 1 ? 1 : length);
  }
  int? best;
  for (final w in kicks.keys) {
    if (best == null ||
        kicks[w]! / minutes[w]! > kicks[best]! / minutes[best]!) {
      best = w;
    }
  }
  return best;
}

/// How many contractions started, their average length, and the average
/// time from one start to the next.
typedef ContractionSummary = ({
  int count,
  Duration? averageLength,
  Duration? averageGap,
});

/// The contraction timer's summary for the hour before [now].
ContractionSummary summariseContractions(
  List<Contraction> newestFirst,
  DateTime now,
) {
  final hour = newestFirst
      .where(
        (c) => !c.startedAt.isBefore(now.subtract(const Duration(hours: 1))),
      )
      .toList();
  if (hour.isEmpty) return (count: 0, averageLength: null, averageGap: null);
  final length =
      hour.fold(
        Duration.zero,
        (sum, c) => sum + c.endedAt.difference(c.startedAt),
      ) ~/
      hour.length;
  Duration? gap;
  if (hour.length > 1) {
    gap =
        hour.first.startedAt.difference(hour.last.startedAt) ~/
        (hour.length - 1);
  }
  return (count: hour.length, averageLength: length, averageGap: gap);
}
