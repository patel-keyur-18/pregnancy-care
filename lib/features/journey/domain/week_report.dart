/// "Your week" in Journey (E7, Plan decision 83): what she logged in one
/// pregnancy week, values only. No scores, streaks or verdicts; a value of
/// zero means its row is hidden. Pure Dart.
library;

import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/wellbeing/domain/week.dart';

/// One week's totals. Minutes are whole minutes of logged sessions.
class WeekReport {
  const new({
    this.dosesDue = 0,
    this.dosesTaken = 0,
    this.walkDays = 0,
    this.walkMinutes = 0,
    this.steps,
    this.exerciseSessions = 0,
    this.exerciseMinutes = 0,
    this.readingMinutes = 0,
    this.listeningMinutes = 0,
    this.meditationMinutes = 0,
    this.breathingMinutes = 0,
    this.waterAverage,
    this.sleepAverage,
    this.moods = const [],
  });

  final int dosesDue;
  final int dosesTaken;

  /// Days with a logged walk or the step goal reached.
  final int walkDays;
  final int walkMinutes;

  /// Steps that week from Health; null without access.
  final int? steps;
  final int exerciseSessions;
  final int exerciseMinutes;
  final int readingMinutes;
  final int listeningMinutes;
  final int meditationMinutes;
  final int breathingMinutes;

  /// Glasses a day over the days she logged water, rounded; null for none.
  final int? waterAverage;

  /// Minutes a night over the nights logged; null for none.
  final int? sleepAverage;

  /// Each mood logged and how often, most often first.
  final List<(MoodWord, int)> moods;

  bool get isEmpty =>
      dosesDue == 0 &&
      walkDays == 0 &&
      walkMinutes == 0 &&
      exerciseSessions == 0 &&
      readingMinutes == 0 &&
      listeningMinutes == 0 &&
      meditationMinutes == 0 &&
      breathingMinutes == 0 &&
      waterAverage == null &&
      sleepAverage == null &&
      moods.isEmpty;
}

/// The report for [days] (dates from [dateOnly], oldest first, up to
/// today). [steps] holds each day's steps in the same order (null where
/// they can't be read); a day at [stepGoal] counts as a day walked.
WeekReport weekReport({
  required List<DateTime> days,
  required Iterable<Session> sessions,
  required Iterable<SupplementPlan> plans,
  required Set<String> takenKeys,
  Iterable<MoodEntry> moods = const [],
  Iterable<SleepLog> sleeps = const [],
  Iterable<WaterLog> water = const [],
  List<int?> steps = const [],
  int stepGoal = 6000,
}) {
  final inWeek = days.toSet();
  final logged = [
    for (final s in sessions)
      if (inWeek.contains(dateOnly(s.startedAt.toLocal()))) s,
  ];
  int minutes(SessionType type) =>
      logged
          .where((s) => s.type == type)
          .fold(0, (n, s) => n + s.durationSec) ~/
      60;
  final doses = adherence(
    [for (final d in days) localDay(d)],
    plans,
    takenKeys,
  );
  final walked = {
    for (final s in logged)
      if (s.type == SessionType.walk) dateOnly(s.startedAt.toLocal()),
    for (final (i, d) in days.indexed)
      if (i < steps.length && (steps[i] ?? 0) >= stepGoal) d,
  };
  final read = steps.whereType<int>();
  final glasses = [
    for (final w in water)
      if (inWeek.contains(w.day) && w.glasses > 0) w.glasses,
  ];
  final counts = <MoodWord, int>{};
  for (final m in moods) {
    if (inWeek.contains(m.day)) counts[m.mood] = (counts[m.mood] ?? 0) + 1;
  }
  return WeekReport(
    dosesDue: doses.fold(0, (n, d) => n + d.due),
    dosesTaken: doses.fold(0, (n, d) => n + d.taken),
    walkDays: walked.length,
    walkMinutes: minutes(SessionType.walk),
    steps: read.isEmpty ? null : read.fold<int>(0, (n, s) => n + s),
    exerciseSessions: logged
        .where((s) => s.type == SessionType.exercise)
        .length,
    exerciseMinutes: minutes(SessionType.exercise),
    readingMinutes: minutes(SessionType.reading),
    listeningMinutes: minutes(SessionType.listening),
    meditationMinutes: minutes(SessionType.meditation),
    breathingMinutes: minutes(SessionType.breathing),
    waterAverage: glasses.isEmpty
        ? null
        : (glasses.reduce((a, b) => a + b) / glasses.length).round(),
    sleepAverage: averageSleepMinutes(
      sleeps.where((s) => inWeek.contains(s.day)),
    ),
    moods:
        [
          for (final m in MoodWord.values)
            if (counts[m] case final n?) (m, n),
        ]..sort(
          (a, b) => b.$2 != a.$2
              ? b.$2.compareTo(a.$2)
              : a.$1.index.compareTo(b.$1.index),
        ),
  );
}

/// The dates of pregnancy week [week] from [start] (the dating start, UTC
/// midnight): seven days, cut at [today] for the current week; empty for a
/// week still to come.
List<DateTime> weekDays(DateTime start, int week, DateTime today) => [
  for (var i = 0; i < 7; i++)
    if (!addDays(start, week * 7 + i).isAfter(today))
      addDays(start, week * 7 + i),
];
