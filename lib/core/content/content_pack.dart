import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_pack.g.dart';

/// One tickable item; `key` stays stable when the wording changes, so ticks
/// survive content updates.
typedef ChecklistItem = ({String key, String text});

/// Original week-by-week notes (ARCHITECTURE §9), weeks 4–42.
@immutable
class WeekContent {
  const new({
    required this.week,
    required this.size,
    required this.baby,
    required this.you,
    required this.checklist,
  });

  factory fromJson(Map<String, dynamic> json) => WeekContent(
    week: json['week'] as int,
    size: json['size'] as String,
    baby: json['baby'] as String,
    you: json['you'] as String,
    checklist: [
      for (final c in (json['checklist'] as List).cast<Map<String, dynamic>>())
        (key: c['key'] as String, text: c['text'] as String),
    ],
  );

  final int week;

  /// "a bhutta (corn cob)": reads after "About the size of".
  final String size;
  final String baby;
  final String you;
  final List<ChecklistItem> checklist;
}

class ContentPack {
  new(Iterable<WeekContent> weeks)
    : _weeks = {for (final w in weeks) w.week: w};

  factory fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    if (json['schemaVersion'] != supportedSchemaVersion) {
      throw FormatException('Unsupported weeks.json schemaVersion', json);
    }
    return ContentPack(
      (json['weeks'] as List).cast<Map<String, dynamic>>().map(
        WeekContent.fromJson,
      ),
    );
  }

  static const supportedSchemaVersion = 1;
  static const firstWeek = 4;
  static const lastWeek = 42;

  final Map<int, WeekContent> _weeks;

  /// Notes for [week], or null outside weeks 4–42.
  WeekContent? operator [](int week) => _weeks[week];
}

/// Read once (the provider is kept alive), so the bundle cache isn't needed.
@Riverpod(keepAlive: true)
Future<ContentPack> contentPack(Ref ref) async => ContentPack.fromJson(
  await rootBundle.loadString('assets/content/weeks.json', cache: false),
);

enum CareKind { test, scan, vaccine }

/// One test, scan or vaccine from the India care template (original text).
@immutable
class CareTemplateItem {
  const new({
    required this.key,
    required this.kind,
    required this.title,
    required this.fromWeek,
    required this.toWeek,
    required this.note,
  });

  factory fromJson(Map<String, dynamic> json) => CareTemplateItem(
    key: json['key'] as String,
    kind: CareKind.values.byName(json['kind'] as String),
    title: json['title'] as String,
    fromWeek: json['fromWeek'] as int,
    toWeek: json['toWeek'] as int,
    note: json['note'] as String,
  );

  final String key;
  final CareKind kind;
  final String title;
  final int fromWeek;
  final int toWeek;
  final String note;
}

/// Parses `care_template_in.json` (schemaVersion 1), in file order.
List<CareTemplateItem> parseCareTemplate(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['schemaVersion'] != 1) {
    throw FormatException('Unsupported care template schemaVersion', json);
  }
  return [
    for (final i in (json['items'] as List).cast<Map<String, dynamic>>())
      CareTemplateItem.fromJson(i),
  ];
}

@Riverpod(keepAlive: true)
Future<List<CareTemplateItem>> careTemplate(Ref ref) async => parseCareTemplate(
  await rootBundle.loadString(
    'assets/content/care_template_in.json',
    cache: false,
  ),
);

enum BagSection { forMe, forBaby, documents }

/// One hospital-bag item from the original template (M8a).
typedef BagTemplateItem = ({String key, BagSection section, String label});

/// Parses `hospital_bag.json` (schemaVersion 1), in file order.
List<BagTemplateItem> parseHospitalBag(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['schemaVersion'] != 1) {
    throw FormatException('Unsupported hospital bag schemaVersion', json);
  }
  return [
    for (final i in (json['items'] as List).cast<Map<String, dynamic>>())
      (
        key: i['key'] as String,
        section: BagSection.values.byName(i['section'] as String),
        label: i['label'] as String,
      ),
  ];
}

@Riverpod(keepAlive: true)
Future<List<BagTemplateItem>> hospitalBag(Ref ref) async => parseHospitalBag(
  await rootBundle.loadString('assets/content/hospital_bag.json', cache: false),
);

/// One birth-plan prompt (original text): she answers in her own words.
typedef BirthPlanPrompt = ({String key, String title, String hint});

/// Parses `birth_plan.json` (schemaVersion 1), in file order.
List<BirthPlanPrompt> parseBirthPlan(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['schemaVersion'] != 1) {
    throw FormatException('Unsupported birth plan schemaVersion', json);
  }
  return [
    for (final i in (json['prompts'] as List).cast<Map<String, dynamic>>())
      (
        key: i['key'] as String,
        title: i['title'] as String,
        hint: i['hint'] as String,
      ),
  ];
}

@Riverpod(keepAlive: true)
Future<List<BirthPlanPrompt>> birthPlanPrompts(Ref ref) async => parseBirthPlan(
  await rootBundle.loadString('assets/content/birth_plan.json', cache: false),
);

/// One calm idea for the Garbhasanskar path's "Activity" (original text).
typedef Activity = ({String key, String title, String text});

/// Parses `activities.json` (schemaVersion 1), in file order.
List<Activity> parseActivities(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['schemaVersion'] != 1) {
    throw FormatException('Unsupported activities schemaVersion', json);
  }
  return [
    for (final i in (json['items'] as List).cast<Map<String, dynamic>>())
      (
        key: i['key'] as String,
        title: i['title'] as String,
        text: i['text'] as String,
      ),
  ];
}

@Riverpod(keepAlive: true)
Future<List<Activity>> activities(Ref ref) async => parseActivities(
  await rootBundle.loadString('assets/content/activities.json', cache: false),
);

/// One step of a routine, timed.
typedef Move = ({String name, String how, int sec});

/// A guided exercise routine (original text). Shown only for its
/// [trimesters], hidden when [avoidIfHighRisk] and the pregnancy is marked
/// high-risk, and locked until "doctor cleared me" is on.
@immutable
class Routine {
  const new({
    required this.key,
    required this.title,
    required this.trimesters,
    required this.avoidIfHighRisk,
    required this.moves,
  });

  factory fromJson(Map<String, dynamic> json) => Routine(
    key: json['key'] as String,
    title: json['title'] as String,
    trimesters: (json['trimesters'] as List).cast<int>().toSet(),
    avoidIfHighRisk: json['avoidIfHighRisk'] as bool,
    moves: [
      for (final m in (json['moves'] as List).cast<Map<String, dynamic>>())
        (
          name: m['name'] as String,
          how: m['how'] as String,
          sec: m['sec'] as int,
        ),
    ],
  );

  final String key;
  final String title;
  final Set<int> trimesters;
  final bool avoidIfHighRisk;
  final List<Move> moves;

  int get seconds => moves.fold(0, (sum, m) => sum + m.sec);
}

/// Parses `routines.json` (schemaVersion 1), in file order.
List<Routine> parseRoutines(String source) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['schemaVersion'] != 1) {
    throw FormatException('Unsupported routines schemaVersion', json);
  }
  return [
    for (final r in (json['routines'] as List).cast<Map<String, dynamic>>())
      Routine.fromJson(r),
  ];
}

/// The routines for [trimester], without the cautious ones when [highRisk].
List<Routine> routinesFor(
  List<Routine> all, {
  required int trimester,
  required bool highRisk,
}) => [
  for (final r in all)
    if (r.trimesters.contains(trimester) && !(highRisk && r.avoidIfHighRisk)) r,
];

@Riverpod(keepAlive: true)
Future<List<Routine>> routines(Ref ref) async => parseRoutines(
  await rootBundle.loadString('assets/content/routines.json', cache: false),
);
