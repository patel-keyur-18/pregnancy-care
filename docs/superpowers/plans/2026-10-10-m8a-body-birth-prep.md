# M8a Blood sugar, foods I avoid, hospital bag and birth plan — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Navmaas 1.3.0 with blood-sugar readings in Vitals, a Care → Nutrition screen holding "Foods I avoid", a hospital-bag checklist with an optional reminder, and a birth plan. All of it is per pregnancy, in backups, and never interpreted.

**Architecture:**
- **Schema v12** adds two columns to `vital_reading` and three tables.
- **New feature folders:**
  - `lib/features/nutrition/` holds Foods I avoid. M8b adds the Nourishly section there.
  - `lib/features/birth_prep/` holds the bag and the birth plan.
- **Content packs** (`hospital_bag.json`, `birth_plan.json`) load like the care template.
- **The bag reminder** is a `ReminderSettings` field planned by `ReminderSync`.

**Tech Stack:** Flutter, drift + SQLCipher, Riverpod 3 codegen, go_router, gen-l10n. No new packages.

**Spec:** `docs/superpowers/specs/2026-10-10-m8-body-birth-prep-design.md` §5

## Global Constraints

- **Branch** `feat/m8a-body-birth-prep`, rebased on `main` after the signing PR merges. PR title `feat: blood sugar, foods I avoid, hospital bag and birth plan`. Version `1.3.0+5` in `pubspec.yaml` and `appVersion` (a test checks they match).
- **No interpretation:** no ranges, colours, "high/low/normal", targets or food advice. Words live in `app_en.arb`, and the hard-line content test covers every new prefix.
- **Never** `DateTime.now()` in `lib/`. Use `clockNow()`.
- **Never** Material `Icons`, never hard-coded colours. `NavmaasIcon` + theme only.
- **Accessibility:** ≥ 48 dp targets, a `Semantics(header: true)` heading on every screen, sheet and dialog, no overflow at 1.0×/1.3×/2.0×, reduce motion respected. New screens go in `test/accessibility_test.dart`.
- **Dialogs with text fields** own their controllers (create and dispose in the dialog's `State`).
- **Drift transactions** read with `get…()`, never `watch().first`.
- **Gates (stop and wait for the owner):**
  - Task 1's content must be approved before Tasks 6–8 use it.
  - Task 2's prototype boards must be approved before any screen code (Tasks 5–9).
- After each task: `dart format .`, `flutter analyze` (zero issues), the task's tests, then commit.
- Docs stay in sync in the same PR (Task 10).

## Review Focus

- **Blood sugar typed as "5.6"** (mmol/L habit) or "0": the dialog only accepts whole numbers 1–999 mg/dL and rejects anything else silently (Save does nothing), like the weight dialog. Test in Task 5.
- **A template item removed or renamed in `hospital_bag.json`** after she ticked it: removed keys vanish without error, and a renamed label keeps the tick (keys are stable). Test in Task 4.
- **Her own bag item with an empty or whitespace name:** not saved. Test in Task 4.
- **The bag reminder date already passed** (she set it, then the day went by): nothing is scheduled, no crash. The setting stays until she clears it. Test in Task 7.
- **"Start a new pregnancy" after ticking bag items:** the new pregnancy starts with an empty bag, empty birth plan and empty avoid list (all keyed by `pregnancyId`). Test in Task 4.

---

### Task 1: Content packs drafted, parsed and hard-line tested (GATE: owner approves the text)

**Files:**
- Create: `assets/content/hospital_bag.json`, `assets/content/birth_plan.json`
- Modify: `pubspec.yaml` (assets list), `lib/core/content/content_pack.dart` (parsers + providers), `tool/content_md.dart` (two renderers), `test/core/content/content_pack_test.dart`
- Create (generated): `docs/content/hospital_bag.md`, `docs/content/birth_plan.md`

**Interfaces:**
- Produces:
  - `enum BagSection { forMe, forBaby, documents }`
  - `typedef BagTemplateItem = ({String key, BagSection section, String label})`
  - `List<BagTemplateItem> parseHospitalBag(String)` and `hospitalBagProvider` (`Future<List<BagTemplateItem>>`)
  - `typedef BirthPlanPrompt = ({String key, String title, String hint})`
  - `List<BirthPlanPrompt> parseBirthPlan(String)` and `birthPlanPromptsProvider`
  - `String renderHospitalBagMarkdown(String json)` and `String renderBirthPlanMarkdown(String json)`

- [ ] **Step 1: Write the failing tests** (append to `content_pack_test.dart`):

```dart
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

    test('docs/content/birth_plan.md matches the JSON', () {
      expect(
        File('docs/content/birth_plan.md').readAsStringSync(),
        renderBirthPlanMarkdown(source),
        reason: 'run: dart run tool/content_md.dart',
      );
    });
  });
```

The prompts may say "pain relief you'd like to talk about", but never name a medical procedure. That keeps them from suggesting choices.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/core/content/content_pack_test.dart`
Expected: compile errors, since `parseHospitalBag` and `parseBirthPlan` aren't defined yet.

- [ ] **Step 3: Parsers and providers** in `lib/core/content/content_pack.dart`, after the care template:

```dart
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
```

Add both files under `flutter: assets:` in `pubspec.yaml`, then run `dart run build_runner build`.

- [ ] **Step 4: Draft the content** (original wording; India context: ID proofs, hospital file, maternity card; plain items).
  - `hospital_bag.json` shape: `{"schemaVersion": 1, "items": [{"key": "bag-me-nightwear", "section": "forMe", "label": "Two loose, front-opening nightwear sets"}, …]}`. About 12 For me, 10 For baby and 6 Documents items.
  - `birth_plan.json` shape: `{"schemaVersion": 1, "prompts": [{"key": "plan-with-me", "title": "Who will be with you", "hint": "The people you'd like beside you, and anyone you'd rather wait outside."}, …]}`. Six prompts: who will be with you; comfort (music, light, movement, what helps you feel calm); pain relief you'd like to talk over with your doctor; after the birth (holding baby, visitors, rest); feeding wishes; anything else.

- [ ] **Step 5: Renderers** in `tool/content_md.dart`. Add constants, `main()` lines and the two renderers, following `renderActivitiesMarkdown`'s style:

```dart
const bagJson = 'assets/content/hospital_bag.json';
const bagMd = 'docs/content/hospital_bag.md';
const planJson = 'assets/content/birth_plan.json';
const planMd = 'docs/content/birth_plan.md';

String renderHospitalBagMarkdown(String json) {
  final items = parseHospitalBag(json);
  const titles = {
    BagSection.forMe: 'For me',
    BagSection.forBaby: 'For baby',
    BagSection.documents: 'Documents',
  };
  final b = StringBuffer()
    ..writeln('# Hospital bag (review copy)')
    ..writeln()
    ..writeln(
      'Generated from [`assets/content/hospital_bag.json`]'
      '(../../assets/content/hospital_bag.json) by '
      '`dart run tool/content_md.dart`. Edit the JSON, not this file. '
      'A test fails if they differ.',
    );
  for (final s in BagSection.values) {
    b
      ..writeln()
      ..writeln('## ${titles[s]}')
      ..writeln();
    for (final i in items.where((i) => i.section == s)) {
      b.writeln('- ${i.label} `${i.key}`');
    }
  }
  return b.toString();
}

String renderBirthPlanMarkdown(String json) {
  final b = StringBuffer()
    ..writeln('# Birth plan prompts (review copy)')
    ..writeln()
    ..writeln(
      'Generated from [`assets/content/birth_plan.json`]'
      '(../../assets/content/birth_plan.json) by '
      '`dart run tool/content_md.dart`. Edit the JSON, not this file. '
      'A test fails if they differ.',
    );
  for (final p in parseBirthPlan(json)) {
    b
      ..writeln()
      ..writeln('## ${p.title} `${p.key}`')
      ..writeln()
      ..writeln(p.hint);
  }
  return b.toString();
}
```

`tool/content_md.dart` must import `package:navmaas/core/content/content_pack.dart`. Check whether its existing renderers already import it; if they parse JSON directly instead, do the same here and skip the import.

- [ ] **Step 6: Generate and pass**

Run: `dart run tool/content_md.dart && flutter test test/core/content/content_pack_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add assets/content/hospital_bag.json assets/content/birth_plan.json docs/content/hospital_bag.md docs/content/birth_plan.md lib/core/content tool/content_md.dart test/core/content pubspec.yaml
git commit -m "feat(content): hospital bag template and birth-plan prompts"
```

- [ ] **Step 8: GATE.** Ask the owner to review `docs/content/hospital_bag.md` and `docs/content/birth_plan.md`. Apply the edits in the JSON, regenerate, and commit. Don't start Task 6 or 8 until approved.

### Task 2: Prototype boards (GATE: owner approves)

**Files:** the prototype artifact `https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8`. Read it first with `Artifact action: read`, then republish to the same URL.

- [ ] **Step 1:** Read the prototype and match its existing Care, sheet and list boards (tokens from `design/navmaas-tokens.css`, `NavmaasIcon` paths).
- [ ] **Step 2:** Add boards in light and dark:
  1. Care with a Blood sugar vital tile, a Nutrition tile, and the "Getting ready" row (Hospital bag, Birth plan) at week 28+, plus its lower placement before week 28.
  2. The blood-sugar log dialog: mg/dL, five context chips, time, note.
  3. The Blood sugar list by day.
  4. Nutrition with Foods I avoid: empty and filled list, add/edit dialog. Also a greyed placeholder area marked "M8b: From Nourishly", so the final layout is visible.
  5. Hospital bag: three sections, ticks, add-your-own, reminder row.
  6. Birth plan: the doctor line, prompts with answers and empty ones, the edit sheet.
- [ ] **Step 3:** Publish to the same URL. Update `docs/DESIGN_SYSTEM.md` line 6 (the board list) in Task 10.
- [ ] **Step 4: GATE.** The owner approves the boards. Their decisions on placement and wording feed Tasks 5–9. Record any new icon as SVG path data for `NavmaasIcon` (Task 9).

### Task 3: Schema v12 and migrations

**Files:**
- Modify: `lib/core/db/tables.dart` (`VitalKind`, `VitalReadings`, three new tables, `BloodSugarContext`)
- Modify: `lib/core/db/app_database.dart` (table list, `schemaVersion => 12`, `from11To12`)
- Generated: `lib/core/db/app_database.steps.dart`, `drift_schemas/…/drift_schema_v12.json`, `test/drift/navmaas/generated/schema_v12.dart` (via `make-migrations`)
- Modify: `test/drift/navmaas/migration_test.dart`, `test/features/backup/backup_service_test.dart`

**Interfaces:**
- Consumes: `BagSection` from Task 1 (import `content_pack.dart` `show BagSection`, as `tables.dart` already does for `CareKind`).
- Produces:
  - Drift classes `VitalReading` (+ `context`, `note`), `AvoidFood`, `BagItem` and `BirthPlanAnswer`, with companions.
  - `enum BloodSugarContext { fasting, beforeMeal, after1h, after2h, bedtime }`.

- [ ] **Step 1: Tables** in `tables.dart`. Change `VitalKind` and its doc, and add to `VitalReadings`:

```dart
enum VitalKind { weight, bloodPressure, bloodSugar }

/// When a blood-sugar reading was taken (M8a). Words in `app_en.arb`.
enum BloodSugarContext { fasting, beforeMeal, after1h, after2h, bedtime }

/// A logged reading. Weight: [value1] kg. Blood pressure: [value1] systolic,
/// [value2] diastolic (mmHg). Blood sugar: [value1] mg/dL with a [context].
/// Recorded only; never interpreted.
@DataClassName('VitalReading')
class VitalReadings extends Table with BaseColumns {
  @override
  String get tableName => 'vital_reading';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get kind => textEnum<VitalKind>()();
  RealColumn get value1 => real()();
  RealColumn get value2 => real().nullable()();
  DateTimeColumn get at => dateTime()();

  /// Blood sugar only (v12).
  TextColumn get context => textEnum<BloodSugarContext>().nullable()();
  TextColumn get note => text().nullable()();
}
```

New tables, after `MediaLinks`:

```dart
/// A food she avoids, with her own reason (M8a). Her list; never advice.
@DataClassName('AvoidFood')
class AvoidFoods extends Table with BaseColumns {
  @override
  String get tableName => 'avoid_food';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get name => text()();
  TextColumn get reason => text().nullable()();
}

/// A hospital-bag item: a template item she ticked ([templateKey]) or one of
/// her own ([label]). Unticking a template item sets [packed] false.
@DataClassName('BagItem')
class BagItems extends Table with BaseColumns {
  @override
  String get tableName => 'bag_item';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get templateKey => text().nullable()();
  TextColumn get label => text().nullable()();
  TextColumn get section => textEnum<BagSection>()();
  BoolColumn get packed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {pregnancyId, templateKey},
  ];
}

/// Her answer to one birth-plan prompt (`BirthPlanPrompt.key`).
@DataClassName('BirthPlanAnswer')
class BirthPlanAnswers extends Table with BaseColumns {
  @override
  String get tableName => 'birth_plan_answer';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get promptKey => text()();
  TextColumn get answer => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {pregnancyId, promptKey},
  ];
}
```

SQLite treats NULLs as distinct, so many of her own items (`templateKey` NULL) don't clash with the unique key.

- [ ] **Step 2: Database.** Add `AvoidFoods, BagItems, BirthPlanAnswers` to `@DriftDatabase(tables: …)`, set `schemaVersion => 12`, and add the step:

```dart
      // v12 (M8a): blood sugar on vitals, foods she avoids, the hospital bag
      // and the birth plan.
      from11To12: (m, schema) async {
        await m.addColumn(schema.vitalReading, schema.vitalReading.context);
        await m.addColumn(schema.vitalReading, schema.vitalReading.note);
        await m.createTable(schema.avoidFood);
        await m.createTable(schema.bagItem);
        await m.createTable(schema.birthPlanAnswer);
      },
```

Run: `dart run build_runner build && dart run drift_dev make-migrations`
Expected: `drift_schema_v12.json`, `schema_v12.dart` and the new `from11To12` step type in `app_database.steps.dart`.

- [ ] **Step 3: Migration test** (append to `migration_test.dart`; import `generated/schema_v11.dart as v11`):

```dart
  test('v11 → v12 keeps her vitals and adds empty birth-prep tables', () async {
    final schema = await verifier.schemaAt(11);
    final old = v11.DatabaseAtV11(schema.newConnection());
    const at = '2026-10-05T00:00:00.000';
    await old.into(old.pregnancy).insert(
      v11.PregnancyCompanion.insert(
        id: 'p1',
        createdAt: at,
        updatedAt: at,
        status: 'active',
        datingMethod: 'lmp',
        startDate: '2026-04-15',
        dueDate: '2027-01-20',
      ),
    );
    await old.into(old.vitalReading).insert(
      v11.VitalReadingCompanion.insert(
        id: 'v1',
        createdAt: at,
        updatedAt: at,
        pregnancyId: 'p1',
        kind: 'weight',
        value1: 61.5,
        at: at,
      ),
    );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 12);
    final v = await db.select(db.vitalReadings).getSingle();
    expect((v.kind, v.value1, v.context, v.note), (VitalKind.weight, 61.5, null, null));
    expect(await db.select(db.avoidFoods).get(), isEmpty);
    expect(await db.select(db.bagItems).get(), isEmpty);
    expect(await db.select(db.birthPlanAnswers).get(), isEmpty);
    await db.close();
  });
```

Check the generated `v11` companion's column types (dates are stored as text in these snapshots, as in the v10 test) and adjust literals to match.

- [ ] **Step 4: Older backups.** In `backup_service_test.dart`:
  - Add the three new tables to every `dropped` list.
  - Add `(11, ['avoid_food', 'bag_item', 'birth_plan_answer'])`.
  - Drop the two new `vital_reading` columns for every version below 12:

```dart
  const birthPrepTables = ['avoid_food', 'bag_item', 'birth_plan_answer'];
  // … each existing tuple gets ...birthPrepTables, e.g.
  //   (10, [...birthPrepTables]),
  //   (11, [...birthPrepTables]),
  // and inside the test, after the letter columns:
      // v12 added a blood-sugar reading's context and note.
      for (final column in ['context', 'note']) {
        await a.db.customStatement(
          'ALTER TABLE vital_reading DROP COLUMN $column',
        );
      }
```

The letter-column drop runs for every version today. Guard it with `if (version < 11)` now that v11 is in the list, since a v11 backup has those columns.

- [ ] **Step 5: Run**

Run: `flutter test test/drift test/features/backup test/core/db`
Expected: PASS, all version pairs to v12 included.

- [ ] **Step 6: Commit**

```bash
git add lib/core/db test/drift test/features/backup drift_schemas
git commit -m "feat(db): schema v12 for blood sugar and birth prep"
```

### Task 4: Repositories

**Files:**
- Modify: `lib/features/care/data/vitals_repository.dart`
- Create: `lib/features/nutrition/data/avoid_food_repository.dart`
- Create: `lib/features/birth_prep/data/bag_repository.dart`, `lib/features/birth_prep/data/birth_plan_repository.dart`
- Create: `test/features/birth_prep/birth_prep_data_test.dart`, `test/features/nutrition/avoid_food_data_test.dart`
- Modify: `test/features/care/care_data_test.dart` (blood-sugar add)

**Interfaces:**
- Consumes: the Task 3 tables and the Task 1 `BagTemplateItem`.
- Produces:
  - `VitalsRepository.add({…, BloodSugarContext? context, String? note})`
  - `AvoidFoodRepository`: `watch(pregnancyId)`, `save({String? id, required String pregnancyId, required String name, String? reason})`, `delete(id)`. Provider `avoidFoodsProvider`.
  - `typedef BagRow = ({String? id, String? templateKey, String label, BagSection section, bool packed})`
  - `List<BagRow> mergeBag(List<BagTemplateItem> template, List<BagItem> rows)` (pure)
  - `BagRepository`: `watch(pregnancyId)`, `setPacked({required String pregnancyId, required BagRow row, required bool packed})`, `addOwn({required String pregnancyId, required String label, required BagSection section})`, `deleteOwn(id)`. Provider `bagProvider` (`Stream<List<BagRow>>` merged with the template).
  - `BirthPlanRepository`: `watch(pregnancyId) → Stream<Map<String, String>>` (promptKey → answer), `save({required String pregnancyId, required String promptKey, required String answer})`. An empty answer soft-deletes. Provider `birthPlanAnswersProvider`.

- [ ] **Step 1: Failing tests.** `test/features/birth_prep/birth_prep_data_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/features/birth_prep/data/bag_repository.dart';
import 'package:navmaas/features/birth_prep/data/birth_plan_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late String pregnancyId;
  late BagRepository bag;

  const template = <BagTemplateItem>[
    (key: 'bag-me-gown', section: BagSection.forMe, label: 'Nightwear'),
    (key: 'bag-baby-cap', section: BagSection.forBaby, label: 'Soft cap'),
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
    pregnancyId = (await db.select(db.pregnancies).getSingle()).id;
    bag = BagRepository(db);
  });
  tearDown(() => db.close());

  Future<List<BagRow>> rows([List<BagTemplateItem> t = template]) async =>
      mergeBag(t, await bag.watch(pregnancyId).first);

  test('template items start unpacked; a tick persists', () async {
    expect((await rows()).map((r) => r.packed), [false, false]);
    await bag.setPacked(pregnancyId: pregnancyId, row: (await rows())[0], packed: true);
    expect((await rows()).map((r) => r.packed), [true, false]);
    await bag.setPacked(pregnancyId: pregnancyId, row: (await rows())[0], packed: false);
    expect((await rows()).map((r) => r.packed), [false, false]);
  });

  test('a renamed template item keeps its tick; a removed one disappears', () async {
    await bag.setPacked(pregnancyId: pregnancyId, row: (await rows())[0], packed: true);
    const edited = <BagTemplateItem>[
      (key: 'bag-me-gown', section: BagSection.forMe, label: 'Two nightwear sets'),
    ];
    final r = await rows(edited);
    expect(r.map((x) => (x.label, x.packed)), [('Two nightwear sets', true)]);
  });

  test('her own items: added under a section, blank names refused, deleted', () async {
    await bag.addOwn(pregnancyId: pregnancyId, label: '  Phone charger ', section: BagSection.forMe);
    await bag.addOwn(pregnancyId: pregnancyId, label: '   ', section: BagSection.forMe);
    final own = (await rows()).where((r) => r.templateKey == null).toList();
    expect(own.map((r) => (r.label, r.section)), [('Phone charger', BagSection.forMe)]);
    await bag.deleteOwn(own.single.id!);
    expect((await rows()).where((r) => r.templateKey == null), isEmpty);
  });

  test('a new pregnancy starts with an empty bag and birth plan', () async {
    await bag.setPacked(pregnancyId: pregnancyId, row: (await rows())[0], packed: true);
    final plan = BirthPlanRepository(db);
    await plan.save(pregnancyId: pregnancyId, promptKey: 'plan-with-me', answer: 'Mum');
    await PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2027, 4, 1));
    final second = (await (db.select(db.pregnancies)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get())
        .first
        .id;
    expect(second, isNot(pregnancyId));
    expect(mergeBag(template, await bag.watch(second).first).map((r) => r.packed),
        [false, false]);
    expect(await plan.watch(second).first, isEmpty);
  });

  test('birth plan: save, edit, clear', () async {
    final plan = BirthPlanRepository(db);
    await plan.save(pregnancyId: pregnancyId, promptKey: 'plan-with-me', answer: 'Mum');
    await plan.save(pregnancyId: pregnancyId, promptKey: 'plan-with-me', answer: 'Mum and my sister');
    expect(await plan.watch(pregnancyId).first, {'plan-with-me': 'Mum and my sister'});
    await plan.save(pregnancyId: pregnancyId, promptKey: 'plan-with-me', answer: '  ');
    expect(await plan.watch(pregnancyId).first, isEmpty);
  });
}
```

Before writing the "new pregnancy" test, check `PregnancyRepository` for how a second pregnancy is started (the "Start new" flow from M5a). Use that method instead of `saveDating` if `saveDating` updates the active one in place.

`test/features/nutrition/avoid_food_data_test.dart`:

```dart
  test('foods she avoids: add with a reason, edit, delete, blanks refused', () async {
    final repo = AvoidFoodRepository(db);
    await repo.save(pregnancyId: pregnancyId, name: ' Papaya ', reason: "doctor's advice");
    await repo.save(pregnancyId: pregnancyId, name: '  ');
    var list = await repo.watch(pregnancyId).first;
    expect(list.map((f) => (f.name, f.reason)), [('Papaya', "doctor's advice")]);
    await repo.save(id: list.single.id, pregnancyId: pregnancyId, name: 'Raw papaya', reason: '');
    list = await repo.watch(pregnancyId).first;
    expect(list.map((f) => (f.name, f.reason)), [('Raw papaya', null)]);
    await repo.delete(list.single.id);
    expect(await repo.watch(pregnancyId).first, isEmpty);
  });
```

(same `setUp`/`tearDown` as above). In `care_data_test.dart`, add:

```dart
  test('blood sugar keeps its context and note', () async {
    final vitals = VitalsRepository(db);
    await vitals.add(
      pregnancyId: pregnancyId,
      kind: VitalKind.bloodSugar,
      value1: 92,
      context: BloodSugarContext.fasting,
      note: 'after a walk',
    );
    final r = (await vitals.watch(pregnancyId, VitalKind.bloodSugar).first).single;
    expect((r.value1, r.context, r.note), (92.0, BloodSugarContext.fasting, 'after a walk'));
  });
```

- [ ] **Step 2: Run, expect failure**

Run: `flutter test test/features/birth_prep test/features/nutrition test/features/care/care_data_test.dart`
Expected: compile errors (missing repositories).

- [ ] **Step 3: Implement.** `VitalsRepository.add` gains `BloodSugarContext? context, String? note` passed as `Value(context)` / `Value(note)`, and its doc reads "Weight, blood-pressure and blood-sugar logs."

`lib/features/nutrition/data/avoid_food_repository.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'avoid_food_repository.g.dart';

/// Foods she avoids, with her own reason (M8a). Her list; the app adds no
/// food guidance of its own.
class AvoidFoodRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<List<AvoidFood>> watch(String pregnancyId) =>
      (_db.select(_db.avoidFoods)
            ..where((t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Adds (no [id]) or edits. A blank name saves nothing; a blank reason
  /// clears it.
  Future<void> save({
    String? id,
    required String pregnancyId,
    required String name,
    String? reason,
  }) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final r = reason?.trim();
    final why = Value(r == null || r.isEmpty ? null : r);
    if (id == null) {
      await _db.into(_db.avoidFoods).insert(
        AvoidFoodsCompanion.insert(pregnancyId: pregnancyId, name: n, reason: why),
      );
    } else {
      await (_db.update(_db.avoidFoods)..where((t) => t.id.equals(id))).write(
        AvoidFoodsCompanion(name: Value(n), reason: why, updatedAt: Value(clockNow())),
      );
    }
  }

  Future<void> delete(String id) =>
      (_db.update(_db.avoidFoods)..where((t) => t.id.equals(id))).write(
        AvoidFoodsCompanion(deletedAt: Value(clockNow())),
      );
}

@riverpod
AvoidFoodRepository avoidFoodRepository(Ref ref) =>
    AvoidFoodRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<AvoidFood>> avoidFoods(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(avoidFoodRepositoryProvider).watch(id);
}
```

`lib/features/birth_prep/data/bag_repository.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bag_repository.g.dart';

/// One line of the hospital bag as shown: a template item or one of hers.
typedef BagRow = ({
  String? id,
  String? templateKey,
  String label,
  BagSection section,
  bool packed,
});

/// The template in file order with her ticks, then her own items. Ticks on
/// keys the template no longer has are dropped; labels come from the
/// template, so a reworded item keeps its tick.
List<BagRow> mergeBag(List<BagTemplateItem> template, List<BagItem> rows) {
  final ticked = {
    for (final r in rows)
      if (r.templateKey != null) r.templateKey!: r,
  };
  return [
    for (final t in template)
      (
        id: ticked[t.key]?.id,
        templateKey: t.key,
        label: t.label,
        section: t.section,
        packed: ticked[t.key]?.packed ?? false,
      ),
    for (final r in rows)
      if (r.templateKey == null)
        (id: r.id, templateKey: null, label: r.label!, section: r.section, packed: r.packed),
  ];
}

/// Hospital-bag ticks and her own items, per pregnancy (M8a).
class BagRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<List<BagItem>> watch(String pregnancyId) =>
      (_db.select(_db.bagItems)
            ..where((t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> setPacked({
    required String pregnancyId,
    required BagRow row,
    required bool packed,
  }) async {
    if (row.templateKey == null) {
      await (_db.update(_db.bagItems)..where((t) => t.id.equals(row.id!))).write(
        BagItemsCompanion(packed: Value(packed), updatedAt: Value(clockNow())),
      );
      return;
    }
    await _db.into(_db.bagItems).insert(
      BagItemsCompanion.insert(
        pregnancyId: pregnancyId,
        templateKey: Value(row.templateKey),
        section: row.section,
        packed: Value(packed),
      ),
      onConflict: DoUpdate(
        (_) => BagItemsCompanion(
          packed: Value(packed),
          deletedAt: const Value(null),
          updatedAt: Value(clockNow()),
        ),
        target: [_db.bagItems.pregnancyId, _db.bagItems.templateKey],
      ),
    );
  }

  /// A blank label saves nothing.
  Future<void> addOwn({
    required String pregnancyId,
    required String label,
    required BagSection section,
  }) async {
    final l = label.trim();
    if (l.isEmpty) return;
    await _db.into(_db.bagItems).insert(
      BagItemsCompanion.insert(pregnancyId: pregnancyId, label: Value(l), section: section),
    );
  }

  Future<void> deleteOwn(String id) =>
      (_db.update(_db.bagItems)..where((t) => t.id.equals(id))).write(
        BagItemsCompanion(deletedAt: Value(clockNow())),
      );
}

@riverpod
BagRepository bagRepository(Ref ref) => BagRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<BagRow>> bag(Ref ref) async* {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) {
    yield const [];
    return;
  }
  final template = await ref.watch(hospitalBagProvider.future);
  yield* ref.watch(bagRepositoryProvider).watch(id).map((r) => mergeBag(template, r));
}
```

`lib/features/birth_prep/data/birth_plan_repository.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'birth_plan_repository.g.dart';

/// Her birth-plan answers in her own words, one per prompt (M8a).
class BirthPlanRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<Map<String, String>> watch(String pregnancyId) =>
      (_db.select(_db.birthPlanAnswers)
            ..where((t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull()))
          .watch()
          .map((rows) => {for (final r in rows) r.promptKey: r.answer});

  /// A blank answer clears the prompt.
  Future<void> save({
    required String pregnancyId,
    required String promptKey,
    required String answer,
  }) {
    final a = answer.trim();
    return _db.into(_db.birthPlanAnswers).insert(
      BirthPlanAnswersCompanion.insert(
        pregnancyId: pregnancyId,
        promptKey: promptKey,
        answer: a,
        deletedAt: Value(a.isEmpty ? clockNow() : null),
      ),
      onConflict: DoUpdate(
        (_) => BirthPlanAnswersCompanion(
          answer: Value(a),
          deletedAt: Value(a.isEmpty ? clockNow() : null),
          updatedAt: Value(clockNow()),
        ),
        target: [_db.birthPlanAnswers.pregnancyId, _db.birthPlanAnswers.promptKey],
      ),
    );
  }
}

@riverpod
BirthPlanRepository birthPlanRepository(Ref ref) =>
    BirthPlanRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<Map<String, String>> birthPlanAnswers(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const {});
  return ref.watch(birthPlanRepositoryProvider).watch(id);
}
```

- [ ] **Step 4: Generate and run**

Run: `dart run build_runner build && flutter test test/features/birth_prep test/features/nutrition test/features/care/care_data_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/care/data lib/features/nutrition lib/features/birth_prep test/features
git commit -m "feat: repositories for blood sugar, foods I avoid, bag and birth plan"
```

### Task 5: Blood sugar in Vitals

**Files:**
- Modify: `lib/features/care/presentation/care_widgets.dart` (`logVital` + `_VitalDialog`)
- Modify: `lib/features/care/presentation/care_screen.dart` (`_VitalsRow`: third tile; layout per Task 2 boards)
- Create: `lib/features/care/presentation/blood_sugar_screen.dart`
- Modify: `lib/app/router.dart` (`/care/blood-sugar`)
- Modify: `lib/l10n/app_en.arb`
- Modify: `test/features/care/care_screens_test.dart`, `test/core/content/content_pack_test.dart`

**Interfaces:**
- Consumes: `VitalsRepository.add(context:, note:)`, `vitalsProvider(VitalKind.bloodSugar)`.
- Produces: route `/care/blood-sugar`, `BloodSugarScreen`, and arb keys:
  - Titles and labels: `bloodSugar` "Blood sugar", `logBloodSugar` "Log blood sugar", `bloodSugarValue` "{value} mg/dL", `bloodSugarLabel` "mg/dL", `bloodSugarWhen` "When", `bloodSugarNote` "Note (optional)", `bloodSugarTitle` "Blood sugar", `bloodSugarEmpty` "No readings yet".
  - Context words: `bloodSugarContextFasting` "Fasting", `bloodSugarContextBeforeMeal` "Before a meal", `bloodSugarContextAfter1h` "1 h after a meal", `bloodSugarContextAfter2h` "2 h after a meal", `bloodSugarContextBedtime` "Bedtime".

- [ ] **Step 1: Failing widget test** in `care_screens_test.dart` (reuse that file's `_tapText`):

```dart
  testWidgets('blood sugar: logged with its context, listed by day, never judged',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Log blood sugar');
    await tester.enterText(find.byType(TextField).first, '5.6');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'decimals refused');
    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: '0 refused');
    await tester.enterText(find.byType(TextField).first, '96');
    await tester.tap(find.text('Fasting'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('96 mg/dL'), findsOneWidget);
    await _tapText(tester, 'Blood sugar');
    expect(find.text('Fasting'), findsOneWidget);
    expect(find.textContaining(RegExp('high|low|normal|range', caseSensitive: false)),
        findsNothing);
  });
```

If the Task 2 boards make the tile itself, not the label, the way into the list, adjust the second `_tapText` target.

- [ ] **Step 2: Run, expect failure**

Run: `flutter test test/features/care/care_screens_test.dart --plain-name 'blood sugar'`
Expected: FAIL ("Log blood sugar" not found).

- [ ] **Step 3: Dialog.** Extend `logVital` to return `(double, double?, BloodSugarContext?, String?)` and pass `context`/`note` to `add`. In `_VitalDialogState`:
  - Add `_note` (a `TextEditingController`, disposed in `dispose`) and `BloodSugarContext? _context`.
  - `_save` for blood sugar: `final v = int.tryParse(_a.text); if (v == null || v < 1 || v > 999) return;`. A context is optional.
  - Blood sugar uses the `FilteringTextInputFormatter.digitsOnly` formatter with length 3.
  - Context chips: a `Wrap` of `ChoiceChip`s from `BloodSugarContext.values`, labelled through `bloodSugarContextWord(l10n, c)`, each with `materialTapTargetSize: MaterialTapTargetSize.padded` to keep 48 dp.
  - The note field is single-line, 120 characters.
  - The `AlertDialog` title is wrapped in `Semantics(header: true, …)`.

Add a word helper next to the dialog:

```dart
String bloodSugarContextWord(AppLocalizations l10n, BloodSugarContext c) =>
    switch (c) {
      BloodSugarContext.fasting => l10n.bloodSugarContextFasting,
      BloodSugarContext.beforeMeal => l10n.bloodSugarContextBeforeMeal,
      BloodSugarContext.after1h => l10n.bloodSugarContextAfter1h,
      BloodSugarContext.after2h => l10n.bloodSugarContextAfter2h,
      BloodSugarContext.bedtime => l10n.bloodSugarContextBedtime,
    };
```

- [ ] **Step 4: Tile and list.**
  - `_VitalsRow` adds a third `_VitalTile` (label `bloodSugar`, value `bloodSugarValue(last.value1.round())`, detail `loggedOn(…)` or `notLoggedYet`, action `logBloodSugar`). It sits per the boards: likely a second row so three tiles never squeeze at 2.0× text. Tapping the tile's label area pushes `/care/blood-sugar`.
  - `BloodSugarScreen`: a `Scaffold` with a back button and a `Semantics(header: true)` title. The `ListView` groups readings by `localDay(at)`, newest first. Each day has a date header, then rows of `time · value mg/dL · context word` with the note below in `bodySmall`. An empty state shows `bloodSugarEmpty`.
  - Register `GoRoute(path: 'blood-sugar', builder: (_, _) => const BloodSugarScreen())` under the `/care` branch.

- [ ] **Step 5: Content hard line.** Add `'bloodSugar'` to the `prefixes` list in `content_pack_test.dart`'s wellbeing-words test, and rename the group to `'wellbeing and vitals words (app_en.arb)'`. It must still contain "Heartburn". Then add:

```dart
    test('every blood-sugar context has a word', () {
      expect(labels('bloodSugarContext').keys.toSet(),
          {for (final c in BloodSugarContext.values) cap(c.name)});
    });
```

`cap('after1h')` is `'After1h'`, which matches `bloodSugarContextAfter1h`.

- [ ] **Step 6: Run**

Run: `flutter test test/features/care test/core/content && flutter analyze`
Expected: PASS, zero issues.

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat(care): blood sugar readings with context, listed by day"
```

### Task 6: Care → Nutrition with Foods I avoid

**Files:**
- Create: `lib/features/nutrition/presentation/nutrition_screen.dart`
- Modify: `lib/features/care/presentation/care_screen.dart` (Nutrition tile, per boards)
- Modify: `lib/app/router.dart` (`/care/nutrition`)
- Modify: `lib/l10n/app_en.arb`
- Create: `test/features/nutrition/nutrition_screens_test.dart`
- Modify: `test/core/content/content_pack_test.dart` (prefix `nutrition`, `avoid`)

**Interfaces:**
- Consumes: `avoidFoodsProvider`, `avoidFoodRepositoryProvider`, `activePregnancyProvider`.
- Produces:
  - `NutritionScreen` at `/care/nutrition`. Its body is a `ListView` whose first child is reserved for M8b's Nourishly section; in M8a it's absent.
  - arb keys: `nutritionTitle` "Nutrition", `avoidFoodsTitle` "Foods I avoid", `avoidFoodsEmpty` "Add foods you'd like to keep off your plate, with your own reason.", `avoidFoodAdd` "Add a food", `avoidFoodEdit` "Edit food", `avoidFoodName` "Food", `avoidFoodReason` "Reason (optional)", `avoidFoodReasonHint` "e.g. doctor's advice", `avoidFoodDelete` "Remove".

- [ ] **Step 1: Failing widget test**

```dart
  testWidgets('foods I avoid: add with a reason, edit, remove', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Nutrition'), 200);
    await tester.ensureVisible(find.text('Nutrition'));
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(find.text('Foods I avoid'), findsOneWidget);
    await tester.tap(find.text('Add a food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Papaya');
    await tester.enterText(find.byType(TextField).at(1), "doctor's advice");
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Papaya'), findsOneWidget);
    expect(find.text("doctor's advice"), findsOneWidget);
    await tester.tap(find.text('Papaya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Papaya'), findsNothing);
  });
```

- [ ] **Step 2: Run, expect failure.** `flutter test test/features/nutrition/nutrition_screens_test.dart`. Expected: FAIL ("Nutrition" not found).

- [ ] **Step 3: Implement.**
  - Screen: `Scaffold` + back button + `Semantics(header: true)` title `nutritionTitle`. A section header `avoidFoodsTitle` (`Semantics(header: true)`). A `Card` list of foods (name in `bodyLarge`, reason in `bodySmall`, tap to edit), or the empty line. A `FilledButton.tonal` "Add a food".
  - `_AvoidFoodDialog`: a `StatefulWidget` that owns two controllers. Title in `Semantics(header: true)`. Fields name (single line, 60 characters) and reason (single line, 120 characters, hint `avoidFoodReasonHint`). Actions: Back, Save, and when editing, a `TextButton` "Remove" coloured `scheme.error` (a destructive action). It returns a sealed result `(name, reason)` or `remove`. The screen calls `save` / `delete`.
  - Care tile: a `_ToolTile`-style tile labelled `nutritionTitle` with the boards' icon, pushing `/care/nutrition`.
  - Route `GoRoute(path: 'nutrition', builder: (_, _) => const NutritionScreen())`.
  - Add `'nutrition'` and `'avoidFood'` to the content test's hard-line prefixes.

- [ ] **Step 4: Run.** `flutter test test/features/nutrition test/core/content && flutter analyze`. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "feat(nutrition): foods I avoid on Care → Nutrition"
```

### Task 7: Hospital bag and its reminder

**Files:**
- Create: `lib/features/birth_prep/presentation/bag_screen.dart`
- Create: `lib/features/birth_prep/domain/bag_reminder.dart`
- Modify: `lib/core/db/settings_repository.dart` (`SettingKeys.bagRemindAt`)
- Modify: `lib/core/reminders/reminder_settings.dart` (`bagAt` field, `fromSettings`, `_fields`)
- Modify: `lib/app/reminders.dart` (add `bagCandidates` when a pregnancy is active)
- Modify: `lib/app/router.dart` (`/care/bag`), `lib/l10n/app_en.arb`
- Create: `test/features/birth_prep/bag_reminder_test.dart`, `test/features/birth_prep/birth_prep_screens_test.dart`

**Interfaces:**
- Consumes: `bagProvider`, `bagRepositoryProvider`, `ReminderCandidate`, `ReminderKind.careItem`, `settingsRepositoryProvider.put/remove`.
- Produces:
  - `SettingKeys.bagRemindAt = 'bag_remind_at'` (local ISO `yyyy-MM-ddTHH:mm`)
  - `ReminderSettings.bagAt` (`DateTime?`)
  - `List<ReminderCandidate> bagCandidates({required DateTime now, required DateTime? at, required AppLocalizations l10n})`
  - arb keys:
    - Screen: `bagTitle` "Hospital bag", `bagForMe` "For me", `bagForBaby` "For baby", `bagDocuments` "Documents", `bagAddOwn` "Add your own", `bagOwnName` "Item", `bagPacked` "{packed} of {total} packed", `bagDelete` "Remove".
    - Reminder: `bagRemind` "Remind me to pack", `bagRemindOff` "No reminder", `bagRemindAt` "{date} at {time}", `bagRemindClear` "Clear reminder", `reminderBagTitle` "Pack the hospital bag", `reminderBagBody` "A gentle reminder you set."

- [ ] **Step 1: Failing planner test** `bag_reminder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/features/birth_prep/domain/bag_reminder.dart';
import 'package:navmaas/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final now = DateTime(2026, 10, 5, 9);

  test('one reminder at the time she chose', () {
    final c = bagCandidates(now: now, at: DateTime(2026, 11, 1, 10), l10n: l10n);
    expect(c.single.at, DateTime(2026, 11, 1, 10));
    expect(c.single.kind, ReminderKind.careItem);
    expect(c.single.title, 'Pack the hospital bag');
  });

  test('none when unset or already past', () {
    expect(bagCandidates(now: now, at: null, l10n: l10n), isEmpty);
    expect(bagCandidates(now: now, at: DateTime(2026, 10, 4, 10), l10n: l10n), isEmpty);
  });

  test('held to the end of quiet hours like any reminder', () {
    final planned = planReminders(
      now: now,
      settings: ReminderSettings.fromSettings({'reminders_on': 'true'}),
      candidates: bagCandidates(now: now, at: DateTime(2026, 10, 6, 23), l10n: l10n),
    );
    expect(planned.single.at.hour, isNot(23));
  });
}
```

Check `planner.dart` for how quiet hours treat non-nudges: whether they're moved to the quiet end or dropped. Then set the last expectation to the planner's actual rule (e.g. `DateTime(2026, 10, 7, 7)`) and import `reminder_settings.dart`.

- [ ] **Step 2: Run, expect failure** (missing `bag_reminder.dart`).

- [ ] **Step 3: Implement** `lib/features/birth_prep/domain/bag_reminder.dart`:

```dart
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The one-off "Pack the hospital bag" reminder she set (M8a), if still ahead.
List<ReminderCandidate> bagCandidates({
  required DateTime now,
  required DateTime? at,
  required AppLocalizations l10n,
}) => [
  if (at != null && at.isAfter(now))
    ReminderCandidate(
      key: 'bag:${at.toIso8601String()}',
      at: at,
      kind: ReminderKind.careItem,
      title: l10n.reminderBagTitle,
      body: l10n.reminderBagBody,
    ),
];
```

Then:
- In `reminder_settings.dart`, add `final DateTime? bagAt;`, parsed in `fromSettings` with `DateTime.tryParse(s[SettingKeys.bagRemindAt] ?? '')`, and add `bagAt` to `_fields`.
- In `ReminderSync._run`, add inside the candidates list:

```dart
        if (pregnancy != null)
          ...bagCandidates(now: now, at: settings.bagAt, l10n: _l10n),
```

- [ ] **Step 4: Failing screen test** `birth_prep_screens_test.dart`:

```dart
  testWidgets('hospital bag: tick, add her own, reminder', (tester) async {
    final scheduler = FakeScheduler();
    await pumpApp(tester, scheduler: scheduler);
    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hospital bag'), 200);
    await tester.ensureVisible(find.text('Hospital bag'));
    await tester.tap(find.text('Hospital bag'));
    await tester.pumpAndSettle();
    expect(find.text('0 of ${_bagCount()} packed'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1 of ${_bagCount()} packed'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Add your own'), 200);
    await tester.tap(find.text('Add your own'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Phone charger');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Phone charger'), findsOneWidget);
  });
```

Here `_bagCount()` is `parseHospitalBag(File('assets/content/hospital_bag.json').readAsStringSync()).length`. The reminder row (date and time pickers) is exercised in the accessibility test (Task 9). Its setting → planner path is covered by Step 1.

- [ ] **Step 5: Implement the screen.**
  - `Scaffold` + back + `Semantics(header: true)` `bagTitle`, then the `bagPacked` count line.
  - Three sections, each with a `Semantics(header: true)` title. Rows are `CheckboxListTile`s (48 dp; the label is the item). Her own items have a trailing remove button (`NmIcon` + tooltip `bagDelete`, `Semantics` label).
  - "Add your own" opens a dialog that owns its controller: a section picker (`PillSegmented` with the three sections) and the name.
  - The reminder row shows `bagRemindOff` or `bagRemindAt(formatShortDate, formatMinuteOfDay)`. Tapping it opens `showDatePicker` then `showTimePicker`, and writes `SettingKeys.bagRemindAt`. A "Clear reminder" button removes the key.
  - Route `GoRoute(path: 'bag', builder: (_, _) => const BagScreen())`.
  - Add `'bag'` and `'reminderBag'` to the content test's hard-line prefixes.

- [ ] **Step 6: Run.** `flutter test test/features/birth_prep test/core/reminders test/core/content && flutter analyze`. Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat(birth-prep): hospital bag with ticks, her own items and a reminder"
```

### Task 8: Birth plan

**Files:**
- Create: `lib/features/birth_prep/presentation/birth_plan_screen.dart`
- Modify: `lib/app/router.dart` (`/care/birth-plan`), `lib/l10n/app_en.arb`
- Modify: `test/features/birth_prep/birth_prep_screens_test.dart`, `test/core/content/content_pack_test.dart`

**Interfaces:**
- Consumes: `birthPlanPromptsProvider`, `birthPlanAnswersProvider`, `birthPlanRepositoryProvider`, `TextEntryDialog` from `care_widgets.dart`.
- Produces: `BirthPlanScreen` at `/care/birth-plan`, and arb keys `birthPlanTitle` "Birth plan", `birthPlanDoctorLine` "Talk this through with your doctor.", `birthPlanEmptyAnswer` "Add your thoughts".

- [ ] **Step 1: Failing test**

```dart
  testWidgets('birth plan: answer a prompt, edit it', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Birth plan'), 200);
    await tester.ensureVisible(find.text('Birth plan'));
    await tester.tap(find.text('Birth plan'));
    await tester.pumpAndSettle();
    expect(find.text('Talk this through with your doctor.'), findsOneWidget);
    final first = parseBirthPlan(
      File('assets/content/birth_plan.json').readAsStringSync(),
    ).first;
    await tester.tap(find.text(first.title));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My mum and my husband');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('My mum and my husband'), findsOneWidget);
  });
```

- [ ] **Step 2: Run, expect failure.**

- [ ] **Step 3: Implement.**
  - `Scaffold` + back + `Semantics(header: true)` `birthPlanTitle`, then `birthPlanDoctorLine` in a quiet card.
  - One `Card` per prompt with the title (`titleSmall`), the hint (`bodySmall`, `onSurfaceVariant`) and the answer (or `birthPlanEmptyAnswer` in `outline` colour). Tapping opens `TextEntryDialog(title: prompt.title, initial: answer)`. Its `AlertDialog` title must be a heading: if `TextEntryDialog` lacks `Semantics(header: true)`, add it there, which fixes all its uses.
  - Saves through `birthPlanRepositoryProvider.save`.
  - Route `GoRoute(path: 'birth-plan', builder: (_, _) => const BirthPlanScreen())`.
  - Add `'birthPlan'` to the hard-line prefixes.

- [ ] **Step 4: Run.** `flutter test test/features/birth_prep test/core/content && flutter analyze`. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "feat(birth-prep): birth plan in her own words"
```

### Task 9: Care layout, accessibility and goldens

**Files:**
- Modify: `lib/features/care/presentation/care_screen.dart` ("Getting ready" row from week 28 and its lower placement before, per boards)
- Modify: `lib/core/theme/navmaas_icons.dart` (new icons from the boards, if any)
- Modify: `test/accessibility_test.dart` (`_screens` entries + seed data)
- Modify: `test/goldens/screens_golden_test.dart` (new screens, light and dark, 1.0× and 2.0×)
- Generated: `test/goldens/macos/*.png`; Linux via CI artifact

**Interfaces:**
- Consumes: everything above. `currentWeek` (or however `TodayScreen` reads the pregnancy week) from `lib/core/pregnancy`.

- [ ] **Step 1: Week-28 placement.**
  - From week 28 on, the "Getting ready" row (two `_ToolTile`s: Hospital bag, Birth plan) shows under the kick/contraction row.
  - Before week 28, the same two entries sit at the end of Care under a `Semantics(header: true)` "Getting ready" title.
  - Widget test: `pumpApp` with a pregnancy at week 20 (seed LMP) shows them at the end; at week 30 they're near the top. Use `tester.getTopLeft` to compare against the Vitals header.

- [ ] **Step 2: Accessibility entries.**
  - Add `_screens` entries for: Blood sugar list, blood-sugar dialog, Nutrition (empty and filled), avoid-food dialog, Hospital bag, the bag "Add your own" dialog, Birth plan, and its edit dialog.
  - Seed one reading, one food, one tick and one answer in the existing seed function.
  - Run: `flutter test test/accessibility_test.dart`. Expected: PASS at 1.0×, 1.3× and 2.0×, with headings, 48 dp and labels.

- [ ] **Step 3: Goldens.** Add cases for Blood sugar, Nutrition, Hospital bag and Birth plan, following the `letters $name` pattern.

Run: `flutter test test/goldens --update-goldens`. Then inspect each new PNG against the Task 2 boards, and run `flutter test test/goldens` (expect PASS).

- [ ] **Step 4: Full suite.** `dart format --set-exit-if-changed . && flutter analyze && flutter test`. Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "test: accessibility and goldens for birth prep screens"
```

### Task 10: Docs, version, verification and PR

**Files:**
- Modify: `docs/PLAN.md`
  - New decision rows from spec §7: Nourishly link, sharing off by default and 90 days, six totals, M8a/M8b split, `meal_note` dropped.
  - Status line and the feature map rows for Vitals, Third-trimester tools and Nutrition.
- Modify: `docs/ARCHITECTURE.md`
  - §8 data model: v12 columns and tables.
  - §15: M8 scope rewritten to the spec, with M8a status and M8b pending.
  - §17: ADR 061 "Nutrition comes from Nourishly through a share file; Navmaas stores none" (recorded now, built in M8b) and ADR 062 "Hospital-bag ticks keyed by template key".
  - The milestone table's Schema column: M8 = v12.
- Modify: `docs/DESIGN_SYSTEM.md` line 6 (new boards) and §8 (any prototype differences).
- Modify: `CLAUDE.md` folder conventions:
  - `nutrition/`: Foods I avoid; M8b adds the Nourishly section.
  - `birth_prep/`: the bag (`mergeBag`, template keys) and the birth plan.
  - The content-pack list gains `hospital_bag.json` and `birth_plan.json`.
  - The content hard-line note covers the new packs.
- Modify: `README.md` if it lists features.
- Modify: `pubspec.yaml` `version: 1.3.0+5` and `appVersion = '1.3.0'`.
- Modify: `~/.claude/…/memory/navmaas-milestone-status.md` (M8a built, PR number).

- [ ] **Step 1: Docs and version** as listed. Then `grep -rn "meal note\|meal_note" docs README.md CLAUDE.md` and fix or remove every stale mention.

- [ ] **Step 2: Definition of done, with evidence**

```sh
dart format --set-exit-if-changed . && flutter analyze && flutter test
flutter build apk --release --target-platform android-arm,android-arm64
# Release manifest: no INTERNET
grep -c "android.permission.INTERNET" build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml || true
flutter build ios --release --no-codesign
```

Expected:
- Everything green.
- APK under 100 MB.
- The `INTERNET` count is `0`. Check the merged manifest path under `build/app/intermediates`; it varies by AGP version.
- iOS compiles.
- The DB stays encrypted: `test/core/db/database_test.dart` already asserts it. Cite it.

- [ ] **Step 3: Push and PR**

```bash
git push -u origin feat/m8a-body-birth-prep
gh pr create --title "feat: blood sugar, foods I avoid, hospital bag and birth plan" --body "…summary, test evidence, owner phone checks…

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

After CI: if goldens fail on Linux, `gh run download <run-id> -n linux-goldens -D test/goldens/linux`, then commit and push.

- [ ] **Step 4: Owner phone checks** (list in the PR):
  - Bag reminder fires at the chosen time and is held in quiet hours.
  - Ticks survive an app restart.
  - The blood-sugar keyboard is numeric.
  - A backup made on 1.3.0 restores.
