# Navmaas — notes for Claude

Navmaas (नवमास) is a calm, private pregnancy tracker for iOS and Android, built with Flutter. It is local-first: no account, no backend, no network calls. Data lives in an encrypted on-device database. Personal use, public MIT repo.

**Source of truth.** Read these before changing anything; they win over assumptions:

- [docs/PLAN.md](docs/PLAN.md): decisions, feature map, constraints
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): stack (§3), folders (§4), pregnancy engine (§6), data model (§8), free Apple ID install (§12), security (§13), milestones (§15), CI (§16), ADRs (§17)
- [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) and [design/navmaas-tokens.css](design/navmaas-tokens.css): "Moonlit Sage" tokens, type, components

**Ask before** adding a package beyond ARCHITECTURE §3, or deviating from the docs. Owner decisions (bundle ID, package swaps, scope) are not yours to make.

**Keep the docs in sync.** Any change that alters something documented (a decision, package, table, setting, folder, test promise, milestone status) updates `docs/`, `README.md` and this file in the same PR. Nothing in the docs may be stale. Prototype differences go in DESIGN_SYSTEM §8.

**The prototype is the exact visual spec** (Plan decision 15), including its icons.

## Commands

```sh
flutter pub get                       # also regenerates lib/l10n/gen (gen-l10n)
flutter run                           # debug; add --release for a phone install
dart format .                         # CI runs: dart format --set-exit-if-changed .
flutter analyze                       # must report zero issues
flutter test                          # unit + widget + accessibility tests
dart run build_runner build           # drift (*.drift.dart) + riverpod (*.g.dart); commit the output
dart run drift_dev make-migrations    # after a schema change (see below)
dart run tool/weeks_md.dart           # after editing assets/content/weeks.json (review copy)
flutter test test/goldens --update-goldens  # after an intended visual change
flutter build apk --release           # universal APK (~71 MB; limit 100 MB); --split-per-abi ~25 MB per phone
flutter build ios --release --no-codesign   # compile check; installs go through Xcode (§12)
```

## Folder conventions (ARCHITECTURE §4)

- `lib/app/`: `NavmaasApp`, router (go_router `StatefulShellRoute`, 5 tabs), theme mode
- `lib/core/theme/`: `AppTheme` (exact hex values), the `NavmaasColors` extension and `NavmaasIcon` (the prototype's icons as SVG path data). Never hard-code colours in widgets, and never use Material `Icons`.
- `lib/core/widgets/`: shared widgets (`PillSegmented`, icon motion). New motion is specified in DESIGN_SYSTEM §5 first.
- `lib/core/content/`: content-pack loader. `assets/content/weeks.json` is the source of the week-by-week text.
- `lib/core/db/`: drift database, tables, key handling, repositories with their providers
- `lib/core/pregnancy/`: the pregnancy engine. **Pure Dart, no Flutter imports.**
- `lib/core/utils/`: date-only maths (UTC-midnight dates), `todayProvider` / `nowProvider` (the clock)
- `lib/features/<feature>/`: screens and widgets per feature
- `lib/l10n/app_en.arb`: every user-facing string. No literals in widgets.
- `test/`: mirrors `lib/`; `test/helpers.dart` has `pumpApp` (in-memory DB, fixed today 2026-10-05 at 9:00); `test/goldens/` holds the golden screenshots

## Hard lines

- **No network calls** of any kind: no analytics, crash reporting, ads or remote fonts. Release Android builds have no `INTERNET` permission.
- **No SOS or emergency features**, no medical interpretation, no dose suggestions, no sex prediction.
- **No copyrighted text or audio** in the repo. Only original or public-domain content.
- **Red (`error`) only for destructive actions and errors.** Notices use amber.
- **Accessibility:**
  - ≥ 48 dp touch targets
  - `Semantics`/tooltip on icon-only buttons
  - no overflow at 1.0×, 1.3× and 2.0× text
  - respect reduce motion

  `test/accessibility_test.dart` enforces this for every screen; add new screens to it.
- Never commit keystores, `key.properties`, provisioning profiles, `.navmaas` backups or personal content.

## Gotchas learned in M1

- **Dart 3.13 style:** constructors are declared as `const new(...)` / `factory name(...)` (lint `unnecessary_type_name_in_constructor`). Dot shorthands (`.lmp`) are fine.
- **Encryption:** `sqlite3` with `hooks: user_defines: sqlite3: source: sqlcipher` in `pubspec.yaml`. This replaces the end-of-life `sqlcipher_flutter_libs`. `encryptedExecutor` refuses to open without SQLCipher.
- **Drift codegen:** drift uses the `not_shared` builder (`*.drift.dart`) and runs before riverpod_generator (see `build.yaml`), so providers can return drift row classes.
- **Riverpod 3 pauses unlistened providers:** use `container.listen(...)`, not `read`, when awaiting a stream provider outside widgets (see `loadFirstValues`).
- **Widget tests with drift:**
  - Seed data inside `tester.runAsync`.
  - Use `DatabaseConnection(..., closeStreamsSynchronously: true)`.
  - Close the DB in `tester.runAsync`; otherwise a failed test hangs the run.

  `pumpApp` already does all three.
  - Call `ensureVisible` before tapping below the fold.
- **OS backups:** they stay on, but the DB and its key are excluded on both platforms. On iOS that's the `navmaas/files` channel plus a `first_unlock_this_device` key; on Android it's the `res/xml` rules. The `.navmaas` backup file (M5) is the only way to move data between phones.
- **Assets in tests:** load with `rootBundle.loadString(path, cache: false)`. A cached asset future from one widget test never completes in the next.
- **Lazy lists:** don't look up a child's context to scroll to it (it may not be built). Compute the offset, as Journey's week chips do.
- **Widget-test scrolling:** `scrollUntilVisible` stops at "partly visible", possibly under the tab bar. Follow it with `ensureVisible` before tapping.
- **Content hard lines:** `test/core/content/content_pack_test.dart` rejects dose, sex-prediction, outcome-claim and emergency words in `weeks.json`.
- **Schema changes:**
  1. Bump `schemaVersion`.
  2. Write the migration.
  3. Run `make-migrations`.
  4. `test/drift/navmaas/migration_test.dart` then checks every version pair.
