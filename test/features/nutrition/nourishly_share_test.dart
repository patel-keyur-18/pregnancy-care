import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/nutrition/domain/nourishly_share.dart';

Map<String, Object?> _base() => jsonDecode(
  File('test/fixtures/nourishly-share-v1.sample.json').readAsStringSync(),
) as Map<String, Object?>;

NourishlyShare? _parse(Map<String, Object?> json) =>
    parseNourishlyShare(jsonEncode(json));

void main() {
  test('reads the shared sample', () {
    final share = _parse(_base())!;
    expect(share.generatedAt, DateTime(2026, 10, 10, 9, 40));
    expect(share.days.map((d) => d.date), [
      DateTime.utc(2026, 10, 10),
      DateTime.utc(2026, 10, 9),
    ]);
    final day = share.day(DateTime.utc(2026, 10, 9))!;
    expect(day.meals.map((m) => m.slot), ['Lunch', 'Dinner']);
    expect(day.meals.first.items, [
      (name: 'Dal tadka', amount: '1 katori · 150 g'),
      (name: 'Phulka', amount: '2 × 1 piece · 60 g'),
    ]);
    expect(day.totals['folate'], 180);
    expect(day.partial, {'folate'});
    expect(
      share.day(DateTime.utc(2026, 10, 10))!.totals.containsKey('folate'),
      isFalse,
    );
    expect(share.day(DateTime.utc(2026, 10, 8)), isNull);
  });

  test('any ISO-8601 precision; shown as written, never converted', () {
    for (final at in [
      '2026-10-10T09:40+05:30',
      '2026-10-10T09:40:00Z',
      '2026-10-10T09:40:00.123456+05:30',
    ]) {
      expect(
        _parse(_base()..['generatedAt'] = at)!.generatedAt,
        DateTime(2026, 10, 10, 9, 40),
        reason: at,
      );
    }
    expect(_parse(_base()..['generatedAt'] = 'yesterday'), isNull);
  });

  test('310.0 and 310 are the same number', () {
    final json = _base();
    ((json['days']! as List)[1] as Map)['totals'] = {'calcium': 310.0};
    expect(_parse(json)!.days[1].totals['calcium'], 310);
    expect(formatNutrient(310.0), '310');
    expect(formatNutrient(1120), '1,120');
    expect(formatNutrient(4.6), '4.6');
  });

  test("anything it can't read is null", () {
    expect(parseNourishlyShare('{'), isNull);
    expect(parseNourishlyShare('[]'), isNull);
    expect(_parse(_base()..['format'] = 'other'), isNull);
    expect(_parse(_base()..['version'] = 2), isNull);
    expect(_parse(_base()..remove('version')), isNull);
    expect(_parse(_base()..remove('days')), isNull);
    final noDate = _base();
    ((noDate['days']! as List)[0] as Map).remove('date');
    expect(_parse(noDate), isNull);
    final noName = _base();
    final meal =
        (((noName['days']! as List)[0] as Map)['meals'] as List)[0] as Map;
    ((meal['items'] as List)[0] as Map).remove('name');
    expect(_parse(noName), isNull);
    final text = _base();
    ((text['days']! as List)[0] as Map)['totals'] = {'energy': '245'};
    expect(_parse(text), isNull);
  });

  test('unknown fields and nutrients are ignored; partial only for totals', () {
    final json = _base()..['extra'] = true;
    final day = (json['days']! as List)[1] as Map;
    day['water'] = 2;
    (day['totals'] as Map)['sodium'] = 900;
    day['partial'] = ['folate', 'iron', 'sodium'];
    (day['totals'] as Map).remove('iron');
    final read = _parse(json)!.days[1];
    expect(read.totals.keys, isNot(contains('sodium')));
    expect(read.partial, {'folate'});
  });

  test('totals and partial may be missing', () {
    final json = _base();
    ((json['days']! as List)[0] as Map)
      ..remove('totals')
      ..remove('partial');
    final day = _parse(json)!.days[0];
    expect(day.totals, isEmpty);
    expect(day.partial, isEmpty);
  });
}
