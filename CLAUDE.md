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
dart run tool/content_md.dart         # after editing assets/content/*.json (review copies in docs/content/)
dart run tool/bell.dart               # regenerates assets/audio/bell.wav and quiet.wav (a test checks they match)
flutter test test/goldens --update-goldens  # after an intended visual change (macOS set)
flutter test integration_test -d <phone>     # on-device checks (allow notifications first; build_expiry_test reads the iPhone build's expiry; backup_test backs up, restores and deletes all data, and app_flow_test runs onboarding, Taken and a PDF read then deletes all data, so both run only on an empty install)
flutter build apk --release --target-platform android-arm,android-arm64  # the phone APK (~66 MB, Arm only; what CI builds; CI fails it over 100 MB)
flutter build apk --release           # universal APK (~103 MB, adds x86_64; emulators only; limit 150 MB); --split-per-abi ~30 MB per phone
flutter build ios --release --no-codesign   # compile check; installs go through Xcode (§12)
```

## Folder conventions (ARCHITECTURE §4)

- `lib/app/`: `NavmaasApp`, router (go_router `StatefulShellRoute`, 5 tabs), theme mode, `ReminderSync` (its state is the plan) and `WidgetSync` (the home-screen widget snapshot)
- `lib/core/theme/`: `AppTheme` (exact hex values), the `NavmaasColors` extension and `NavmaasIcon` (the prototype's icons as SVG path data). Never hard-code colours in widgets, and never use Material `Icons`.
- `lib/core/widgets/`: shared widgets (`PillSegmented`, icon motion). New motion is specified in DESIGN_SYSTEM §5 first.
- `lib/core/reminders/`: the pure planner, the OS scheduler adapter (`ReminderScheduler`, faked in tests by `FakeScheduler`) and calm-notification settings. **Every notification goes through `ReminderSync` in `lib/app/reminders.dart`**, never straight to the plugin.
- `lib/core/content/`: content-pack loaders. `assets/content/weeks.json` (week-by-week text), `care_template_in.json` (India tests, scans, vaccines) `activities.json` (daily calm activities) and `routines.json` (exercise routines) are the sources; `docs/content/*.md` are generated review copies.
- `lib/core/platform/`: platform adapters. `audio.dart`: `AudioPlayback` (just_audio behind audio_service; faked in tests by `FakeAudio`), the playback stream and the sleep timer. `health.dart`: `StepSource` (read-only steps from HealthKit / Health Connect; faked by `FakeSteps`). `build_info.dart`: the iPhone build's expiry from `embedded.mobileprovision` (`pumpApp(buildExpiry:)` in tests). `home_widget.dart`: `WidgetPublisher` (`home_widget` behind it; faked by `FakeWidgetPublisher`). `authenticator.dart`: `Authenticator` (`local_auth`; faked by `FakeAuthenticator`, which fails until `succeed` is set). `app_usage.dart`: `AppUsage`, the `navmaas/usage` channel to `AppUsage.kt` / `AppLimitCheck.kt` (Android only; faked by `FakeAppUsage`, which `pumpApp` sets to unsupported, like an iPhone, unless given one).
- `lib/core/db/`: drift database, tables, key handling, repositories with their providers
- `lib/core/pregnancy/`: the pregnancy engine. **Pure Dart, no Flutter imports.**
- `lib/core/utils/`: date-only maths (UTC-midnight dates), `clockNow` (the one wall clock), `todayProvider` / `nowProvider`
- `lib/features/<feature>/`: screens and widgets per feature. `sessions/`: library (files in `db/library/`, never encrypted, never in the repo), reader, listen, letters, walk, exercise, breathing, meditation (`ScreenOff` is the shared overlay); the listening log turns playback into sessions (playback ids starting `meditation:` are logged as meditation); `SessionClock` is the shared once-a-second timer, except for the walk, whose unfinished walk lives in the `walk_draft` setting as timestamped stretches (`domain/walk_draft.dart`, logged only at Finish walk). Library progress uses `library_item.furthest` (only goes up); the reader reopens at `position`. `third_trimester/`: kick counter and contraction timer (`domain/patterns.dart`: her averages, never a verdict). `settings/`: Me, pause or end tracking and the quiet "tracking stopped" page. `screen_rest/`: Screen Rest (rules in `settings`, ADR 037), time in Navmaas (`ScreenUse`, saved when the app leaves the screen), rest windows and nudges (`domain/`, pure); limits for other apps (Android, M11a): `data/app_limits.dart`, `domain/limit_rules.dart` (the rules the Kotlin check follows, pure) and the Limits screen; `app/app_limit_sync.dart` sends the rules. `backup/`: the `.navmaas` file (`backup_file.dart`, pure Dart), `BackupService` (faked by `FakeBackupService` in `pumpApp`), the backup log and the Backup & restore screen. `wellbeing/`: mood, symptom, sleep and water logs (keys in the DB, words in `app_en.arb` via `WellbeingWords`), the week and water nudges (`domain/`, pure), Wellbeing and its entry screens; Today's card is `today/wellbeing_card.dart`. `app_lock/`: `AppLock` (locked or not, from the app's lifecycle and the minutes away), the lock screen and the app-switcher cover, shown above the router in `MaterialApp.builder`. `home_widget/`: the widget snapshot (`domain/`, pure); the native widgets are `ios/NavmaasWidget/` (WidgetKit extension) and `android/.../NavmaasWidget.kt` + `res/layout/navmaas_widget.xml`, and they show only the snapshot
- `lib/l10n/app_en.arb`: every user-facing string. No literals in widgets.
- `test/`: mirrors `lib/`; `test/helpers.dart` has `pumpApp` (in-memory DB, fixed today 2026-10-05 with `clockNow` pinned to 9:00, fake scheduler, fake audio, fake steps, a fake widget publisher, a fake authenticator, a fake app usage (unsupported by default), a temp library folder, a fake file picker, an optional build expiry, `FakeBackupService`, a fake share sheet and a delete-all-data that empties the in-memory DB); `test/goldens/` holds the golden screenshots (`failures/` is git-ignored)

## Hard lines

- **No network calls** of any kind: no analytics, crash reporting, ads or remote fonts. Release Android builds have no `INTERNET` permission.
- **No SOS or emergency features**, no medical interpretation, no dose suggestions, no sex prediction. No warning or danger-sign lists anywhere: nothing tells her a symptom is serious, normal, or a reason to act. The only symptom list is Wellbeing's log of common discomforts (Plan decision 39): she records what she felt; nothing is advised, rated or flagged. Walk and Exercise show one general line (Plan decision 26).
- **No copyrighted text or audio** in the repo. Only original or public-domain content.
- **Red (`error`) only for destructive actions and errors.** Notices use amber.
- **Accessibility:**
  - ≥ 48 dp touch targets
  - `Semantics`/tooltip on icon-only buttons
  - no overflow at 1.0×, 1.3× and 2.0× text
  - a heading (`Semantics(header: true)`) on every screen, sheet and dialog
  - respect reduce motion

  `test/accessibility_test.dart` enforces this for every screen; add new screens to it.
- Never commit keystores, `key.properties`, provisioning profiles, `.navmaas` backups or personal content.

## Gotchas learned so far

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
- **Goldens:** one exact set per platform. `test/goldens/macos/` is updated locally. For `test/goldens/linux/`, push to the PR; when CI's tests fail it uploads fresh Linux renders as `linux-goldens`: `gh run download <run-id> -n linux-goldens -D test/goldens/linux`.
- **Semantics in Cards:** `Card` merges its children into one node. A custom tappable inside a card needs `Semantics(container: true, …)` or screen readers lose it.
- **Dialogs with text fields:** the dialog widget must own (create and dispose) its controllers; disposing them after `showDialog` returns crashes the closing animation.
- **Encrypted attachments:** `AttachmentStore` only; never write photo bytes to disk unencrypted, and decrypt only in memory.
- **Drift transactions:** read with `get…()` inside a transaction, never `watch().first` (the stream waits for the transaction).
- **Reminder actions** run in a background isolate: no app channels there (`navmaas/files` is skipped), and the app refreshes drift streams on resume.
- **Content hard lines:** `test/core/content/content_pack_test.dart` rejects dose, sex-prediction, outcome-claim and emergency words in `weeks.json`, the care template, `activities.json` and `routines.json` (which also may not say "on your back").
- **Schema changes:**
  1. Bump `schemaVersion`.
  2. Write the migration.
  3. Run `make-migrations`.
  4. `test/drift/navmaas/migration_test.dart` then checks every version pair.
- **Real file I/O in widget tests** (the reader, library import) runs outside fake time: loop `tester.runAsync(short delay)` + `pump()` a few times (`_settleIo` in the Sessions and accessibility tests).
- **`ref` in `dispose()`** throws. Read repositories and ids in `initState()` when `dispose()` must save something (the reader logs its session there).
- **Scroll position in `dispose()`:** child scroll views are already detached. Keep the position in a field from a scroll listener.
- **APK ABIs:** `build.gradle.kts` drops every ABI not passed in `--target-platform`, so the Arm-only APK carries no stray x86_64 library.
- **Repeating animations** never let `pumpAndSettle` finish. Slow breathing animates only after Start, so tests and the accessibility pass see it still; drive a running session with `pump(duration)`.
- **Health access** is asked on the first walk only; Sessions and Today read steps without asking (null until allowed).
- **The clock:** never call `DateTime.now()` in `lib/`; use `clockNow()`. Widget tests pin it to 9:00 on 5 Oct 2026 (moving with real and fake time). Rows stamped with the real clock land on another day than the screens show.
- **Tracking status:** features read only the *active* pregnancy, so a paused / ended / delivered one makes them empty; the router shows `/stopped` instead of the tabs (`latestPregnancyProvider`). Never add per-screen status checks.
- **Backup & restore from onboarding or the quiet page uses `context.go('/backup')`**, not push: a router refresh re-checks the route *underneath* a pushed one, so restored data appearing would close the screen before "Restored" shows.
- **Restore stages in `backup-work-restore/`**, never in `backup-work/` (where the backup she just made lives).
- **Providers that swap the database** (`backupService`, `deleteAllData`) are `keepAlive`: an auto-dispose one is disposed mid-run once nothing listens (the simulator caught it).
- **The real backup service reads the database lazily** (`database()`): a restore swaps `appDatabaseProvider` underneath it.
- **Reminder settings compare by value** (`ReminderSettings ==`, `.distinct()`): writing an unrelated setting (time in Navmaas, saved on every hide) must not re-plan reminders. Add new rule fields to `_fields`.
- **Notification taps** go through `openReminder` (`ReminderPayload.open`); a tap that launched the app comes from `ReminderScheduler.launchResponse()` after the first frame.
- **Buttons that change colour with state:** give each state its own `key`, or the label fades through the fill (the contraction button failed the contrast test mid-tween).
- **Screens that start from saved data** (mood, sleep): seed with `ref.listenManual(…, fireImmediately: true)` in `initState`, without `setState` on the first call, and stop once she has touched a field. A `ref.read` there sees nothing when the stream hasn't loaded yet.
- **Wellbeing words:** the DB stores enum keys; add a word to `app_en.arb` (`moodWord*`, `symptomPick*`, `severity*`, `restedWord*`) and `WellbeingWords` together, or the content test fails. No good/bad, advice or warning words anywhere in Wellbeing.
- **Nudges bundle:** a nudge within 30 minutes of another reminder rides in that notification (generic title, "Folic acid · Water"); on its own over the daily limit it drops, and the digest never holds one.
- **`FakeAudio` doesn't move position by itself:** `seek` in the test where real playback would have moved on (Meditation's countdown and "running" state read the position).
- **Meditation's timer is audio:** the countdown comes from the track's position, not a Dart timer, so it keeps time with the phone locked. Change the bell only through `tool/bell.dart`.
- **Home-screen widget words** come from `app_en.arb` through the snapshot (`widgetSnapshot`); the native code has no user-facing text except the widget gallery's name and description. With "Hide details" the snapshot must hold no week, size, baby or reminder text (unit test).
- **Widget taps** open `navmaas://widget/today`, which Flutter's deep linking routes to `/today`. Never add a `homeWidget` query: `home_widget` would claim the URL and Flutter wouldn't route it.
- **Android widget layouts** (RemoteViews) allow only layouts such as `FrameLayout` / `LinearLayout`, `TextView` and `ImageView`; a plain `View` spacer makes the widget fail to load. Use an empty `FrameLayout`.
- **Xcode:** Runner's "Embed Foundation Extensions" phase must stay before "Thin Binary", or the build reports a cycle. The widget extension uses Flutter's xcconfigs for its version and the same team.
- **App lock** covers the app from `MaterialApp.builder`; never add per-screen lock checks or a lock route. Lifecycle in tests: step through every state (`inactive`, `hidden`, `paused` and back), as the engine does; the test binding doesn't fill them in, and `AppLifecycleListener` only calls `onHide` / `onShow` on those steps.
- **App-limit notices** are decided in Dart (`limitRules`): the Kotlin check only follows the open windows, the day's room and the ready-made notice. Change a rule or a word in Dart, never in `AppLimitCheck.kt`.
- **Integration tests that write from the background isolate** (`reminderActionInBackground`): the app's own drift streams don't see another connection's write until `markTablesUpdated` (the app does it on resume), so call it before checking.
- **Version:** bump `version` in `pubspec.yaml` and `appVersion` in `backup_service.dart` together (a test checks they match); the widget extension takes the same version from Flutter's xcconfigs.
