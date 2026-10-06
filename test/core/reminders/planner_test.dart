import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/features/wellbeing/domain/water_reminders.dart';
import 'package:navmaas/l10n/gen/app_localizations_en.dart';

// Monday 5 October 2026, 08:00 local.
final now = DateTime(2026, 10, 5, 8);
const on = ReminderSettings(on: true);

ReminderCandidate c(
  String key,
  DateTime at, {
  ReminderKind kind = ReminderKind.supplement,
}) => ReminderCandidate(
  key: key,
  at: at,
  kind: kind,
  title: key,
  body: '$key body',
);

DateTime t(int day, int hour, [int minute = 0]) =>
    DateTime(2026, 10, day, hour, minute);

List<(DateTime, String, bool)> plan(
  List<ReminderCandidate> candidates, {
  ReminderSettings settings = on,
  int maxPending = 60,
}) => [
  for (final p in planReminders(
    now: now,
    candidates: candidates,
    settings: settings,
    maxPending: maxPending,
  ))
    (p.at, p.keys.join(','), p.isDigest),
];

void main() {
  test('reminders off: nothing is scheduled', () {
    expect(
      plan([c('a', t(5, 9))], settings: const ReminderSettings()),
      isEmpty,
    );
  });

  test('only the next 7 days, nothing in the past', () {
    // 23:00 on the 11th is quiet, so it moves to 7:00 on the 12th, still
    // inside the window that ends at 8:00 on the 12th.
    expect(plan([c('past', t(5, 7)), c('in', t(11, 23)), c('out', t(12, 8))]), [
      (t(12, 7), 'in', false),
    ]);
  });

  group('quiet hours (9:30 pm – 7:00 am)', () {
    test('reminders move to the end of quiet hours', () {
      expect(plan([c('late', t(5, 22)), c('early', t(6, 5))]), [
        (t(6, 7), 'early,late', false),
      ]);
    });
    test('session nudges inside quiet hours are dropped', () {
      expect(plan([c('nudge', t(5, 23), kind: ReminderKind.nudge)]), isEmpty);
    });
  });

  test('reminders within 30 minutes are bundled at the first time', () {
    expect(plan([c('a', t(5, 9)), c('b', t(5, 9, 30)), c('c', t(5, 9, 31))]), [
      (t(5, 9), 'a,b', false),
      (t(5, 9, 31), 'c', false),
    ]);
  });

  group('daily limit', () {
    final four = [
      c('s1', t(6, 9)),
      c('s2', t(6, 11)),
      c('s3', t(6, 13)),
      c('s4', t(6, 15)),
      c('visit', t(6, 17), kind: ReminderKind.appointment),
    ];
    test(
      'over the limit: priority wins, the rest fold into a morning digest',
      () {
        expect(plan(four), [
          (t(6, 7), 's3,s4', true),
          (t(6, 9), 's1', false),
          (t(6, 11), 's2', false),
          (t(6, 17), 'visit', false),
        ]);
      },
    );
    test('within the limit: no digest', () {
      expect(plan(four.take(4).toList()).where((p) => p.$3), isEmpty);
    });
    test("today's digest is skipped once its morning time has passed", () {
      final today = [for (var h = 9; h < 19; h += 2) c('t$h', t(5, h))];
      final planned = plan(today);
      expect(planned.where((p) => p.$3), isEmpty);
      expect(planned, hasLength(3));
    });
  });

  test('ids are stable across runs and change when the time changes', () {
    int id(DateTime at) => planReminders(
      now: now,
      candidates: [c('a', at)],
      settings: on,
    ).single.id;
    expect(id(t(5, 9)), id(t(5, 9)));
    expect(id(t(5, 9)), isNot(id(t(5, 10))));
    expect(id(t(5, 9)), inInclusiveRange(1, 0x7fffffff));
  });

  test('never more than the iOS-safe cap, earliest kept', () {
    final many = [
      for (var d = 5; d < 12; d++)
        for (var h = 8; h < 20; h += 1) c('x$d-$h', t(d, h)),
    ];
    final planned = plan(
      many,
      settings: const ReminderSettings(on: true, dailyLimit: 8),
      maxPending: 20,
    );
    expect(planned, hasLength(20));
    expect(planned.first.$1, t(5, 8));
  });

  group('Screen Rest', () {
    test('a meal window (1:00–1:45 pm) holds reminders until it ends', () {
      expect(plan([c('calcium', t(5, 13, 10))]), [
        (t(5, 13, 45), 'calcium', false),
      ]);
    });
    test('its own notice is not held; other nudges in it are dropped', () {
      expect(
        plan([
          c('${mealKeyPrefix}x', t(5, 13), kind: ReminderKind.nudge),
          c('walk', t(5, 13, 20), kind: ReminderKind.nudge),
        ]),
        [(t(5, 13), '${mealKeyPrefix}x', false)],
      );
    });
    test('meal times off: nothing is held', () {
      expect(
        plan([
          c('calcium', t(5, 13, 10)),
        ], settings: const ReminderSettings(on: true, mealOn: false)),
        [(t(5, 13, 10), 'calcium', false)],
      );
    });
    test('bedtime rest off: no quiet hours', () {
      expect(
        plan([
          c('late', t(5, 22)),
        ], settings: const ReminderSettings(on: true, quietOn: false)),
        [(t(5, 22), 'late', false)],
      );
    });
    test('a meal window ending in quiet hours waits for the morning', () {
      expect(
        plan(
          [c('late', t(5, 21, 40))],
          settings: const ReminderSettings(on: true, mealDinner: 21 * 60 + 30),
        ),
        [(t(6, 7), 'late', false)],
      );
    });
  });

  group('the digest and nudges', () {
    ReminderCandidate nudge(String key, DateTime at) =>
        c(key, at, kind: ReminderKind.nudge);
    test('only nudges over the limit: no digest, the extra nudge drops', () {
      expect(
        plan([
          c('s1', t(6, 9)),
          c('s2', t(6, 11)),
          c('s3', t(6, 15)),
          nudge('n1', t(6, 17)),
          nudge('n2', t(6, 19)),
        ]),
        [
          (t(6, 9), 's1', false),
          (t(6, 11), 's2', false),
          (t(6, 15), 's3', false),
          (t(6, 17), 'n1', false),
        ],
      );
    });
    test('nudges never wait for the morning digest', () {
      expect(
        plan([
          for (var h = 9; h < 19; h += 2) c('s$h', t(6, h)),
          nudge('wind', t(6, 21)),
        ]),
        [
          (t(6, 7), 's15,s17', true),
          (t(6, 9), 's9', false),
          (t(6, 11), 's11', false),
          (t(6, 13, 45), 's13', false),
        ],
      );
    });
  });

  group('water reminders (Plan decision 41)', () {
    const water = ReminderSettings(on: true, waterOn: true);
    List<ReminderCandidate> nudges({
      ReminderSettings settings = water,
      bool goalReached = false,
    }) => waterCandidates(
      now: now,
      settings: settings,
      goalReached: goalReached,
      l10n: AppLocalizationsEn(),
      days: 2,
    );
    List<DateTime> times(List<(DateTime, String, bool)> p) => [
      for (final (at, _, _) in p) at,
    ];

    test('off by default: none', () {
      expect(nudges(settings: on), isEmpty);
    });

    test('every 2 hours in the day; quiet hours and meal times drop them', () {
      final today = plan(
        nudges(),
        settings: const ReminderSettings(
          on: true,
          waterOn: true,
          dailyLimit: 8,
        ),
      ).where((p) => p.$1.day == 5);
      // 9, 11, 13 (lunch: dropped), 15, 17, 19, 21 (quiet from 9:30 pm: the
      // 9 pm one stays) ; 20:00 dinner never lands on a 2-hour step.
      expect(times(today.toList()), [
        t(5, 9),
        t(5, 11),
        t(5, 15),
        t(5, 17),
        t(5, 19),
        t(5, 21),
      ]);
      expect(today.every((p) => p.$2.startsWith(waterKeyPrefix)), isTrue);
    });

    test('every 3 hours: 10, 1 (held by lunch, dropped), 4, 7', () {
      final today = plan(
        nudges(
          settings: const ReminderSettings(
            on: true,
            waterOn: true,
            waterEvery: 3,
          ),
        ),
      ).where((p) => p.$1.day == 5);
      expect(times(today.toList()), [t(5, 10), t(5, 16), t(5, 19)]);
    });

    test('nothing in quiet hours, even when they are moved', () {
      final all = nudges(
        settings: const ReminderSettings(
          on: true,
          waterOn: true,
          quietStart: 18 * 60,
          quietEnd: 9 * 60,
          dailyLimit: 8,
        ),
      );
      final today = plan(
        all,
        settings: const ReminderSettings(
          on: true,
          waterOn: true,
          quietStart: 18 * 60,
          quietEnd: 9 * 60,
          dailyLimit: 8,
        ),
      ).where((p) => p.$1.day == 5);
      expect(times(today.toList()), [t(5, 11), t(5, 15), t(5, 17)]);
    });

    test('they give way under the daily limit and never join the digest', () {
      final p = plan([
        c('s1', t(6, 8, 30)),
        c('s2', t(6, 12)),
        c('s3', t(6, 14, 30)),
        c('s4', t(6, 18, 30)),
        c('s5', t(6, 20, 50)),
        ...nudges(),
      ]).where((p) => p.$1.day == 6).toList();
      // Within 30 minutes a nudge rides along with a supplement (bundling);
      // on its own over the limit it drops, and the digest has none.
      final digest = p.where((p) => p.$3).single;
      expect(digest.$2.contains(waterKeyPrefix), isFalse);
      expect(
        p.where(
          (p) =>
              !p.$3 &&
              p.$2.split(',').every((k) => k.startsWith(waterKeyPrefix)),
        ),
        isEmpty,
        reason: 'no water-only notification over the limit',
      );
    });

    test("once today's goal is reached, today's stop; tomorrow's stay", () {
      final p = nudges(goalReached: true);
      expect(p.where((c) => c.at.day == 5), isEmpty);
      expect(p.where((c) => c.at.day == 6), isNotEmpty);
      expect(p.first.title, 'Water');
    });
  });
}
