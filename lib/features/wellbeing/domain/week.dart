import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/utils/date_only.dart';

/// What she logged on one day, for the Wellbeing week (no scores, no
/// verdicts: just what she wrote down).
class WellbeingDay {
  const new({
    required this.day,
    this.mood,
    this.symptoms = const [],
    this.sleep,
    this.glasses = 0,
  });

  final DateTime day;
  final MoodEntry? mood;

  /// Oldest first.
  final List<SymptomEntry> symptoms;
  final SleepLog? sleep;
  final int glasses;

  bool get isEmpty =>
      mood == null && symptoms.isEmpty && sleep == null && glasses == 0;
}

/// The 7 days ending [today], today first.
List<WellbeingDay> weekOf(
  DateTime today, {
  Iterable<MoodEntry> moods = const [],
  Iterable<SymptomEntry> symptoms = const [],
  Iterable<SleepLog> sleeps = const [],
  Iterable<WaterLog> water = const [],
}) => [
  for (var i = 0; i < 7; i++)
    () {
      final day = addDays(today, -i);
      final logged =
          symptoms.where((s) => dateOnly(s.loggedAt.toLocal()) == day).toList()
            ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
      return WellbeingDay(
        day: day,
        mood: moods.where((m) => m.day == day).firstOrNull,
        symptoms: logged,
        sleep: sleeps.where((s) => s.day == day).firstOrNull,
        glasses: water.where((w) => w.day == day).firstOrNull?.glasses ?? 0,
      );
    }(),
];

/// Minutes asleep that night plus naps.
int sleepMinutes(SleepLog s) {
  final night = s.wokeAt.difference(s.bedAt).inMinutes;
  return (night < 0 ? 0 : night) + s.napMinutes;
}

/// The average of [sleepMinutes] over the nights logged, or null if none.
int? averageSleepMinutes(Iterable<SleepLog> nights) => nights.isEmpty
    ? null
    : (nights.map(sleepMinutes).reduce((a, b) => a + b) / nights.length)
          .round();
