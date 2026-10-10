# M8 Body and birth prep, with the Nourishly link — design

*Approved in conversation 2026-10-10. Supersedes the M8 scope in [ARCHITECTURE §15](../../ARCHITECTURE.md#m8-body-and-birth-prep) where they differ; §15, the Plan and the other docs are updated in the PRs that build it.*

## 1. Intent

- **What the owner asked for:** build M8 (blood sugar, nutrition, hospital bag, birth plan). For nutrition, Navmaas shows what she logged in **Nourishly** (the owner's own diet tracker, [patel-keyur-18/nourishly](https://github.com/patel-keyur-18/nourishly)) instead of having her type meals again. Nourishly may change to expose its data to Navmaas only.
- **Who uses it:** the owner's wife on her Android phone (the real user). The owner on his iPhone (testing). Both apps sit on the same phone in both cases. APKs are installed from GitHub releases.
- **Success:**
  - She logs food once, in Nourishly, and sees each day's meals and a few totals in Navmaas.
  - Blood sugar, foods she avoids, the hospital bag and the birth plan live in Navmaas.
  - GitHub-release updates install in place on her phone.

## 2. Constraints carried over

- **No network** on either side, and Navmaas release builds keep no `INTERNET`. The apps talk only on the phone.
- **No interpretation.** Navmaas shows values only: no targets, %, scores, colours, "high/low" or food advice. Nothing of Nourishly's targets, scores or insights crosses over.
- **No new Dart packages.** Native code is small Kotlin/Swift.
- **Design first:** new screens go on the prototype canvas, in light and dark, approved before code (ADR 043).
- **Content:** original, drafted by Claude, approved by the owner, with review copies and the hard-line test.
- **Process:** each PR bumps the version and uses a Conventional Commits title. Docs stay in sync in the same PR.

## 3. Pieces and order

| # | PR | Repo | Version |
|---|---|---|---|
| 0a | `ci: sign release APKs with the owner's key` | navmaas | 1.2.1 |
| 0b | the same for Nourishly (its own conventions) | nourishly | its next |
| 1 | M8a `feat: blood sugar, foods I avoid, hospital bag and birth plan` | navmaas | 1.3.0 |
| 2 | `feat: share with Navmaas` | nourishly | its next |
| 3 | M8b `feat: meals from Nourishly` | navmaas | 1.4.0 |

0a/0b come first because every APK from a GitHub release is signed with a different key today. This was checked on 2026-10-10:

| APK | Cert SHA-256 |
|---|---|
| Navmaas 1.2.0 | `7db737d7…` |
| Navmaas, earlier CI build | `44898f5e…` |
| Nourishly v1.0.0 | `877104f5…` |
| Mac debug key | `90f0d7c4…` |

So no release can update the previous one in place, and the M8b link can't work.

## 4. Signing (PRs 0a, 0b)

- **One keystore** signs both apps. The owner generates it with `keytool` (or Android Studio → Generate Signed Bundle/APK → Create new), e.g. `~/keyur-android.jks`, alias `release`, validity 10000 days. Claude never sees the passwords.
- **Mac:** a git-ignored `android/key.properties` in each repo points at the same `.jks`. Navmaas's Gradle already reads it. Nourishly gets the same `signingConfigs` block and the same debug fallback.
- **CI:**
  - Four repository secrets per repo: `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.
  - A step before the APK build decodes the keystore into `$RUNNER_TEMP` and writes `android/key.properties`.
  - If the secrets are absent (fork PRs), the step is skipped and the build falls back to the debug key as today.
- **Never committed:** no `.jks` and no `key.properties` (CLAUDE.md hard line).
- **Check:** a CI step prints the APK's signing cert SHA-256 (`apksigner verify --print-certs`) so the owner can compare it across releases. It never prints passwords.
- **One-time move on her phone** (Mac builds or the first releases on the new key):
  1. Navmaas: Backup → uninstall → install → Restore.
  2. Nourishly: export → uninstall → install → import.
- **Risk:** lose the `.jks` or its password and neither app updates in place. The owner backs both up in two places.
- **Side effect:** `flutter run` (debug key) can't install over a release-signed app without uninstalling first.
- **Docs:** README install steps (one key for both apps, the secrets), ARCHITECTURE §16 (CI signs with the owner's key from secrets) and an ADR.

## 5. M8a — Navmaas only (PR 1)

### 5.1 Schema v12 (one bump)

- `vital_reading`: new nullable `context` (`BloodSugarContext`: `fasting`, `beforeMeal`, `after1h`, `after2h`, `bedtime`) and nullable `note`. `VitalKind` gains `bloodSugar` (value1 = mg/dL).
- `avoid_food`: `pregnancyId`, `name`, `reason` (nullable).
- `bag_item`: `pregnancyId`, `templateKey` (nullable; unique per pregnancy when set), `label` (nullable; her own items), `section` (`forMe`, `forBaby`, `documents`), `packed` (bool). Template items get a row once she ticks them. Her own items always have a row.
- `birth_plan_answer`: `pregnancyId`, `promptKey`, `answer`. Unique per (`pregnancyId`, `promptKey`).
- `make-migrations` plus the migration test for every version pair. Backup round-trip covers the new tables, an older backup restores and migrates, and delete-all empties them.

### 5.2 Blood sugar (Care → Vitals)

- A third vital tile beside Weight and BP. Its log sheet takes mg/dL, when it was taken (Fasting · Before a meal · 1 h after · 2 h after · Bedtime), the time and a note.
- The list is grouped by day, newest first. No ranges, colours or labels such as "high". Context words are in `app_en.arb`, and the content test checks them.

### 5.3 Care → Nutrition

- A new Care tile and screen. In M8a it holds only **Foods I avoid**: her list, each item with an optional reason ("doctor's advice"), with add, edit and delete.
- The app gives no food guidance. M8b adds the Nourishly section above this list on the same screen.

### 5.4 Hospital bag

- Template `assets/content/hospital_bag.json`: about 30 original items in three sections (For me, For baby, Documents), each with a stable key.
- She ticks items as packed, and adds and deletes her own items. Template edits never lose her ticks: removed keys are ignored, and a changed label keeps its tick.
- **Optional one-off reminder** "Pack the hospital bag" at a date and time she picks. It's stored in `settings`, planned through `ReminderSync`, and follows §7's calm rules.
- **On Care:** a "Getting ready" row (Hospital bag, Birth plan) is prominent from week 28. Before week 28 both stay reachable lower on Care. Exact placement is settled on the prototype boards.

### 5.5 Birth plan

- `assets/content/birth_plan.json`: 5–7 original prompts with short hints. They cover who will be with you, comfort preferences, after the birth, feeding wishes, and anything else.
- She answers each prompt in free text and can edit at any time. "Talk this through with your doctor" sits at the top.

### 5.6 Content

- Claude drafts both packs. The owner approves them before the screens that use them are built.
- `tool/content_md.dart` produces review copies in `docs/content/`, and `content_pack_test` extends to both packs.

### 5.7 Tests and done-when

- Blood-sugar readings save with their context and are listed by day. No screen judges a value (widget tests, content test).
- Bag ticks persist per pregnancy and survive template edits (test with a changed template). The bag reminder follows quiet hours (planner test).
- Birth plan answers save and edit. Foods I avoid: add, edit and delete.
- Every new screen and sheet is in `accessibility_test.dart`, with goldens in light and dark (macOS and Linux).

## 6. The Nourishly link (PRs 2 and 3)

### 6.1 Contract: `nourishly-share.json`, version 1

```json
{ "format": "nourishly-share", "version": 1,
  "generatedAt": "2026-10-10T09:40:00+05:30",
  "days": [ { "date": "2026-10-09",
      "meals": [ { "slot": "Breakfast",
                   "items": [ { "name": "Poha", "amount": "1 bowl · 150 g" } ] } ],
      "totals": { "energy": 1850, "protein": 62, "iron": 14.2,
                  "calcium": 820, "folate": 310, "fibre": 22 },
      "partial": ["iron"] } ] }
```

- **Scope:** the shared profile only, for the last 90 days. Days with nothing logged are left out.
- **Totals:** Nourishly's nutrient ids, with fixed units: `energy` kcal, `protein` g, `iron` mg, `calcium` mg, `folate` µg, `fibre` g. A nutrient with no data at all is left out of `totals`. `partial` lists nutrients where some of the day's foods had no data, because Nourishly treats unknown as unknown, not zero.
- **`slot` and `amount`** are display text from her Nourishly data: meal slot name, serving label and grams.
- **Never in the file:** targets, %, scores, insights, profile details (age, weight, due date) or other profiles.
- **Compatibility:** readers ignore unknown fields. A different `format`, or a `version` greater than 1, means "can't read". New optional fields don't bump the version.
- **One sample file** (`nourishly-share-v1.sample.json`) lives in both repos. Each repo's tests read it. The contract text is in both repos' docs.

### 6.2 Nourishly side (PR 2)

- **Settings → "Share with Navmaas":**
  - Off by default.
  - A profile picker, defaulting to the profile with a due date.
  - A line saying what is shared.
  - Turning it off deletes the file.
- **`ShareSnapshotBuilder`** (pure Dart) is built from the existing DAOs and daily summaries.
- **Writer:**
  - Rewrites the file after any change to the shared profile's food log (debounced, about 2 s) and when the app goes to the background.
  - Writes are atomic (temp file + rename).
- **Android:**
  - The file sits in the app's private files dir, `share/nourishly-share.json`.
  - `ShareProvider` (authority `com.nourishly.app.nourishly.share`, exported, read-only) serves it through `openFile`.
  - `android:readPermission="com.patelkeyur.permission.NOURISHLY_SHARE"`, declared with `protectionLevel="signature"`.
- **iPhone:**
  - The file goes into App Group `group.com.patelkeyur.share` (added to Runner's entitlements, same personal team).
  - It's excluded from iCloud backup.
- **Tests:**
  - The builder never includes another profile.
  - No target or score fields appear.
  - The 90-day window and partial flags are right.
  - The output matches the sample's shape.
  - Turning sharing off deletes the file.

### 6.3 Navmaas side (PR 3)

- **Adapter:** `lib/core/platform/nourishly.dart`, `NourishlySource.readShare() → String?` over channel `navmaas/nourishly`. Tests use `FakeNourishly` in `pumpApp`.
- **Android:**
  - Kotlin opens `content://com.nourishly.app.nourishly.share/navmaas`.
  - The manifest gains `<uses-permission>` for `com.patelkeyur.permission.NOURISHLY_SHARE`, a `<queries><provider android:authorities="com.nourishly.app.nourishly.share"/></queries>` entry, and **its own declaration of the same signature permission**. Then install order doesn't matter: Android grants a signature permission only if it was already defined when the app installed, and both apps share the key.
  - Not installed, no permission or no file all return `null`.
- **iPhone:**
  - Swift reads the file from App Group `group.com.patelkeyur.share`, which Runner joins.
  - The widget's group `group.com.patelkeyur.navmaas` is untouched.
- **Parser:** pure Dart, `lib/features/nutrition/domain/nourishly_share.dart`.
- **Nutrition screen:** a "From Nourishly" section above Foods I avoid.
  - Day picker over the last 7 days, prev/next for older ones.
  - Each day lists its meals with items and amounts, then a row of totals as plain numbers with units (words in `app_en.arb`). A partial nutrient carries a small "some foods had no data" note.
  - "Updated {time}" comes from `generatedAt`.
  - It reads when the screen opens and when the app resumes. **Navmaas stores nothing** (no table, no backup change). Nourishly stays the source of truth.
- **States** (calm wording, no red):
  - *Not found or sharing off:* "Turn on Share with Navmaas in Nourishly".
  - *Nothing that day:* "No meals from Nourishly for this day".
  - *Couldn't read:* "Couldn't read Nourishly's data. Open Nourishly once, then come back." This one is amber.
- **Tests:**
  - Parser against the shared sample, plus bad JSON, a future version, a missing field and partial nutrients.
  - Widget tests for all four states and a re-read on resume.
  - Accessibility and goldens.
  - The merged release manifest still has no `INTERNET`.
- **On the phones** (owner checks): Android with both apps from releases on the new key, in both install orders. The iPhone App Group read.

### 6.4 Not built (add later if wanted)

- An "Open Nourishly" button, which needs URL schemes or launch intents in both apps.
- Anything about water and weight, which both apps log.
- Signing CI's iOS builds, since free Apple ID signing stays on the Mac.

## 7. Owner decisions recorded (go into the Plan)

- Nutrition comes from Nourishly through the snapshot hand-off. Navmaas stores nothing. `meal_note` is dropped from M8.
- "Share with Navmaas" in Nourishly is off by default. It shares one profile and 90 days.
- Navmaas shows meals plus six totals: kcal, protein, iron, calcium, folate, fibre. Values only.
- M8 is split into M8a (Navmaas features) and M8b (the link), with a Nourishly PR between them.
- One owner-made keystore signs both apps. CI uses it from repository secrets. The owner creates it and sets the secrets.
- Still to come, during M8a: approval of the hospital bag template and the birth-plan prompts (Claude drafts), and approval of the prototype boards.
