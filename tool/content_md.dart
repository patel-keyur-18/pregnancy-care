// Regenerates the owner's review copies of the content packs:
//   dart run tool/content_md.dart
// docs/content/weeks.md from assets/content/weeks.json, and
// docs/content/care_template.md from assets/content/care_template_in.json,
// docs/content/activities.md from assets/content/activities.json, and
// docs/content/routines.md from assets/content/routines.json.
import 'dart:convert';
import 'dart:io';

const weeksJson = 'assets/content/weeks.json';
const weeksMd = 'docs/content/weeks.md';
const careJson = 'assets/content/care_template_in.json';
const careMd = 'docs/content/care_template.md';
const activitiesJson = 'assets/content/activities.json';
const activitiesMd = 'docs/content/activities.md';
const routinesJson = 'assets/content/routines.json';
const routinesMd = 'docs/content/routines.md';
const bagJson = 'assets/content/hospital_bag.json';
const bagMd = 'docs/content/hospital_bag.md';
const planJson = 'assets/content/birth_plan.json';
const planMd = 'docs/content/birth_plan.md';

void main() {
  File(
    weeksMd,
  ).writeAsStringSync(renderWeeksMarkdown(File(weeksJson).readAsStringSync()));
  File(careMd)
      .writeAsStringSync(renderCareMarkdown(File(careJson).readAsStringSync()));
  File(activitiesMd).writeAsStringSync(
    renderActivitiesMarkdown(File(activitiesJson).readAsStringSync()),
  );
  File(routinesMd).writeAsStringSync(
    renderRoutinesMarkdown(File(routinesJson).readAsStringSync()),
  );
  File(bagMd).writeAsStringSync(
    renderHospitalBagMarkdown(File(bagJson).readAsStringSync()),
  );
  File(planMd).writeAsStringSync(
    renderBirthPlanMarkdown(File(planJson).readAsStringSync()),
  );
}

String renderWeeksMarkdown(String json) {
  final weeks = ((jsonDecode(json) as Map<String, dynamic>)['weeks'] as List)
      .cast<Map<String, dynamic>>();
  final out = StringBuffer('''
# Week-by-week content (review copy)

Generated from [`assets/content/weeks.json`](../../assets/content/weeks.json) by `dart run tool/content_md.dart`. Edit the JSON, not this file. A test fails if they differ.

General, original text written to the standard of an experienced obstetrician. No numbers, doses, sex prediction, outcome claims or danger-sign lists; anything clinical says "ask your doctor".

**If you only have five minutes, check these:**

1. Test timings: NT scan (wk 10–11), quadruple marker (wk 16), anomaly scan (wk 18), glucose test (wk 24), growth scan (wk 30).
2. Td vaccine (wk 13) and anti-D for Rh-negative mothers (wk 28).
3. The size comparisons: are they familiar fruits and vegetables for you?
4. Weeks 21–27 reuse the prototype's text.
5. Tone: calm, short, no guilt.
''');
  const trimesters = {
    14: 'First trimester',
    28: 'Second trimester',
    43: 'Third trimester',
  };
  String? section;
  for (final w in weeks) {
    final n = w['week'] as int;
    final title = trimesters.entries.firstWhere((e) => n < e.key).value;
    if (title != section) {
      section = title;
      out.write('\n## $title\n');
    }
    out
      ..write('\n**Week $n** · ${w['size']}  \n')
      ..write('Baby: ${w['baby']}  \n')
      ..write('You: ${w['you']}  \n');
    for (final c in (w['checklist'] as List).cast<Map<String, dynamic>>()) {
      out.write('☐ ${c['text']}  \n');
    }
  }
  return out.toString();
}

String renderCareMarkdown(String json) {
  final items = ((jsonDecode(json) as Map<String, dynamic>)['items'] as List)
      .cast<Map<String, dynamic>>();
  final out = StringBuffer('''
# India care template (review copy)

Generated from [`assets/content/care_template_in.json`](../../assets/content/care_template_in.json) by `dart run tool/content_md.dart`. Edit the JSON, not this file. A test fails if they differ.

Tests, scans and vaccines commonly offered in pregnancy in India, written to the standard of an experienced obstetrician. Each becomes an item under Care → Coming up, with the week window as a gentle guide. Nothing here is advice to have or skip anything: every item defers to her doctor. No doses or interpretation.

**If you only have five minutes, check these:**

1. The week windows (especially NT scan, anomaly scan, glucose test, Td).
2. Td first / second wording, and whether you want the Tdap and flu vaccine items.
3. The first-visit test list.

| Weeks | Kind | Item | Note |
|---|---|---|---|
''');
  for (final i in items) {
    final weeks = '${i['fromWeek']}–${i['toWeek']}';
    out.write('| $weeks | ${i['kind']} | ${i['title']} | ${i['note']} |\n');
  }
  return out.toString();
}

String renderActivitiesMarkdown(String json) {
  final items = ((jsonDecode(json) as Map<String, dynamic>)['items'] as List)
      .cast<Map<String, dynamic>>();
  final out = StringBuffer('''
# Daily calm activities (review copy)

Generated from [`assets/content/activities.json`](../../assets/content/activities.json) by `dart run tool/content_md.dart`. Edit the JSON, not this file. A test fails if they differ.

The "Activity" tile on the Garbhasanskar path shows one of these a day, in order, starting again after the last. Original text: small, calm things to do, with no claims about what they do for the baby.

**If you only have five minutes, check these:**

1. Do the ideas feel natural for your days?
2. Anything you'd add from your own family's traditions?

| # | Activity | Text |
|---|---|---|
''');
  for (final (n, i) in items.indexed) {
    out.write('| ${n + 1} | ${i['title']} | ${i['text']} |\n');
  }
  return out.toString();
}

String renderRoutinesMarkdown(String json) {
  final routines =
      ((jsonDecode(json) as Map<String, dynamic>)['routines'] as List)
          .cast<Map<String, dynamic>>();
  final out = StringBuffer('''
# Exercise routines (review copy)

Generated from [`assets/content/routines.json`](../../assets/content/routines.json) by `dart run tool/content_md.dart`. Edit the JSON, not this file. A test fails if they differ.

Gentle, original routines written to the standard of an experienced obstetrician. They stay locked until "Doctor cleared me for exercise" is on in Me, show only for their trimester, and the ones marked "cautious" are hidden when "High-risk pregnancy" is on. Every routine screen shows the same general line (Plan decision 26): "Go gently. Stop and rest if anything feels uncomfortable, and check with your doctor." No lying flat on the back; no claims about outcomes.

**If you only have five minutes, check these:**

1. Are the moves right for each trimester?
2. Which routines should hide for a high-risk pregnancy?
3. Are the timings comfortable?
''');
  for (final r in routines) {
    final moves = (r['moves'] as List).cast<Map<String, dynamic>>();
    final total = moves.fold<int>(0, (sum, m) => sum + (m['sec'] as int));
    final trimesters = (r['trimesters'] as List).join(', ');
    final cautious = r['avoidIfHighRisk'] == true ? ' · cautious' : '';
    out
      ..write('\n## ${r['title']} (`${r['key']}`)\n\n')
      ..write('Trimester $trimesters · ${(total / 60).ceil()} min$cautious\n\n')
      ..write('| Move | How | Time |\n|---|---|---|\n');
    for (final m in moves) {
      out.write('| ${m['name']} | ${m['how']} | ${m['sec']} s |\n');
    }
  }
  return out.toString();
}

String renderHospitalBagMarkdown(String json) {
  final items = ((jsonDecode(json) as Map<String, dynamic>)['items'] as List)
      .cast<Map<String, dynamic>>();
  final out = StringBuffer('''
# Hospital bag (review copy)

Generated from [`assets/content/hospital_bag.json`](../../assets/content/hospital_bag.json) by `dart run tool/content_md.dart`. Edit the JSON, not this file. A test fails if they differ.

The template for Care → Hospital bag. She ticks items as packed and adds her own; a tick follows the item's key, so rewording an item keeps her tick. Original text, nothing medical.

**If you only have five minutes, check these:**

1. Anything missing that your hospital asks you to bring?
2. Anything here you'd never pack?
''');
  const sections = {
    'forMe': 'For me',
    'forBaby': 'For baby',
    'documents': 'Documents',
  };
  for (final MapEntry(key: section, value: title) in sections.entries) {
    out.write('\n## $title\n\n');
    for (final i in items.where((i) => i['section'] == section)) {
      out.write('- ${i['label']} `${i['key']}`\n');
    }
  }
  return out.toString();
}

String renderBirthPlanMarkdown(String json) {
  final prompts =
      ((jsonDecode(json) as Map<String, dynamic>)['prompts'] as List)
          .cast<Map<String, dynamic>>();
  final out = StringBuffer('''
# Birth plan prompts (review copy)

Generated from [`assets/content/birth_plan.json`](../../assets/content/birth_plan.json) by `dart run tool/content_md.dart`. Edit the JSON, not this file. A test fails if they differ.

Care → Birth plan shows each prompt with its hint; she answers in her own words, under the line "Talk this through with your doctor." The prompts suggest no medical choice.

**If you only have five minutes, check these:**

1. Is anything you'd want to write about missing?
2. Does the pain-relief prompt feel right without naming any option?
''');
  for (final p in prompts) {
    out.write('\n## ${p['title']} `${p['key']}`\n\n${p['hint']}\n');
  }
  return out.toString();
}
