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
