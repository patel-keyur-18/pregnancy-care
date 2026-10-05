import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';

import '../../../tool/weeks_md.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = File('assets/content/weeks.json').readAsStringSync();
  final pack = ContentPack.fromJson(source);
  final weeks = [
    for (var w = ContentPack.firstWeek; w <= ContentPack.lastWeek; w++) w,
  ];

  test('loads from the app bundle', () async {
    final bundled = ContentPack.fromJson(
      await rootBundle.loadString('assets/content/weeks.json'),
    );
    expect(bundled[24]!.size, 'a bhutta (corn cob)');
  });

  test('every week 4–42 has a size, notes and at least one checklist item', () {
    expect(pack[3], isNull);
    expect(pack[43], isNull);
    for (final w in weeks) {
      final c = pack[w];
      expect(c, isNotNull, reason: 'week $w');
      expect(c!.week, w);
      for (final text in [
        c.size,
        c.baby,
        c.you,
        ...c.checklist.map((i) => i.text),
      ]) {
        expect(text.trim(), isNotEmpty, reason: 'week $w');
        expect(text, text.trim(), reason: 'week $w has stray spaces');
      }
      expect(c.checklist, isNotEmpty, reason: 'week $w');
    }
  });

  test('checklist keys are unique and stable-looking', () {
    final keys = [
      for (final w in weeks) ...pack[w]!.checklist.map((i) => i.key),
    ];
    expect(keys.toSet(), hasLength(keys.length));
    for (final k in keys) {
      expect(k, matches(RegExp(r'^w\d\d-[a-z0-9-]+$')));
    }
  });

  // PLAN §5.5 hard lines: no doses, no sex prediction, no outcome claims, no
  // emergency or danger-sign content.
  test('hard lines: no forbidden words', () {
    final forbidden = RegExp(
      r'\b(mg|mcg|ml|iu|dose|doses|dosage|tablets?|capsules?|boy|girl|gender|sex|iq|smarter|intelligen\w*|guarantee\w*|emergency|danger\w*|sos)\b',
      caseSensitive: false,
    );
    expect(forbidden.allMatches(source).map((m) => m[0]).toList(), isEmpty);
  });

  test('unsupported schemaVersion is rejected', () {
    expect(
      () => ContentPack.fromJson('{"schemaVersion": 2, "weeks": []}'),
      throwsFormatException,
    );
  });

  test('docs/content/weeks.md matches weeks.json', () {
    expect(
      File('docs/content/weeks.md').readAsStringSync(),
      renderWeeksMarkdown(source),
      reason: 'run: dart run tool/weeks_md.dart',
    );
  });
}
