import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';

import '../../../tool/content_md.dart';

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
      reason: 'run: dart run tool/content_md.dart',
    );
  });

  group('India care template', () {
    final careSource = File('assets/content/care_template_in.json')
        .readAsStringSync();
    final items = parseCareTemplate(careSource);

    test('keys unique, windows inside weeks 4–42, text present', () {
      expect(items.map((i) => i.key).toSet(), hasLength(items.length));
      for (final i in items) {
        expect(i.fromWeek, inInclusiveRange(4, i.toWeek), reason: i.key);
        expect(i.toWeek, lessThanOrEqualTo(42), reason: i.key);
        expect(i.title.trim(), isNotEmpty);
        expect(i.note.trim(), isNotEmpty);
      }
    });

    test('hard lines: no forbidden words', () {
      final forbidden = RegExp(
        r'\b(mg|mcg|ml|iu|dose|doses|dosage|tablets?|boy|girl|gender|sex|iq|guarantee\w*|emergency|danger\w*|sos)\b',
        caseSensitive: false,
      );
      expect(forbidden.allMatches(careSource).map((m) => m[0]), isEmpty);
    });

    test('docs/content/care_template.md matches the JSON', () {
      expect(
        File('docs/content/care_template.md').readAsStringSync(),
        renderCareMarkdown(careSource),
        reason: 'run: dart run tool/content_md.dart',
      );
    });
  });

  group('daily activities', () {
    final source = File('assets/content/activities.json').readAsStringSync();
    final items = parseActivities(source);

    test('about a month of unique, filled-in ideas', () {
      expect(items.length, greaterThanOrEqualTo(28));
      expect(items.map((i) => i.key).toSet(), hasLength(items.length));
      for (final i in items) {
        expect(i.title.trim(), isNotEmpty);
        expect(i.text, i.text.trim(), reason: i.key);
      }
    });

    test('hard lines: no forbidden words', () {
      final forbidden = RegExp(
        r'\b(mg|mcg|ml|iu|dose|doses|dosage|tablets?|boy|girl|gender|sex|iq|smarter|intelligen\w*|guarantee\w*|emergency|danger\w*|sos)\b',
        caseSensitive: false,
      );
      expect(forbidden.allMatches(source).map((m) => m[0]), isEmpty);
    });

    test('docs/content/activities.md matches the JSON', () {
      expect(
        File('docs/content/activities.md').readAsStringSync(),
        renderActivitiesMarkdown(source),
        reason: 'run: dart run tool/content_md.dart',
      );
    });
  });
}
