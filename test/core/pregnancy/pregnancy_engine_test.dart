import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/utils/date_only.dart';

// Expected dates were computed independently with Python's `datetime`,
// not with the formulas under test.
DateTime d(String iso) => DateTime.parse('${iso}T00:00:00Z');

void main() {
  group('pregnancyStart + due date', () {
    final cases = <(String, DatingMethod, String, int, int, String, String)>[
      // name, method, date, cycleLength, embryoDay, start, due
      ('LMP 28d', .lmp, '2026-04-15', 28, 5, '2026-04-15', '2027-01-20'),
      (
        'conception',
        .conception,
        '2026-04-29',
        28,
        5,
        '2026-04-15',
        '2027-01-20',
      ),
      ('IVF day-5', .ivf, '2026-05-04', 28, 5, '2026-04-15', '2027-01-20'),
      ('IVF day-3', .ivf, '2026-05-02', 28, 3, '2026-04-15', '2027-01-20'),
      ('scan EDD', .scan, '2027-01-20', 28, 5, '2026-04-15', '2027-01-20'),
      // Leap years.
      ('LMP on 29 Feb', .lmp, '2024-02-29', 28, 5, '2024-02-29', '2024-12-05'),
      ('due on 29 Feb', .lmp, '2023-05-25', 28, 5, '2023-05-25', '2024-02-29'),
      (
        'spans 29 Feb 2028',
        .lmp,
        '2027-06-10',
        28,
        5,
        '2027-06-10',
        '2028-03-16',
      ),
      ('non-leap Feb', .lmp, '2025-05-25', 28, 5, '2025-05-25', '2026-03-01'),
      (
        'LMP 40d over Feb 29',
        .lmp,
        '2024-02-28',
        40,
        5,
        '2024-03-11',
        '2024-12-16',
      ),
      (
        'conception → 29 Feb',
        .conception,
        '2024-03-14',
        28,
        5,
        '2024-02-29',
        '2024-12-05',
      ),
      (
        'IVF day-3 over Feb 29',
        .ivf,
        '2024-03-01',
        28,
        3,
        '2024-02-13',
        '2024-11-19',
      ),
      (
        'scan EDD 29 Feb',
        .scan,
        '2024-02-29',
        28,
        5,
        '2023-05-25',
        '2024-02-29',
      ),
      // Month and year ends.
      (
        'LMP 31 Jan, 30d',
        .lmp,
        '2026-01-31',
        30,
        5,
        '2026-02-02',
        '2026-11-09',
      ),
      (
        'LMP 31 Jan, 21d',
        .lmp,
        '2026-01-31',
        21,
        5,
        '2026-01-24',
        '2026-10-31',
      ),
      ('LMP 31 Dec', .lmp, '2026-12-31', 28, 5, '2026-12-31', '2027-10-07'),
      (
        'conception 1 Mar',
        .conception,
        '2026-03-01',
        28,
        5,
        '2026-02-15',
        '2026-11-22',
      ),
      (
        'IVF day-5 1 Mar',
        .ivf,
        '2026-03-01',
        28,
        5,
        '2026-02-10',
        '2026-11-17',
      ),
      (
        'scan EDD 1 Mar',
        .scan,
        '2027-03-01',
        28,
        5,
        '2026-05-25',
        '2027-03-01',
      ),
    ];

    for (final (name, method, date, cycle, embryo, start, due) in cases) {
      test(name, () {
        final s = pregnancyStart(
          method: method,
          date: d(date),
          cycleLength: cycle,
          embryoDay: embryo,
        );
        expect(s, d(start));
        expect(PregnancySnapshot.of(start: s, today: s).dueDate, d(due));
      });
    }
  });

  group('LMP cycle lengths 21–40', () {
    final cases = <(int, String, String)>[
      (21, '2026-04-08', '2027-01-13'),
      (22, '2026-04-09', '2027-01-14'),
      (23, '2026-04-10', '2027-01-15'),
      (24, '2026-04-11', '2027-01-16'),
      (25, '2026-04-12', '2027-01-17'),
      (26, '2026-04-13', '2027-01-18'),
      (27, '2026-04-14', '2027-01-19'),
      (28, '2026-04-15', '2027-01-20'),
      (29, '2026-04-16', '2027-01-21'),
      (30, '2026-04-17', '2027-01-22'),
      (31, '2026-04-18', '2027-01-23'),
      (32, '2026-04-19', '2027-01-24'),
      (33, '2026-04-20', '2027-01-25'),
      (34, '2026-04-21', '2027-01-26'),
      (35, '2026-04-22', '2027-01-27'),
      (36, '2026-04-23', '2027-01-28'),
      (37, '2026-04-24', '2027-01-29'),
      (38, '2026-04-25', '2027-01-30'),
      (39, '2026-04-26', '2027-01-31'),
      (40, '2026-04-27', '2027-02-01'),
    ];
    for (final (cycle, start, due) in cases) {
      test('$cycle days', () {
        final s = pregnancyStart(
          method: .lmp,
          date: d('2026-04-15'),
          cycleLength: cycle,
        );
        expect(s, d(start));
        expect(PregnancySnapshot.of(start: s, today: s).dueDate, d(due));
      });
    }
  });

  group('snapshot (start 2026-04-15, due 2027-01-20)', () {
    final start = d('2026-04-15');
    final cases = <(String, String, int, int, int, int, int, int, bool)>[
      // name, today, weeks, days, month, trimester, toGo, pastDue, review
      ('day 0', '2026-04-15', 0, 0, 1, 1, 280, 0, false),
      ('ga 30 is month 1', '2026-05-15', 4, 2, 1, 1, 250, 0, false),
      ('ga 31 is month 2', '2026-05-16', 4, 3, 2, 1, 249, 0, false),
      ('13w6d last of T1', '2026-07-21', 13, 6, 4, 1, 183, 0, false),
      ('14w0d first of T2', '2026-07-22', 14, 0, 4, 2, 182, 0, false),
      ('24w5d', '2026-10-05', 24, 5, 6, 2, 107, 0, false),
      ('27w6d last of T2', '2026-10-27', 27, 6, 7, 2, 85, 0, false),
      ('28w0d first of T3', '2026-10-28', 28, 0, 7, 3, 84, 0, false),
      ('due date', '2027-01-20', 40, 0, 10, 3, 0, 0, false),
      ('due + 7', '2027-01-27', 41, 0, 10, 3, 0, 7, false),
      ('month capped at 10', '2027-02-14', 43, 4, 10, 3, 0, 25, false),
      ('44w0d still fine', '2027-02-17', 44, 0, 10, 3, 0, 28, false),
      ('44w1d needs review', '2027-02-18', 44, 1, 10, 3, 0, 29, true),
    ];
    for (final (name, today, w, dd, m, tri, toGo, past, review) in cases) {
      test(name, () {
        final s = PregnancySnapshot.of(start: start, today: d(today));
        expect(
          (
            s.weeks,
            s.days,
            s.month,
            s.trimester,
            s.daysToGo,
            s.daysPastDue,
            s.needsReview,
          ),
          (w, dd, m, tri, toGo, past, review),
        );
      });
    }

    test('before start needs review', () {
      final s = PregnancySnapshot.of(start: start, today: d('2026-04-14'));
      expect(s.gaDays, -1);
      expect(s.needsReview, isTrue);
    });
  });

  group('input checks', () {
    test('cycle length outside 21–40 throws', () {
      for (final c in [20, 41]) {
        expect(
          () => pregnancyStart(
            method: .lmp,
            date: d('2026-01-01'),
            cycleLength: c,
          ),
          throwsRangeError,
        );
      }
    });
    test('embryo day other than 3 or 5 throws', () {
      expect(
        () => pregnancyStart(method: .ivf, date: d('2026-01-01'), embryoDay: 4),
        throwsArgumentError,
      );
    });
  });

  group('date-only maths', () {
    test('dateOnly drops time of day and keeps the calendar date', () {
      expect(dateOnly(DateTime(2026, 3, 29, 23, 59)), d('2026-03-29'));
      expect(dateOnly(DateTime(2026, 3, 29, 0, 1)), d('2026-03-29'));
    });
    test('a 23-hour local gap across DST still counts as one day', () {
      // US and EU clocks jump on these nights; the result must not depend on
      // the device time zone.
      for (final (a, b) in [
        (DateTime(2026, 3, 8, 0, 30), DateTime(2026, 3, 9, 0, 30)),
        (DateTime(2026, 3, 29, 0, 30), DateTime(2026, 3, 30, 0, 30)),
        (DateTime(2026, 11, 1, 0, 30), DateTime(2026, 11, 2, 0, 30)),
      ]) {
        expect(daysBetween(dateOnly(a), dateOnly(b)), 1);
      }
    });
    test('addDays crosses month and year ends', () {
      expect(addDays(d('2026-12-31'), 1), d('2027-01-01'));
      expect(addDays(d('2024-03-01'), -1), d('2024-02-29'));
    });
  });

  test('trimesterOfWeek matches the snapshot boundaries', () {
    for (final (week, tri) in [
      (4, 1),
      (13, 1),
      (14, 2),
      (27, 2),
      (28, 3),
      (42, 3),
    ]) {
      expect(trimesterOfWeek(week), tri, reason: 'week $week');
      final s = PregnancySnapshot.of(
        start: d('2026-01-01'),
        today: addDays(d('2026-01-01'), week * 7),
      );
      expect(s.trimester, tri, reason: 'snapshot week $week');
    }
  });
}
