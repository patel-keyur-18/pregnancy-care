// Regenerates docs/content/weeks.md, the owner's review copy of
// assets/content/weeks.json:  dart run tool/weeks_md.dart
import 'dart:convert';
import 'dart:io';

const jsonPath = 'assets/content/weeks.json';
const mdPath = 'docs/content/weeks.md';

void main() => File(mdPath)
    .writeAsStringSync(renderWeeksMarkdown(File(jsonPath).readAsStringSync()));

String renderWeeksMarkdown(String json) {
  final weeks = ((jsonDecode(json) as Map<String, dynamic>)['weeks'] as List)
      .cast<Map<String, dynamic>>();
  final out = StringBuffer('''
# Week-by-week content (review copy)

Generated from [`assets/content/weeks.json`](../../assets/content/weeks.json) by `dart run tool/weeks_md.dart`. Edit the JSON, not this file. A test fails if they differ.

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
