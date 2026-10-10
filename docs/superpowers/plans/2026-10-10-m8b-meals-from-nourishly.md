# M8b Meals from Nourishly — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Navmaas 1.4.0. Care → Nutrition shows the meals and six day totals she logged in Nourishly, read from Nourishly's share file. The Care tile says "Today: N meals from Nourishly". Navmaas stores none of it.

**Architecture:**
- **Platform adapter** `lib/core/platform/nourishly.dart`: `NourishlySource.readShare() → String?` over channel `navmaas/nourishly`.
  - Android: Kotlin reads `content://com.nourishly.app.nourishly.share/navmaas`.
  - iPhone: Swift reads `share/nourishly-share.json` in App Group `group.com.patelkeyur.share`.
  - Either returns `null` when Nourishly isn't there, sharing is off, or permission is missing.
- **Pure-Dart parser** `lib/features/nutrition/domain/nourishly_share.dart`: `parseNourishlyShare(String) → NourishlyShare?`. A `null` result means "can't read".
- **One provider**, `nourishlyShareProvider`, returns `Future<NourishlyShare?>`. Its `AsyncValue` states:
  - `data(null)`: not shared.
  - `data(share)`: shared.
  - `error`: unreadable.
  - It is re-read on app resume (`app.dart`) and when Nutrition opens.
- **Nutrition screen:** a "From Nourishly" section above Foods I avoid. It has a 7-day strip and a meals card.

**Tech Stack:** Flutter, Riverpod 3 codegen, gen-l10n, `intl` (already a dependency), Kotlin, Swift. No new packages.

**Spec:** `docs/superpowers/specs/2026-10-10-m8-body-birth-prep-design.md` §6.1 and §6.3. Nourishly's side of the contract is in nourishly `docs/navmaas-share.md` (v1, merged and released as Nourishly v1.2.0).

## Global Constraints

- **Branch, PR and version:**
  - Branch `feat/m8b-meals-from-nourishly` from `main`. PR title `feat: meals from Nourishly`.
  - Version `1.4.0+6` in `pubspec.yaml` and `appVersion` in `backup_service.dart` (a test checks they match).
  - Never merge it myself.
- **Nothing stored:** no table, no setting, no backup change, no schema bump. Nourishly stays the source of truth.
- **Values only:**
  - Plain numbers with units.
  - No targets, %, scores, colours, "high/low" or food advice.
  - Nothing red: the unreadable state uses `amberSoft` / `onAmberSoft`.
- **Words:** every string in `app_en.arb` under the `nourishly` prefix (plus `nutritionTodayMeals`). The hard-line ARB word check covers the prefix.
  - Unit strings (`nourishlyUnit*`) are exempt, as `mg/dL` is: "mg" is a food amount here, not a dose.
- **Never** `DateTime.now()` in `lib/` (`clockNow()` / `todayProvider`). Never Material `Icons` (`NmIcon(NavmaasIcon.…)`). Never hard-coded colours.
- **Accessibility:**
  - ≥ 48 dp targets, with a tooltip or `Semantics` on the icon-only arrows.
  - A `Semantics(header: true)` heading on the section.
  - No overflow at 1.0×, 1.3× and 2.0×.
  - New states go in `test/accessibility_test.dart`.
- **Retry off:** `nourishlyShareProvider` sets `retry` to never. Riverpod 3 retries failed providers by default, which would leave timers pending in tests and keep re-reading a broken file.
- **Signature permission:** Navmaas declares `com.patelkeyur.permission.NOURISHLY_SHARE` (`signature`) itself, as well as using it, so install order doesn't matter (ADR 061).
- **iPhone groups:** the widget's App Group `group.com.patelkeyur.navmaas` stays untouched. Runner joins `group.com.patelkeyur.share` in addition.
- **After each task:** `dart format .`, `flutter analyze` (zero issues), the task's tests, then commit.
- **Docs** stay in sync in the same PR (Task 7).

## Review Focus

- **A file written by a newer Nourishly** (`version: 2`, or a renamed field) shows the amber "Couldn't read" state and never crashes. Unknown *extra* fields still parse. Tests in Task 1.
- **`generatedAt` precision and time zone:**
  - Precision: `…09:40+05:30`, `…09:40:00Z` and `…09:40:00.123456+05:30` all show "Updated 9:40 am".
  - Time zone: it reads the same on a UTC CI runner as on an IST Mac, because Navmaas shows the wall-clock time as written, not converted. Tests in Task 1 and Task 4.
- **A stale file:**
  - If Nourishly last wrote days ago, "Updated" must show the date, not just a time that reads as today. Test in Task 4.
  - If Nourishly is still writing when Navmaas resumes (race on switching apps), opening Nutrition reads again. Test in Task 4.
- **Partial or missing nutrients:**
  - Nourishly leaves out a nutrient with no data. The row simply has five totals, never "0".
  - A `partial` id with no total is ignored. Tests in Task 1 and Task 4.
- **Android without the permission** (the Nourishly APK signed with another key, or Nourishly missing): Kotlin returns `null`, and she sees "Turn on Share with Navmaas in Nourishly", not an error. That can't run in widget tests. It is covered by the owner's device check, the `adb` refusal (Task 7, PR checklist).

---

### Task 1: Parser for the share file (pure Dart)

**Files:**
- Create: `test/fixtures/nourishly-share-v1.sample.json` (a byte-for-byte copy of nourishly `packages/nourishly_data/test/fixtures/nourishly-share-v1.sample.json`)
- Create: `lib/features/nutrition/domain/nourishly_share.dart`
- Test: `test/features/nutrition/nourishly_share_test.dart`

**Interfaces:**
- Produces:
  - `class NourishlyShare { DateTime generatedAt; List<NourishlyDay> days; NourishlyDay? day(DateTime date); }`. `generatedAt` is the wall-clock time as written, as a local `DateTime`.
  - `class NourishlyDay { DateTime date; List<NourishlyMeal> meals; Map<String, num> totals; Set<String> partial; }`. `date` is UTC midnight, as `dateOnly`.
  - `class NourishlyMeal { String slot; List<NourishlyItem> items; }`
  - `typedef NourishlyItem = ({String name, String amount});`
  - `const nourishlyNutrients = ['energy', 'protein', 'iron', 'calcium', 'folate', 'fibre'];`
  - `NourishlyShare? parseNourishlyShare(String text)`
  - `String formatNutrient(num value)`. Examples: 1120 → `1,120`, 4.6 → `4.6`, 310.0 → `310`.

- [ ] **Step 1: Copy the fixture**

```bash
mkdir -p test/fixtures
cp ../nourishly/packages/nourishly_data/test/fixtures/nourishly-share-v1.sample.json test/fixtures/
```

- [ ] **Step 2: Write the failing tests**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/features/nutrition/domain/nourishly_share.dart';

Map<String, Object?> _base() =>
    jsonDecode(
          File('test/fixtures/nourishly-share-v1.sample.json').readAsStringSync(),
        )
        as Map<String, Object?>;

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
    expect(share.day(DateTime.utc(2026, 10, 10))!.totals.containsKey('folate'), isFalse);
    expect(share.day(DateTime.utc(2026, 10, 8)), isNull);
  });

  test('any ISO-8601 precision; shown as written, never converted', () {
    for (final at in [
      '2026-10-10T09:40+05:30',
      '2026-10-10T09:40:00Z',
      '2026-10-10T09:40:00.123456+05:30',
    ]) {
      expect(_parse(_base()..['generatedAt'] = at)!.generatedAt,
          DateTime(2026, 10, 10, 9, 40), reason: at);
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
    (((((noName['days']! as List)[0] as Map)['meals'] as List)[0]
            as Map)['items'] as List)[0]
        .remove('name');
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
```

- [ ] **Step 3: Run them and watch them fail**

Run: `flutter test test/features/nutrition/nourishly_share_test.dart`
Expected: FAIL. Compilation error, because `nourishly_share.dart` doesn't exist.

- [ ] **Step 4: Implement**

```dart
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
      days: [
        for (final d in json['days']! as List<Object?>) _day(d! as Map),
      ],
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
      for (final meal in d['meals']! as List<Object?>)
        NourishlyMeal(
          slot: (meal! as Map)['slot']! as String,
          items: [
            for (final i in meal['items']! as List<Object?>)
              (
                name: (i! as Map)['name']! as String,
                amount: i['amount']! as String,
              ),
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
```

Note: `json['version'] != 1` is true for `1.0` too, since Dart `1.0 == 1` holds for `num`. A missing version is `null`, which is unreadable.

- [ ] **Step 5: Run the tests and watch them pass**

Run: `flutter test test/features/nutrition/nourishly_share_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 6: Commit**

```bash
dart format . && flutter analyze
git add test/fixtures/nourishly-share-v1.sample.json lib/features/nutrition/domain/nourishly_share.dart test/features/nutrition/nourishly_share_test.dart
git commit -m "feat(nutrition): read Nourishly's share file (v1)"
```

---

### Task 2: Prototype board (GATE: owner approves)

**Files:** the prototype artifact `https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8`. Read it first with `Artifact action: read`, then republish to the same URL.

- [ ] **Step 1: Read the existing boards.** Read the prototype and its M8a Nutrition board. That board has a greyed "M8b: From Nourishly" placeholder.
- [ ] **Step 2: Replace the placeholder with real boards, in light and dark:**
  1. **Nutrition, shared.** Under the "From Nourishly" heading:
     - The 7-day strip: weekday letter plus day number. A small dot marks a day with meals, and today has a ring. ‹ and › move a week.
     - The selected day's card:
       - Each meal slot, with its items and amounts.
       - A "Day totals" row: Energy 1,120 kcal, Protein 38.2 g, Iron 9.4 mg, Calcium 310 mg, Folate 180 µg, Fibre 21.5 g.
       - The note "Folate: some foods had no data".
       - "Updated 9:40 am".
     - Foods I avoid below.
  2. **Nutrition, empty day:** "No meals from Nourishly for this day".
  3. **Nutrition, not shared:** "Turn on Share with Navmaas in Nourishly".
  4. **Nutrition, unreadable:** an amber card reading "Couldn't read Nourishly's data. Open Nourishly once, then come back."
  5. **Care's Nutrition tile:** "Today: 2 meals from Nourishly".
- [ ] **Step 3: Publish** to the same URL.
- [ ] **Step 4: GATE.** The owner approves the boards. Their placement and wording decisions feed Tasks 4–6. Any wording change goes into the ARB list in Task 4.

---

### Task 3: Platform adapter, Android and iPhone readers

**Files:**
- Create: `lib/core/platform/nourishly.dart` (+ generated `nourishly.g.dart`)
- Create: `android/app/src/main/kotlin/com/patelkeyur/navmaas/NourishlyShare.kt`
- Modify: `android/app/src/main/kotlin/com/patelkeyur/navmaas/MainActivity.kt`, `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/AppDelegate.swift`, `ios/Runner/Runner.entitlements`
- Modify: `test/helpers.dart` (`FakeNourishly`, `pumpApp(nourishly:)`, `nourishlyJson()`)
- Modify: `.github/workflows/ci.yml` (permission check on the release APK)

**Interfaces:**
- Produces:
  - `abstract interface class NourishlySource { Future<String?> readShare(); }`
  - `class ChannelNourishly implements NourishlySource`
  - `@Riverpod(keepAlive: true) NourishlySource nourishlySource(Ref ref) => ChannelNourishly();`
  - Test side:
    - `class FakeNourishly implements NourishlySource { new([this.text]); String? text; Object? error; int reads; }`
    - `pumpApp(…, FakeNourishly? nourishly)`. It defaults to `FakeNourishly()`, which is not shared.
    - `String nourishlyJson({int version = 1})`: a share for `testToday` (2026-10-05) and the day before.

- [ ] **Step 1: Dart adapter**

```dart
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nourishly.g.dart';

/// Nourishly's share file (ADR 061), as text: through `navmaas/nourishly`
/// (`NourishlyShare.kt`, `AppDelegate.swift`). Null when Nourishly isn't
/// installed, sharing is off, or Navmaas may not read it. Faked in tests.
abstract interface class NourishlySource {
  Future<String?> readShare();
}

class ChannelNourishly implements NourishlySource {
  static const _channel = MethodChannel('navmaas/nourishly');

  @override
  Future<String?> readShare() => _channel.invokeMethod<String>('readShare');
}

@Riverpod(keepAlive: true)
NourishlySource nourishlySource(Ref ref) => ChannelNourishly();
```

- [ ] **Step 2: Test fakes** in `test/helpers.dart`.
  - Add `FakeNourishly` next to `FakeAppUsage`.
  - Add the `nourishly` parameter, and the override `nourishlySourceProvider.overrideWithValue(nourishly ?? FakeNourishly())`.
  - Add `nourishlyJson`.

```dart
/// Nourishly's share file as the platform would hand it over.
class FakeNourishly implements NourishlySource {
  new([this.text]);

  /// Null: not shared.
  String? text;

  /// Thrown instead, like a platform error.
  Object? error;
  int reads = 0;

  @override
  Future<String?> readShare() async {
    reads++;
    if (error case final e?) throw e;
    return text;
  }
}

/// A share file (version 1) for [testToday] and the day before, written at
/// 8:40 that morning.
String nourishlyJson({int version = 1}) => jsonEncode({
  'format': 'nourishly-share',
  'version': version,
  'generatedAt': '2026-10-05T08:40:00.000+05:30',
  'days': [
    {
      'date': '2026-10-05',
      'meals': [
        {
          'slot': 'Breakfast',
          'items': [
            {'name': 'Poha', 'amount': '1 katori · 150 g'},
          ],
        },
      ],
      'totals': {
        'energy': 245,
        'protein': 4.6,
        'iron': 2.1,
        'calcium': 18,
        'fibre': 2.4,
      },
      'partial': <String>[],
    },
    {
      'date': '2026-10-04',
      'meals': [
        {
          'slot': 'Lunch',
          'items': [
            {'name': 'Dal tadka', 'amount': '1 katori · 150 g'},
            {'name': 'Phulka', 'amount': '2 × 1 piece · 60 g'},
          ],
        },
        {
          'slot': 'Dinner',
          'items': [
            {'name': 'Khichdi', 'amount': '1 bowl · 250 g'},
          ],
        },
      ],
      'totals': {
        'energy': 1120,
        'protein': 38.2,
        'iron': 9.4,
        'calcium': 310.0,
        'folate': 180,
        'fibre': 21.5,
      },
      'partial': ['folate'],
    },
  ],
});
```

- [ ] **Step 3: Android reader.** Create `NourishlyShare.kt`:

```kotlin
package com.patelkeyur.navmaas

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Reads Nourishly's share file (M8b, ADR 061) from its read-only provider.
 * Only apps holding com.patelkeyur.permission.NOURISHLY_SHARE get in, a
 * signature permission: both apps are signed with the owner's key (ADR 060).
 * Nourishly not installed, sharing off, or no permission: null.
 */
object NourishlyShare {
    private val uri = Uri.parse("content://com.nourishly.app.nourishly.share/navmaas")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "navmaas/nourishly").setMethodCallHandler { call, result ->
            if (call.method != "readShare") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            io.execute {
                // FileNotFoundException (no provider, no file) and
                // SecurityException (no permission) both mean "not shared".
                val text = try {
                    context.contentResolver.openInputStream(uri)
                        ?.bufferedReader()
                        ?.use { it.readText() }
                } catch (e: Exception) {
                    null
                }
                main.post { result.success(text) }
            }
        }
    }
}
```

In `MainActivity.configureFlutterEngine`, after `AppUsage.register(...)`:

```kotlin
        // Meals from Nourishly (M8b).
        NourishlyShare.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
```

- [ ] **Step 4: Android manifest.**
  - After the `RECORD_AUDIO` permission, add:

```xml
    <!-- Meals from Nourishly (M8b, ADR 061): its share file is readable only
         with this signature permission, so only by apps signed with the
         owner's key. Navmaas declares it too, so install order doesn't matter. -->
    <permission
        android:name="com.patelkeyur.permission.NOURISHLY_SHARE"
        android:protectionLevel="signature" />
    <uses-permission android:name="com.patelkeyur.permission.NOURISHLY_SHARE" />
```

  - Inside the existing `<queries>` element (line 124), add:

```xml
        <!-- Meals from Nourishly (M8b): Android 11+ hides other apps' providers. -->
        <provider android:authorities="com.nourishly.app.nourishly.share" />
```

- [ ] **Step 5: iPhone reader.**
  - In `Runner.entitlements`, add `<string>group.com.patelkeyur.share</string>` to the `com.apple.security.application-groups` array.
  - Change that block's comment to say: "Home-screen widget: the snapshot it shows; Nourishly: the meals it shares (M8b). Both work with a free Apple ID."
  - In `AppDelegate.swift`, at the end of `didInitializeImplicitFlutterEngine`, add:

```swift
    // Meals from Nourishly (M8b, ADR 061): its share file, in the App Group
    // both apps join under the owner's team. Not there: nil.
    let nourishly = engineBridge.pluginRegistry.registrar(forPlugin: "NavmaasNourishly")!
    FlutterMethodChannel(name: "navmaas/nourishly", binaryMessenger: nourishly.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "readShare" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let file = FileManager.default
          .containerURL(forSecurityApplicationGroupIdentifier: "group.com.patelkeyur.share")?
          .appendingPathComponent("share/nourishly-share.json")
        result(file.flatMap { try? String(contentsOf: $0, encoding: .utf8) })
      }
```

- [ ] **Step 6: CI check on the release APK.** In `ci.yml`, after "Show the APK's signing certificate", add this step.
  - Use `if` rather than `! grep`, because bash's `-e` ignores a negated command.

```yaml
      # No network in release (ARCHITECTURE §13), and Nourishly's read
      # permission is there (M8b).
      - name: Check the APK's permissions
        run: |
          tools="$ANDROID_HOME/build-tools/$(ls "$ANDROID_HOME/build-tools" | sort -V | tail -1)"
          perms=$("$tools/aapt2" dump permissions build/app/outputs/flutter-apk/app-release.apk)
          echo "$perms"
          if grep -q "android.permission.INTERNET" <<<"$perms"; then
            echo "The release APK asks for INTERNET"; exit 1
          fi
          grep -q "com.patelkeyur.permission.NOURISHLY_SHARE" <<<"$perms"
```

- [ ] **Step 7: Verify.**
  - `dart run build_runner build`, then `dart format .` and `flutter analyze`. Expected: zero issues.
  - `flutter test`. Expected: all pass (no behaviour has changed yet).
  - `flutter build apk --release --target-platform android-arm,android-arm64`, then run the Step 6 script locally with `$ANDROID_HOME`. Expected:
    - It lists `com.patelkeyur.permission.NOURISHLY_SHARE`.
    - It has no `android.permission.INTERNET` line.
  - `flutter build ios --release --no-codesign`. Expected: builds.
- [ ] **Step 8: Commit**

```bash
git add lib/core/platform/nourishly.dart lib/core/platform/nourishly.g.dart android ios/Runner/AppDelegate.swift ios/Runner/Runner.entitlements test/helpers.dart .github/workflows/ci.yml
git commit -m "feat(platform): read Nourishly's share file on Android and iPhone"
```

---

### Task 4: "From Nourishly" on Care → Nutrition

**Files:**
- Create: `lib/features/nutrition/data/nourishly_meals.dart` (+ `.g.dart`)
- Create: `lib/features/nutrition/presentation/nourishly_section.dart`
- Modify: `lib/features/nutrition/presentation/nutrition_screen.dart`, `lib/app/app.dart`
- Modify: `lib/l10n/app_en.arb`, `test/core/content/content_pack_test.dart`
- Test: `test/features/nutrition/nourishly_section_test.dart`

**Interfaces:**
- Consumes: `parseNourishlyShare`, `NourishlyShare`, `formatNutrient`, `nourishlyNutrients` (Task 1); `nourishlySourceProvider`, `FakeNourishly`, `nourishlyJson` (Task 3).
- Produces: `@Riverpod(retry: _never) Future<NourishlyShare?> nourishlyShare(Ref ref)`. Its states are `data(null)` for not shared, `data(share)` for shared, and `error` for unreadable.

- [ ] **Step 1: Words.** Add to `app_en.arb` after the `avoidFood*` keys. Use the owner's board wording from Task 2 if it differs.

```json
  "nutritionTodayMeals": "{count, plural, =1{Today: 1 meal from Nourishly} other{Today: {count} meals from Nourishly}}",
  "@nutritionTodayMeals": {"placeholders": {"count": {"type": "int"}}},
  "nourishlyTitle": "From Nourishly",
  "nourishlyNotShared": "Turn on Share with Navmaas in Nourishly",
  "nourishlyNoMeals": "No meals from Nourishly for this day",
  "nourishlyUnreadable": "Couldn't read Nourishly's data. Open Nourishly once, then come back.",
  "nourishlyUpdated": "Updated {when}",
  "@nourishlyUpdated": {"placeholders": {"when": {"type": "String"}}},
  "nourishlyTotals": "Day totals",
  "nourishlyPartial": "{nutrients}: some foods had no data",
  "@nourishlyPartial": {"placeholders": {"nutrients": {"type": "String"}}},
  "nourishlyEarlier": "Earlier days",
  "nourishlyLater": "Later days",
  "nourishlyEnergy": "Energy",
  "nourishlyProtein": "Protein",
  "nourishlyIron": "Iron",
  "nourishlyCalcium": "Calcium",
  "nourishlyFolate": "Folate",
  "nourishlyFibre": "Fibre",
  "nourishlyUnitKcal": "kcal",
  "nourishlyUnitG": "g",
  "nourishlyUnitMg": "mg",
  "nourishlyUnitUg": "µg",
```

- [ ] **Step 2: Content test.** In the ARB word check (`content_pack_test.dart` ~line 245):
  - Add `'nourishly'` to `prefixes`.
  - Skip unit keys, by changing the `if` to `if (!key.startsWith('@') && !key.startsWith('nourishlyUnit') && prefixes.any(key.startsWith))`.
  - Extend the comment: "Nourishly's unit strings (`nourishlyUnit*`) are measurements of food, not doses."
  - Run: `flutter test test/core/content/content_pack_test.dart`. Expected: PASS.
  - Then, as a check, temporarily rename `nourishlyUnitMg` to `nourishlyMg`. Expected: FAIL on `mg`. Revert.

- [ ] **Step 3: Write the failing widget tests** in `test/features/nutrition/nourishly_section_test.dart`. `testToday` is Monday 5 Oct 2026, so the strip shows Tue 29 Sep to Mon 5 Oct.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';

import '../../helpers.dart';

Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

Future<void> _care(WidgetTester tester, FakeNourishly nourishly) async {
  await pumpApp(tester, seed: _seed, nourishly: nourishly);
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text('Care')),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Nutrition'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text('Nutrition'));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, FakeNourishly nourishly) async {
  await _care(tester, nourishly);
  await tester.tap(find.text('Nutrition'));
  await tester.pumpAndSettle();
}

Future<void> _resume(WidgetTester tester) async {
  [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ].forEach(tester.binding.handleAppLifecycleStateChanged);
  await tester.pumpAndSettle();
}

Future<void> _day(WidgetTester tester, String date) async {
  await tester.tap(find.byKey(ValueKey('nourishly-day-$date')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('not shared', (tester) async {
    await _open(tester, FakeNourishly());
    expect(find.text('From Nourishly'), findsOneWidget);
    expect(find.text('Turn on Share with Navmaas in Nourishly'), findsOneWidget);
    expect(find.text('Foods I avoid'), findsOneWidget);
  });

  testWidgets("today's meals, totals as plain values, when it was updated", (
    tester,
  ) async {
    await _open(tester, FakeNourishly(nourishlyJson()));
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Poha'), findsOneWidget);
    expect(find.text('1 katori · 150 g'), findsOneWidget);
    expect(find.text('245 kcal'), findsOneWidget);
    expect(find.text('4.6 g'), findsOneWidget);
    // No folate that day: left out, never "0".
    expect(find.text('Folate'), findsNothing);
    expect(find.text('Updated 8:40 am'), findsOneWidget);
  });

  testWidgets('another day, with a partial total; a day with nothing', (
    tester,
  ) async {
    await _open(tester, FakeNourishly(nourishlyJson()));
    await _day(tester, '2026-10-04');
    expect(find.text('Dal tadka'), findsOneWidget);
    expect(find.text('2 × 1 piece · 60 g'), findsOneWidget);
    expect(find.text('1,120 kcal'), findsOneWidget);
    expect(find.text('310 mg'), findsOneWidget);
    expect(find.text('Folate: some foods had no data'), findsOneWidget);
    await _day(tester, '2026-10-03');
    expect(find.text('No meals from Nourishly for this day'), findsOneWidget);
  });

  testWidgets('earlier weeks; never past today', (tester) async {
    await _open(tester, FakeNourishly(nourishlyJson()));
    final later = find.byTooltip('Later days');
    expect(tester.widget<IconButton>(later).onPressed, isNull);
    await tester.tap(find.byTooltip('Earlier days'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nourishly-day-2026-09-22')), findsOneWidget);
    expect(find.byKey(const ValueKey('nourishly-day-2026-10-05')), findsNothing);
    expect(find.text('No meals from Nourishly for this day'), findsOneWidget);
    await tester.tap(later);
    await tester.pumpAndSettle();
    expect(find.text('Poha'), findsOneWidget);
  });

  testWidgets('an older file shows its date', (tester) async {
    await _open(
      tester,
      FakeNourishly(
        nourishlyJson().replaceFirst('2026-10-05T08:40', '2026-10-03T21:05'),
      ),
    );
    expect(find.text('Updated Sat, 3 Oct, 9:05 pm'), findsOneWidget);
  });

  testWidgets('unreadable: amber, never red', (tester) async {
    for (final fake in [
      FakeNourishly(nourishlyJson(version: 2)),
      FakeNourishly()..error = PlatformException(code: 'io'),
    ]) {
      await _open(tester, fake);
      const words =
          "Couldn't read Nourishly's data. Open Nourishly once, then come back.";
      expect(find.text(words), findsOneWidget);
      final context = tester.element(find.text(words));
      final scheme = Theme.of(context).colorScheme;
      final amber = Theme.of(context).extension<NavmaasColors>()!;
      expect(tester.widget<Text>(find.text(words)).style!.color, amber.onAmberSoft);
      expect(amber.onAmberSoft, isNot(scheme.error));
    }
  });

  testWidgets('reads again on resume and when Nutrition opens', (tester) async {
    final fake = FakeNourishly();
    await _open(tester, fake);
    expect(find.text('Turn on Share with Navmaas in Nourishly'), findsOneWidget);
    fake.text = nourishlyJson();
    await _resume(tester);
    expect(find.text('Poha'), findsOneWidget);
    final reads = fake.reads;
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(fake.reads, greaterThan(reads));
  });
}
```

Note: `_seed` and the tab tap copy `nutrition_screens_test.dart`. The pregnancy is at week 25 on `testToday`.

- [ ] **Step 4: Run them and watch them fail**

Run: `flutter test test/features/nutrition/nourishly_section_test.dart`
Expected: FAIL. "From Nourishly" is not found (and the provider doesn't exist yet).

- [ ] **Step 5: Provider** in `lib/features/nutrition/data/nourishly_meals.dart`:

```dart
import 'package:navmaas/core/platform/nourishly.dart';
import 'package:navmaas/features/nutrition/domain/nourishly_share.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nourishly_meals.g.dart';

Duration? _never(int retryCount, Object error) => null;

/// What Nourishly shares (M8b). Null: not shared; an error: there is a file
/// Navmaas can't read. Never stored. Re-read on resume (`app.dart`) and when
/// Nutrition opens; no automatic retry (a broken file stays broken).
@Riverpod(retry: _never)
Future<NourishlyShare?> nourishlyShare(Ref ref) async {
  final text = await ref.watch(nourishlySourceProvider).readShare();
  if (text == null) return null;
  return parseNourishlyShare(text) ??
      (throw const FormatException("Nourishly's share file"));
}
```

In `app.dart` `_onResume`, add `..invalidate(nourishlyShareProvider)` to the `ref` cascade, with a comment: "Nourishly may have written new meals while she was away."

- [ ] **Step 6: The section.** `nourishly_section.dart`, a `ConsumerStatefulWidget NourishlySection`:
  - **`initState`:** `Future.microtask(() => ref.invalidate(nourishlyShareProvider))`. This re-reads when Nutrition opens; Nourishly may still have been writing when Navmaas resumed.
  - **State:**
    - `_end`, the last day of the strip. It starts at `ref.read(todayProvider)`.
    - `_selected`, which starts at today.
    - ‹ sets `_end` back 7 days and selects it. › sets it forward 7 days, never past today, and selects it. › is disabled (`onPressed: null`) when `_end` is today.
    - Both arrows are `IconButton`s with `NmIcon(NavmaasIcon.chevronLeft/Right)`, a `tooltip` of `nourishlyEarlier` / `nourishlyLater`, and a 48 dp minimum.
  - **Layout:**
    - `Semantics(header: true)` "From Nourishly".
    - Then `switch (ref.watch(nourishlyShareProvider))`:
      - `AsyncData(value: null)`: `nourishlyNotShared` in `bodyMedium`.
      - `AsyncError()`: a `DecoratedBox` with `amberSoft` and radius 20, holding `nourishlyUnreadable` in `onAmberSoft`. Copy the `me_screen.dart` notice.
      - `AsyncData(value: final share?)`: the strip, then the day.
      - Loading with no value: `SizedBox.shrink()`.
  - **Strip:** a `Row` of 7 `Expanded` chips, `addDays(_end, -6 … 0)`.
    - Each chip is `InkWell`, `key: ValueKey('nourishly-day-${yyyy-MM-dd}')`, min 48 dp tall.
    - It shows `DateFormat('EEEEE')` over `d`.
    - Today has a ring. The selected chip has a `primaryContainer` fill. A small dot shows when `share.day(day)?.meals.isNotEmpty`.
    - `Semantics(container: true, selected: …, label: formatDate(day))`.
    - Text in `FittedBox`, as `_DayDot` does in `supplements_screen.dart`.
  - **Day card:**
    - No meals: `nourishlyNoMeals`.
    - Otherwise, for each meal: the slot in `titleSmall`, then each item as name (`bodyLarge` w700) with the amount below (`bodySmall`, `outline` colour).
    - Then the `nourishlyTotals` label and a `Wrap` (spacing 8) of `'${label} ${formatNutrient(v)} ${unit}'`. Only the nutrients in `day.totals`, in `nourishlyNutrients` order. The label and unit words come from a switch over the id.
    - Then, if `partial` is not empty, `nourishlyPartial(labels.join(', '))` in `bodySmall`.
  - **Under the card:** `nourishlyUpdated(when)`.
    - If `generatedAt` is today: `when = DateFormat('h:mm a').format(at).toLowerCase()`.
    - Otherwise: `'${formatShortDate(dateOnly(at))}, ${time}'`.
  - In `NutritionScreen`, insert `const NourishlySection()` and a 24 dp gap between the subtitle and "Foods I avoid".
  - Update the class doc to "M8b: the meals she logged in Nourishly above the list".

- [ ] **Step 7: Run the tests and watch them pass**

Run:
- `flutter test test/features/nutrition/`
- `flutter test test/core/content/content_pack_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
dart format . && flutter analyze
git add lib/features/nutrition lib/app/app.dart lib/l10n/app_en.arb test/core/content/content_pack_test.dart test/features/nutrition
git commit -m "feat(nutrition): meals and day totals from Nourishly"
```

---

### Task 5: Care's Nutrition tile, "Today: N meals from Nourishly"

**Files:**
- Modify: `lib/features/care/presentation/care_screen.dart:319-337`
- Test: `test/features/nutrition/nourishly_section_test.dart` (add tests)

**Interfaces:**
- Consumes: `nourishlyShareProvider` (Task 4); `nutritionTodayMeals` ARB (Task 4).

- [ ] **Step 1: Failing tests** (append to the Task 4 file):

```dart
  testWidgets("Care's tile: today's meals from Nourishly", (tester) async {
    await _care(tester, FakeNourishly(nourishlyJson()));
    expect(find.text('Today: 1 meal from Nourishly'), findsOneWidget);
  });

  testWidgets("Care's tile: foods she avoids when nothing is shared today", (
    tester,
  ) async {
    await _care(tester, FakeNourishly());
    expect(find.text('Foods you avoid'), findsOneWidget);
  });
```

- [ ] **Step 2: Run them.** Expected: the first FAILS ("Today: 1 meal…" not found); the second passes.
- [ ] **Step 3: Implement.** In `_NutritionTile.build`:

```dart
    final today = ref.watch(todayProvider);
    final meals =
        ref.watch(nourishlyShareProvider).value?.day(today)?.meals.length ?? 0;
    // …
      subtitle: meals > 0
          ? l10n.nutritionTodayMeals(meals)
          : l10n.nutritionAvoidCount(foods.length),
```

Change the doc comment to say: "with today's meals from Nourishly (M8b), or how many foods she avoids".

- [ ] **Step 4: Run** `flutter test test/features/nutrition/ test/features/care/`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(care): the Nutrition tile shows today's meals from Nourishly`

---

### Task 6: Accessibility and goldens

**Files:**
- Modify: `test/accessibility_test.dart`, `test/goldens/screens_golden_test.dart`
- Create or update: `test/goldens/macos/*.png`, `test/goldens/linux/*.png`

- [ ] **Step 1: Accessibility.**
  - `_screens` uses one `pumpApp` per entry. Check how it is called (lines 820–890) and add a `nourishly` argument, so an entry can carry a `FakeNourishly`. Give the record a third field, or keep a separate map, whichever the file's pattern allows with the smaller diff. Ledger the choice.
  - Add entries:
    - `'nutrition, from Nourishly'`: shared, today.
    - `'nutrition, another day'`: shared, after tapping `nourishly-day-2026-10-04`.
    - `'nutrition, unreadable'`: version 2.
  - The existing `'nutrition'` entry stays as the not-shared state.
- [ ] **Step 2: Run** `flutter test test/accessibility_test.dart`. Expected: PASS at 1.0×, 1.3× and 2.0×. If 2.0× overflows the strip, fix it with `FittedBox` on chip text, never by shrinking targets.
- [ ] **Step 3: Goldens.**
  - Add a test `'nutrition from Nourishly $name'` beside the M8a birth-prep goldens.
  - It uses `pumpApp(…, nourishly: FakeNourishly(nourishlyJson()))` and selects 4 Oct (partial note visible).
  - Files: `nutrition_nourishly_$name.png`.
  - The existing `nutrition_$name.png` changes (it now shows the not-shared line).
  - Run `flutter test test/goldens --update-goldens` (macOS), then look at each new and changed PNG.
- [ ] **Step 4:** Push, then download the Linux goldens: `gh run download <run-id> -n linux-goldens -D test/goldens/linux`.
- [ ] **Step 5: Commit** `test: accessibility and goldens for meals from Nourishly`, then `test: Linux goldens for meals from Nourishly`.

---

### Task 7: Docs, version, verification and PR

**Files:**
- `pubspec.yaml` and `lib/features/backup/data/backup_service.dart` (`appVersion`): `1.4.0+6` / `1.4.0`.
- `docs/PLAN.md`:
  - Decision 71: change "built in M8b" to "built in M8b, 1.4.0".
  - Add decision 76, **M8b**:
    - The 7-day strip with ‹ › by week, back as far as she likes, never past today.
    - "Updated" shows the time for today and the date otherwise.
    - Totals in fixed order. A missing nutrient is left out, never 0. "{nutrients}: some foods had no data".
    - The Care tile line.
    - Unit strings exempt from the word check.
    - The unreadable state is amber.
    - Not stored anywhere.
    - **Navmaas 1.4.0 (build 6)**.
- `docs/ARCHITECTURE.md`:
  - Status line: add "M8b built: meals from Nourishly (no schema change), Navmaas 1.4.0".
  - §4: the `nutrition/` line (domain/ parser, data/ provider) and `core/platform/nourishly.dart`.
  - §13: Navmaas declares and uses `NOURISHLY_SHARE`. Runner joins `group.com.patelkeyur.share`. It reads only and stores nothing.
  - §15: M8 ✅ (M8a and M8b, dates).
  - §16: the new CI permission check.
- `docs/DESIGN_SYSTEM.md`:
  - Line 6 board list: "M8b's boards added 2026-10-…: Nutrition from Nourishly (shared, empty day, not shared, unreadable) and Care's tile".
  - §8: any difference from the board.
- `CLAUDE.md`:
  - Folder conventions: `core/platform/nourishly.dart` (`NourishlySource`, faked by `FakeNourishly`), `nutrition/` (the M8b part), and `pumpApp`'s fake list.
  - Gotchas:
    - Unit keys `nourishlyUnit*` are exempt from the ARB word check.
    - `nourishlyShareProvider` has retry off.
    - Times from Nourishly are shown as written, never converted.
- `README.md`:
  - The features list says Nutrition shows meals from Nourishly when "Share with Navmaas" is on there.
  - Privacy: the link stays on the phone.

- [ ] **Step 1:** Make the edits above. Then grep the docs for leftovers that are now stale: `rg -n "M8b" docs README.md CLAUDE.md`. Every hit must read as built, not "next" or "adds".
- [ ] **Step 2: Full verification:**
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`. Expected: zero issues.
  - `flutter test`. Expected: all pass. `test/screenshots/capture_test.dart` fails on macOS only (Linux font path), as it did before this branch.
  - `flutter build apk --release --target-platform android-arm,android-arm64` with the Task 3 permission script. Expected: NOURISHLY_SHARE present, no INTERNET.
  - `flutter build ios --release --no-codesign`.
- [ ] **Step 3: Final review.** Run a fresh reviewer on the most capable model over `git merge-base main HEAD..HEAD`, then do one fix pass, as superpowers:executing-plans describes.
- [ ] **Step 4: PR.**
  - Push. Run `gh pr create --base main --title "feat: meals from Nourishly"`.
  - The body gives a summary, the test evidence, and the **owner's phone checks**:
    1. Android, both apps from GitHub releases (Nourishly v1.2.0+, Navmaas 1.4.0), installed in both orders. Turn on sharing in Nourishly, log a meal, switch to Navmaas: it appears.
    2. Android refusal: `adb shell content read --uri content://com.nourishly.app.nourishly.share/navmaas` fails with a permission error from the shell.
    3. iPhone: in Xcode, Runner → Signing & Capabilities shows both App Groups. Install both apps, turn sharing on, and the meals appear.
  - End the PR body with the attribution line. Do not merge.

---

## Self-review notes

- **Spec §6.3 coverage:**

  | Spec item | Task |
  |---|---|
  | Adapter | 3 |
  | Android manifest (uses, declares, queries) | 3 |
  | iPhone group | 3 |
  | Parser | 1 |
  | Section above Foods I avoid | 4 |
  | 7-day picker with prev/next | 4 |
  | Meals, items and amounts | 4 |
  | Totals with units | 4 |
  | Partial note | 4 |
  | "Updated" | 4 |
  | Re-read on open and resume | 4 |
  | Nothing stored | Global constraint |
  | States: not shared, no meals, unreadable in amber | 4 |
  | Parser tests: sample, bad JSON, future version, missing field, partial | 1 |
  | Widget tests: states and resume | 4 |
  | Accessibility and goldens | 6 |
  | Merged release manifest has no INTERNET | 3 (CI step) |
  | Owner's phone checks | 7 |
  | Tile line (owner decision 2026-10-10) | 5 |

- **Two deliberate choices beyond the spec:**
  - **"Updated":** shows the date when the file isn't from today. Otherwise a stale file would read as fresh.
  - **The four states:** carried by `AsyncValue` (`null`, a share, or an error) rather than a new sealed type.
