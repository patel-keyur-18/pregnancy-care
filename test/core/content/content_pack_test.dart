import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/tables.dart';

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

  group('exercise routines', () {
    final source = File('assets/content/routines.json').readAsStringSync();
    final routines = parseRoutines(source);

    test('unique keys, valid trimesters, timed moves', () {
      expect(routines.map((r) => r.key).toSet(), hasLength(routines.length));
      for (final r in routines) {
        expect(r.trimesters, isNotEmpty, reason: r.key);
        expect(r.trimesters.difference({1, 2, 3}), isEmpty, reason: r.key);
        expect(r.moves, isNotEmpty, reason: r.key);
        for (final m in r.moves) {
          expect(m.sec, greaterThan(0), reason: '${r.key}: ${m.name}');
          expect(m.how.trim(), isNotEmpty, reason: '${r.key}: ${m.name}');
        }
      }
    });

    test('every trimester has routines, even when high-risk', () {
      for (final t in [1, 2, 3]) {
        expect(
          routinesFor(routines, trimester: t, highRisk: true),
          isNotEmpty,
          reason: 'trimester $t',
        );
        expect(
          routinesFor(routines, trimester: t, highRisk: false).length,
          greaterThan(
            routinesFor(routines, trimester: t, highRisk: true).length,
          ),
          reason: 'trimester $t: high risk hides the cautious ones',
        );
      }
    });

    test('hard lines: no forbidden words, no lying flat on the back', () {
      final forbidden = RegExp(
        r'\b(mg|mcg|ml|iu|dose|doses|dosage|tablets?|boy|girl|gender|sex|iq|smarter|intelligen\w*|guarantee\w*|emergency|danger\w*|sos|on your back)\b',
        caseSensitive: false,
      );
      expect(forbidden.allMatches(source).map((m) => m[0]), isEmpty);
    });

    test('docs/content/routines.md matches the JSON', () {
      expect(
        File('docs/content/routines.md').readAsStringSync(),
        renderRoutinesMarkdown(source),
        reason: 'run: dart run tool/content_md.dart',
      );
    });
  });

  // Plan decisions 39–43: the symptom pick-list and the mood words are a log,
  // never advice or a warning list, and Wellbeing has no good/bad wording.
  group('wellbeing and vitals words (app_en.arb)', () {
    final arb = (jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
    String cap(String s) => s[0].toUpperCase() + s.substring(1);
    Map<String, String> labels(String prefix) => {
      for (final MapEntry(:key, :value) in arb.entries)
        if (key.startsWith(prefix)) key.substring(prefix.length): value,
    };

    test('every stored key has a word, and every word a key', () {
      for (final (prefix, keys) in [
        ('moodWord', MoodWord.values),
        ('symptomPick', SymptomKind.values),
        ('severity', Severity.values),
        ('restedWord', Rested.values),
      ]) {
        expect(labels(prefix).keys.toSet(), {
          for (final k in keys) cap(k.name),
        }, reason: prefix);
      }
      expect(MoodWord.values, hasLength(5));
      expect(labels('moodWord').values.toSet(), hasLength(5));
    });

    test('every blood-sugar context has a word', () {
      expect(labels('bloodSugarContext').keys.toSet(), {
        for (final c in BloodSugarContext.values) cap(c.name),
      });
    });

    test('hard lines: no advice, warning, verdict or good/bad words', () {
      const prefixes = [
        'wellbeing',
        'mood',
        'symptom',
        'severity',
        'sleep',
        'rested',
        'water',
        'nap',
        'reminderWater',
        'hideForToday',
        'yourWeek',
        'nothingLogged',
        'weekSleep',
        'weekWater',
        'goal',
        'noteOptional',
        'meditation',
        'bloodSugar',
        'nutrition',
        'avoidFood',
      ];
      final text =
          [
                for (final MapEntry(:key, :value) in arb.entries)
                  if (!key.startsWith('@') && prefixes.any(key.startsWith))
                    value,
              ]
              .join('\n')
              // Blood sugar's unit is a measurement, not a dose; "mg" alone
              // stays banned.
              .replaceAll('mg/dL', '');
      expect(text, contains('Heartburn'), reason: 'the words are checked');
      final forbidden = RegExp(
        r'\b(warn\w*|serious|severe|urgent\w*|abnormal|normal|risk\w*|'
        'unsafe|safe|should|must|consult|contact|hospital|sign of|'
        r'symptom of|good|bad|poor|better|worse|score\w*|healthy|unhealthy|'
        r'enough|too (much|little|few|many)|emergency|danger\w*|sos|dose|'
        r'doses|dosage|mg|ml|boy|girl|gender|sex|guarantee\w*)\b',
        caseSensitive: false,
      );
      expect(forbidden.allMatches(text).map((m) => m[0]), isEmpty);
    });
  });

  // M8a: the hospital-bag template and the birth-plan prompts are original,
  // drafted by Claude and approved by the owner.
  group('hospital bag', () {
    final source = File('assets/content/hospital_bag.json').readAsStringSync();
    final items = parseHospitalBag(source);

    test('about 30 items, every section filled, keys unique and stable', () {
      expect(items.length, inInclusiveRange(24, 36));
      for (final s in BagSection.values) {
        expect(items.where((i) => i.section == s), isNotEmpty, reason: s.name);
      }
      final keys = items.map((i) => i.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      for (final k in keys) {
        expect(k, matches(RegExp(r'^bag-[a-z0-9-]+$')));
      }
    });

    test('hard lines: no forbidden words', () {
      final forbidden = RegExp(
        r'\b(mg|mcg|ml|iu|dose|doses|dosage|tablets?|boy|girl|gender|sex|'
        r'guarantee\w*|emergency|danger\w*|sos|warn\w*|must|should)\b',
        caseSensitive: false,
      );
      expect(forbidden.allMatches(source).map((m) => m[0]), isEmpty);
    });

    test('unsupported schemaVersion is rejected', () {
      expect(
        () => parseHospitalBag('{"schemaVersion": 2, "items": []}'),
        throwsFormatException,
      );
    });

    test('docs/content/hospital_bag.md matches the JSON', () {
      expect(
        File('docs/content/hospital_bag.md').readAsStringSync(),
        renderHospitalBagMarkdown(source),
        reason: 'run: dart run tool/content_md.dart',
      );
    });
  });

  group('birth plan prompts', () {
    final source = File('assets/content/birth_plan.json').readAsStringSync();
    final prompts = parseBirthPlan(source);

    test('5–7 prompts with unique keys, titles and hints', () {
      expect(prompts.length, inInclusiveRange(5, 7));
      expect(prompts.map((p) => p.key).toSet(), hasLength(prompts.length));
      for (final p in prompts) {
        expect(p.key, matches(RegExp(r'^plan-[a-z0-9-]+$')));
        expect(p.title.trim(), isNotEmpty);
        expect(p.hint.trim(), isNotEmpty);
      }
    });

    test('hard lines: no forbidden words, no medical choices suggested', () {
      final forbidden = RegExp(
        r'\b(mg|mcg|ml|iu|dose|doses|dosage|tablets?|boy|girl|gender|sex|'
        r'guarantee\w*|emergency|danger\w*|sos|warn\w*|must|should|'
        r'epidural|induction|caesarean|c-section|recommend\w*)\b',
        caseSensitive: false,
      );
      expect(forbidden.allMatches(source).map((m) => m[0]), isEmpty);
    });

    test('unsupported schemaVersion is rejected', () {
      expect(
        () => parseBirthPlan('{"schemaVersion": 2, "prompts": []}'),
        throwsFormatException,
      );
    });

    test('docs/content/birth_plan.md matches the JSON', () {
      expect(
        File('docs/content/birth_plan.md').readAsStringSync(),
        renderBirthPlanMarkdown(source),
        reason: 'run: dart run tool/content_md.dart',
      );
    });
  });
}
