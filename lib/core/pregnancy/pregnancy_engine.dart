/// Pregnancy dating (ARCHITECTURE §6). Pure Dart: no Flutter imports.
library;

import 'dart:math' as math;

import 'package:navmaas/core/utils/date_only.dart';

enum DatingMethod { lmp, conception, ivf, scan }

const pregnancyLengthDays = 280;
const minCycleLength = 21;
const maxCycleLength = 40;

/// Gestational day 0. [date] is the LMP, conception date, IVF transfer date or
/// scan due date, depending on [method].
DateTime pregnancyStart({
  required DatingMethod method,
  required DateTime date,
  int cycleLength = 28,
  int embryoDay = 5,
}) {
  RangeError.checkValueInInterval(
    cycleLength,
    minCycleLength,
    maxCycleLength,
    'cycleLength',
  );
  if (embryoDay != 3 && embryoDay != 5) {
    throw ArgumentError.value(embryoDay, 'embryoDay', 'must be 3 or 5');
  }
  return addDays(date, switch (method) {
    .lmp => cycleLength - 28,
    .conception => -14,
    .ivf => embryoDay == 3 ? -17 : -19,
    .scan => -pregnancyLengthDays,
  });
}

/// Where a pregnancy stands on a given day.
class PregnancySnapshot {
  /// Gestational age on [today] for a pregnancy that started on [start].
  factory of({required DateTime start, required DateTime today}) {
    final ga = daysBetween(start, today);
    return PregnancySnapshot._(
      gaDays: ga,
      dueDate: addDays(start, pregnancyLengthDays),
      daysLeft: pregnancyLengthDays - ga,
    );
  }

  new _({required this.gaDays, required this.dueDate, required int daysLeft})
    : daysToGo = math.max(0, daysLeft),
      daysPastDue = math.max(0, -daysLeft);

  /// Gestational age in days; can be negative or very large for bad input.
  final int gaDays;
  final DateTime dueDate;
  final int daysToGo;
  final int daysPastDue;

  int get weeks => gaDays ~/ 7;
  int get days => gaDays % 7;

  /// Display month: 24w4d is "Month 6". Capped at 10.
  int get month => math.min(gaDays ~/ 30.44 + 1, 10);

  /// 1 until 13w6d, 2 until 27w6d, then 3.
  int get trimester => gaDays < 98 ? 1 : (gaDays < 196 ? 2 : 3);

  /// Below 0 or above 44 weeks: ask the user to check the dates.
  bool get needsReview => gaDays < 0 || gaDays > 44 * 7;
}

/// Trimester of completed week [week] (same boundaries as the snapshot).
int trimesterOfWeek(int week) => week < 14 ? 1 : (week < 28 ? 2 : 3);

/// Weeks per trimester as shown on Journey: 1–13, 14–27, 28–40.
const trimesterWeeks = {1: (1, 13), 2: (14, 27), 3: (28, 40)};
