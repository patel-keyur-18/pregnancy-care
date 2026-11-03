import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/platform/health.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/journey/domain/week_report.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'week_report_data.g.dart';

/// Each day's steps from [from] (a date) for [days] days, the last one up to
/// now; nulls without Health access (never asks for it).
@riverpod
Future<List<int?>> weekSteps(Ref ref, DateTime from, int days) async {
  final source = ref.watch(stepSourceProvider);
  final now = clockNow();
  return [
    for (var i = 0; i < days; i++)
      await source.steps(
        DateTime(from.year, from.month, from.day + i),
        switch (DateTime(from.year, from.month, from.day + i + 1)) {
          final end when end.isAfter(now) => now,
          final end => end,
        },
      ),
  ];
}

@riverpod
Stream<List<MoodEntry>> _moodsFrom(
  Ref ref,
  String pregnancyId,
  DateTime from,
) => ref.watch(wellbeingRepositoryProvider).watchMoods(pregnancyId, from);

@riverpod
Stream<List<SleepLog>> _sleepFrom(Ref ref, String pregnancyId, DateTime from) =>
    ref.watch(wellbeingRepositoryProvider).watchSleep(pregnancyId, from);

@riverpod
Stream<List<WaterLog>> _waterFrom(Ref ref, String pregnancyId, DateTime from) =>
    ref.watch(wellbeingRepositoryProvider).watchWater(pregnancyId, from);

/// "Your week" for pregnancy week [week] of the active pregnancy (E7), or
/// null for a week still to come.
@riverpod
WeekReport? weekReportOf(Ref ref, int week) {
  final pregnancy = ref.watch(activePregnancyProvider).value;
  if (pregnancy == null) return null;
  final days = weekDays(pregnancy.startDate, week, ref.watch(todayProvider));
  if (days.isEmpty) return null;
  final first = days.first;
  final from = localDay(first);
  final to = DateTime(days.last.year, days.last.month, days.last.day + 1);
  return weekReport(
    days: days,
    sessions: ref.watch(sessionsBetweenProvider(from, to)).value ?? const [],
    plans: ref.watch(supplementPlansProvider).value ?? const [],
    takenKeys: ref.watch(takenDosesProvider(from, to)).value ?? const {},
    moods: ref.watch(_moodsFromProvider(pregnancy.id, first)).value ?? const [],
    sleeps:
        ref.watch(_sleepFromProvider(pregnancy.id, first)).value ?? const [],
    water: ref.watch(_waterFromProvider(pregnancy.id, first)).value ?? const [],
    steps: ref.watch(weekStepsProvider(first, days.length)).value ?? const [],
    stepGoal: ref.watch(stepGoalProvider).value ?? defaultStepGoal,
  );
}
