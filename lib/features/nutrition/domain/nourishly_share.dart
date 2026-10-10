/// Nourishly's share file, version 1 (spec §6.1; nourishly
/// docs/navmaas-share.md). Pure Dart: values only, nothing interpreted.
library;

import 'dart:convert';

import 'package:intl/intl.dart';

/// The six day totals, in the order shown: energy (kcal), protein (g),
/// iron (mg), calcium (mg), folate (µg), fibre (g).
const nourishlyNutrients = [
  'energy',
  'protein',
  'iron',
  'calcium',
  'folate',
  'fibre',
];

typedef NourishlyItem = ({String name, String amount});

class NourishlyMeal {
  const new({required this.slot, required this.items});

  final String slot;
  final List<NourishlyItem> items;
}

class NourishlyDay {
  const new({
    required this.date,
    required this.meals,
    required this.totals,
    required this.partial,
  });

  /// UTC midnight, as `dateOnly`.
  final DateTime date;
  final List<NourishlyMeal> meals;

  /// Only nutrients Nourishly had data for; never a made-up zero.
  final Map<String, num> totals;

  /// Totals where some of the day's foods had no data.
  final Set<String> partial;
}

class NourishlyShare {
  const new({required this.generatedAt, required this.days});

  /// When Nourishly wrote the file: the wall-clock time on her phone as
  /// written, not converted (same phone, and tests read the same everywhere).
  final DateTime generatedAt;

  /// Newest first.
  final List<NourishlyDay> days;

  NourishlyDay? day(DateTime date) =>
      days.where((d) => d.date == date).firstOrNull;
}

final _wallClock = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})');
final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// The file, or null when it can't be read: bad JSON, another format, a
/// newer version, or a known field missing or of the wrong type. Unknown
/// fields are ignored (the contract's compatibility rule).
NourishlyShare? parseNourishlyShare(String text) {
  try {
    final json = jsonDecode(text) as Map<String, Object?>;
    if (json['format'] != 'nourishly-share' || json['version'] != 1) {
      return null;
    }
    final at = json['generatedAt']! as String;
    final m = _wallClock.firstMatch(at);
    if (m == null || DateTime.tryParse(at) == null) return null;
    int g(int i) => int.parse(m[i]!);
    return NourishlyShare(
      generatedAt: DateTime(g(1), g(2), g(3), g(4), g(5)),
      days: [for (final d in json['days']! as List<Object?>) _day(d! as Map)],
    );
  } on Object {
    return null;
  }
}

NourishlyDay _day(Map<Object?, Object?> d) {
  final date = d['date']! as String;
  if (!_date.hasMatch(date)) throw const FormatException('date');
  final parsed = DateTime.parse(date);
  final totals = <String, num>{
    for (final MapEntry(:key, :value)
        in ((d['totals'] as Map?) ?? const {}).entries)
      if (nourishlyNutrients.contains(key)) key! as String: value! as num,
  };
  return NourishlyDay(
    date: DateTime.utc(parsed.year, parsed.month, parsed.day),
    meals: [
      for (final meal in (d['meals']! as List).cast<Map<Object?, Object?>>())
        NourishlyMeal(
          slot: meal['slot']! as String,
          items: [
            for (final i
                in (meal['items']! as List).cast<Map<Object?, Object?>>())
              (name: i['name']! as String, amount: i['amount']! as String),
          ],
        ),
    ],
    totals: totals,
    partial: {
      for (final p in (d['partial'] as List?) ?? const [])
        if (totals.containsKey(p)) p! as String,
    },
  );
}

/// "1,120", "4.6", "310": Nourishly already rounds; trailing ".0" goes.
String formatNutrient(num value) => NumberFormat('#,##0.#').format(value);
