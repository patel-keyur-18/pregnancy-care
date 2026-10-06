import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/features/home_widget/domain/widget_snapshot.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final pack = ContentPack.fromJson(
    File('assets/content/weeks.json').readAsStringSync(),
  );
  final today = DateTime.utc(2026, 10, 5);
  final now = DateTime(2026, 10, 5, 9);
  // 24 weeks 3 days on 5 Oct.
  final start = DateTime.utc(2026, 4, 17);

  PlannedReminder at(int id, DateTime at) => PlannedReminder(
    id: id,
    at: at,
    kind: ReminderKind.supplement,
    items: [
      ReminderCandidate(
        key: 'k$id',
        at: at,
        kind: ReminderKind.supplement,
        title: 'Folic acid',
        body: '',
      ),
    ],
  );
  final planned = [
    at(1, DateTime(2026, 10, 5, 8)), // already past
    at(2, DateTime(2026, 10, 5, 20)),
    at(3, DateTime(2026, 10, 6, 8)),
  ];
  final titles = ['Iron', 'Folic acid', 'Calcium'];

  Map<String, dynamic> snapshot({DateTime? start, bool hidden = false}) =>
      jsonDecode(
        widgetSnapshot(
          today: today,
          now: now,
          start: start,
          pack: pack,
          planned: planned,
          titles: titles,
          hidden: hidden,
          l10n: l10n,
        ),
      ) as Map<String, dynamic>;

  test('details: a day per entry and the reminders still ahead', () {
    final s = snapshot(start: start);
    expect((s['stopped'], s['hidden']), (false, false));
    final days = (s['days'] as List).cast<Map<String, dynamic>>();
    expect(days, hasLength(widgetDays));
    expect(days.first, {
      'date': '2026-10-05',
      'week': 'Week 24',
      'weekDay': 'Week 24 · day 3',
      'daySize': 'Day 3 · ${pack[24]!.size}',
      'size': 'Baby is about the size of ${pack[24]!.size}',
    });
    expect(days[4]['week'], 'Week 25', reason: 'a new week on 9 Oct');
    final next = (s['next'] as List).cast<Map<String, dynamic>>();
    expect(next.map((n) => n['title']), ['Folic acid', 'Calcium']);
    expect(next.first, {
      'at': DateTime(2026, 10, 5, 20).millisecondsSinceEpoch,
      'date': '2026-10-05',
      'weekday': 'Mon',
      'time': '8:00 pm',
      'title': 'Folic acid',
    });
    expect((s['labels'] as Map)['tomorrow'], 'Tomorrow');
  });

  test('hidden: no week, size, baby or reminder text, only times', () {
    final s = snapshot(start: start, hidden: true);
    // Every text the widget could show.
    Iterable<String> texts(Object? v) => switch (v) {
      final String t => [t],
      final Map<dynamic, dynamic> m => m.values.expand(texts),
      final List<dynamic> l => l.expand(texts),
      _ => const [],
    };
    final raw = texts(s).join('\n');
    expect(s['days'], isEmpty);
    expect((s['next'] as List).map((n) => (n as Map)['time']), [
      '8:00 pm',
      '8:00 am',
    ]);
    for (final text in [
      'Week',
      'week',
      'Day ',
      'size',
      'Baby',
      'baby',
      pack[24]!.size,
      'Folic',
      'Calcium',
    ]) {
      expect(raw, isNot(contains(text)), reason: text);
    }
  });

  test('tracking stopped: only the brand mark', () {
    final s = snapshot();
    expect(s['stopped'], isTrue);
    expect(s['days'], isEmpty);
    expect(s['next'], isEmpty);
  });

  test('dates that need review leave the day out', () {
    final s = snapshot(start: DateTime.utc(2027));
    expect(s['days'], isEmpty);
  });

  test('Android redraws after each reminder ahead and at each midnight', () {
    final times = widgetUpdateTimes(now: now, planned: planned);
    expect(times.take(2), [
      DateTime(2026, 10, 5, 20, 0, 1),
      DateTime(2026, 10, 6, 8, 0, 1),
    ]);
    expect(times.skip(2).first, DateTime(2026, 10, 6, 0, 0, 1));
    expect(times, hasLength(2 + widgetDays));
  });
}
