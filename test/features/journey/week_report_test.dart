import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/journey/domain/week_report.dart';

final _at = DateTime(2026, 10, 5);

Session _session(SessionType type, DateTime startedAt, int minutes) => Session(
  id: '${type.name}$startedAt',
  createdAt: _at,
  updatedAt: _at,
  pregnancyId: 'p',
  type: type,
  startedAt: startedAt,
  durationSec: minutes * 60,
);

MoodEntry _mood(DateTime day, MoodWord mood) => MoodEntry(
  id: '$day',
  createdAt: _at,
  updatedAt: _at,
  pregnancyId: 'p',
  day: day,
  mood: mood,
);

WaterLog _water(DateTime day, int glasses) => WaterLog(
  id: '$day',
  createdAt: _at,
  updatedAt: _at,
  pregnancyId: 'p',
  day: day,
  glasses: glasses,
);

SleepLog _sleep(DateTime day, int hours) => SleepLog(
  id: '$day',
  createdAt: _at,
  updatedAt: _at,
  pregnancyId: 'p',
  day: day,
  bedAt: DateTime(day.year, day.month, day.day - 1, 22),
  wokeAt: DateTime(day.year, day.month, day.day - 1, 22 + hours),
  napMinutes: 0,
);

DateTime _d(int day) => DateTime.utc(2026, 9, day);

void main() {
  // Dating start 15 Apr 2026: week 21 is 9–15 Sep; 5 Oct is in week 24.
  final start = DateTime.utc(2026, 4, 15);
  final today = DateTime.utc(2026, 10, 5);

  test('a week is seven days; the current one stops today; later none', () {
    expect(weekDays(start, 21, today), [for (var d = 9; d <= 15; d++) _d(d)]);
    expect(weekDays(start, 24, today), [
      _d(30),
      for (var d = 1; d <= 5; d++) DateTime.utc(2026, 10, d),
    ]);
    expect(weekDays(start, 25, today), isEmpty);
  });

  final days = weekDays(start, 21, today);

  test('nothing logged: empty', () {
    final r = weekReport(
      days: days,
      sessions: const [],
      plans: const [],
      takenKeys: const {},
    );
    expect(r.isEmpty, isTrue);
    expect(r.steps, isNull);
  });

  test('sessions in the week only, by type, in whole minutes', () {
    final r = weekReport(
      days: days,
      sessions: [
        _session(.walk, DateTime(2026, 9, 9, 7), 20),
        _session(.walk, DateTime(2026, 9, 9, 18), 25),
        _session(.walk, DateTime(2026, 9, 12, 7), 20),
        _session(.walk, DateTime(2026, 9, 16, 7), 20), // next week
        _session(.exercise, DateTime(2026, 9, 10, 8), 15),
        _session(.exercise, DateTime(2026, 9, 11, 8), 15),
        _session(.reading, DateTime(2026, 9, 10, 21), 15),
        _session(.listening, DateTime(2026, 9, 10, 21), 40),
        _session(.meditation, DateTime(2026, 9, 13, 6), 10),
        _session(.breathing, DateTime(2026, 9, 13, 6), 5),
      ],
      plans: const [],
      takenKeys: const {},
    );
    expect(
      (r.walkDays, r.walkMinutes, r.exerciseSessions, r.exerciseMinutes),
      (2, 65, 2, 30),
    );
    expect(
      (
        r.readingMinutes,
        r.listeningMinutes,
        r.meditationMinutes,
        r.breathingMinutes,
      ),
      (15, 40, 10, 5),
    );
    expect(r.isEmpty, isFalse);
  });

  test('a day at the step goal counts as walked; steps add up', () {
    final r = weekReport(
      days: days,
      sessions: [_session(.walk, DateTime(2026, 9, 9, 7), 20)],
      plans: const [],
      takenKeys: const {},
      steps: [6000, 5999, null, 8000, 0, 0, 0],
    );
    // 9 Sep by walk and steps, 12 Sep by steps.
    expect((r.walkDays, r.steps), (2, 19999));
  });

  test('water and sleep average over the days logged; moods counted', () {
    final r = weekReport(
      days: days,
      sessions: const [],
      plans: const [],
      takenKeys: const {},
      water: [_water(_d(9), 6), _water(_d(10), 9), _water(_d(11), 0)],
      sleeps: [_sleep(_d(9), 7), _sleep(_d(10), 8), _sleep(_d(20), 3)],
      moods: [
        _mood(_d(9), .tired),
        _mood(_d(10), .calm),
        _mood(_d(11), .tired),
        _mood(_d(12), .happy),
        _mood(_d(16), .low), // next week
      ],
    );
    expect(r.waterAverage, 8, reason: '7.5 rounds up; 0 glasses is no log');
    expect(r.sleepAverage, 450);
    expect(r.moods, [
      (MoodWord.tired, 2),
      (MoodWord.calm, 1),
      (MoodWord.happy, 1),
    ]);
  });
}
