# Navmaas — Architecture Design

| | |
|---|---|
| **Status** | v13 — updated 2026-10-06 (MVP complete, M1–M6. Phase 2 split into M7–M11 and Phase 3 into M12–M14, each with scope and done-when criteria (§15); family sharing out of scope, ADR 042. M7 Wellbeing built (M7a schema v7, ADRs 044–045; M7b meditation, ADR 046)) |
| **Stack** | Flutter (stable) · Dart 3 |
| **Inputs** | [Plan](PLAN.md) · [Design system](DESIGN_SYSTEM.md) · [Prototype](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8) |

## 1. Context and constraints

| Constraint | Consequence for the design |
|---|---|
| Personal use, free | No accounts, payments, analytics or backend |
| Tracking aid, no medical reviewer | Domain logic records and reminds; it never interprets readings |
| No SOS / emergency features | Emergencies are handled manually, as the doctor advises. The app has no emergency calls, location sharing or danger-sign content |
| Owner supplies Garbhasanskar content | In-app import of PDF, text and audio, stored on the device |
| Public MIT repository | Only original or public-domain content in `assets/`; no secrets in the repo |
| India, English only | `en` strings through `gen-l10n` (ready for more later); India care template |
| iPhone signed with a **free Apple ID** | Only capabilities available to a personal team; the build expires every 7 days, so the app warns before expiry (§12) |
| No cloud | Password-protected backup file is the only way data survives a lost or wiped phone (§11) |
| Calm, low-screen product | Audio-first sessions, a notification budget, quiet hours, Screen Rest |
| Low-end Android phones | Small app size, no background polling in the MVP, offline-first |

**Non-functional targets**

- Cold start under 2 s on a 3 GB-RAM Android phone.
- Phone APK at most 100 MB, universal APK at most 150 MB (the owner's limits; CI fails the phone APK over 100 MB). Since M4a the phone build is Arm only (`--target-platform android-arm,android-arm64`, about 66 MB at M6); the universal APK, which adds x86_64 for emulators, is about 103 MB, so it is for emulators only, and `--split-per-abi` gives about 30 MB per phone. PDFium (the PDF engine) is about 5 MB per ABI.
- 100 % offline.
- No network calls.
- Every screen usable at 200 % text size and with TalkBack / VoiceOver.
- A backup streams through in a fixed amount of memory, whatever the library size: a 500 MB library needs about what a 50 MB one does (about +30 MB on a Mac, up to ~80 MB on CI's Linux, depending on garbage collection; owner decision 2026-10-06).

## 2. Architecture at a glance

```mermaid
flowchart TB
  subgraph UI["Presentation"]
    Screens["Feature screens & widgets"] --> Ctrl["Riverpod controllers / notifiers"]
  end
  subgraph Domain["Domain (pure Dart)"]
    Engine["Pregnancy engine"]
    Planner["Reminder planner"]
    Rules["Session rules"]
  end
  subgraph Data["Data"]
    Repos["Repositories"] --> DB[("Drift + SQLCipher")]
    Repos --> Files[("App sandbox files<br/>library · attachments")]
    Pack["Content-pack loader"] --> Assets[("Bundled JSON assets")]
    Backup["Backup & restore service"] --> DB
    Backup --> Files
  end
  subgraph Platform["Platform adapters"]
    Notif["Local notifications"]
    Health["HealthKit / Health Connect"]
    Audio["Background audio"]
    Share["Files · share sheet"]
    Build["Build-expiry reader (iOS, Dart)"]
    SR["Screen Rest channel (P2, Android)"]
  end
  Keys["Secure storage<br/>(Keychain / Keystore)"] --> DB
  Ctrl --> Engine & Planner & Rules & Repos & Pack & Backup
  Planner --> Notif
  Backup --> Share
  Ctrl --> Health & Audio & Build & SR
```

- **One Flutter app, no server.** All state lives in an encrypted SQLite database plus files in the app sandbox.
- **Domain is pure Dart.** The pregnancy engine and the reminder planner have no Flutter imports, so they are fast to unit-test.
- **Platform adapters sit behind interfaces**, so tests can use fakes.

## 3. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter stable, Dart 3 | Material 3 with custom tokens |
| State & DI | `flutter_riverpod` (+ `riverpod_generator`) | Compile-safe providers, easy overrides in tests |
| Navigation | `go_router` | `StatefulShellRoute` for the 5 tabs, keeping each tab's stack |
| Database | `drift` + `sqlite3` (SQLCipher build) | Typed SQL, migrations, reactive streams, encrypted at rest. `sqlcipher_flutter_libs` is end-of-life, so `pubspec.yaml` selects SQLCipher with `hooks: user_defines: sqlite3: source: sqlcipher`. The binary is fetched and checksum-verified at build time only |
| Files | `path_provider` | App support folder that holds the database |
| Secrets | `flutter_secure_storage` | Holds the random 256-bit DB and attachment keys |
| Models | Plain Dart classes, hand-written `fromJson` | One small content-pack model; a test loads the real `weeks.json`, so code generators (`freezed`, `json_serializable`) aren't needed |
| Icons | `path_parsing` (flutter.dev) | Turns the prototype's SVG path data into Flutter paths, so its own line icons are drawn exactly |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` | Local reminders scheduled with the OS (exact alarms on Android), no push. `timezone` lists `http` for its own data-download script; the app never calls it (ADR 020) |
| Health | `health` | M4b. Reads steps from HealthKit and Health Connect; never writes (ADR 030) |
| Audio | `just_audio` + `audio_service` | Background playback, lock-screen controls, sleep timer (M4a). M7b: the meditation timer is a playlist of two bundled assets (`assets/audio/bell.wav`, `quiet.wav`, generated by `tool/bell.dart`), so no new package. `audio_service` brings a download cache (`flutter_cache_manager` → `http`, `sqflite`) that Navmaas never calls (ADR 026) |
| Reading | `pdfrx` for PDF; built-in renderer for text/Markdown | M4a. PDFium is fetched at build time only. EPUB later (Plan decision 24) |
| Import / export | `file_picker` (open), `image_picker`, `share_plus` | Books and audio (`file_picker`, M4a); backup files are opened with `file_picker` and saved through the share sheet (`share_plus`, M5b), because `file_picker`'s save dialog needs the whole file in memory; `image_picker` (M3b) takes or chooses prescription photos through the system camera and photo picker, so no camera permission is declared |
| Backup | `cryptography` (Argon2id, ChaCha20-Poly1305) | See §11. The body is a simple stream of files, so `archive` isn't needed (Plan decision 33). `cryptography` also encrypts attachments with AES-256-GCM (M3b, §13) |
| Device | `url_launcher` | "Call clinic" opens the dialler; "Directions" opens Apple Maps or Google Maps on iPhone and the maps app on Android (ADR 024) |
| Security | `local_auth` (optional app lock) | Arrives in M10; not added yet |
| Utilities | `intl`, `uuid` (v7), `collection` | |
| Lints & tests | `very_good_analysis`, `flutter_test`, `mocktail` (when a fake needs it), `integration_test` | Golden tests for light/dark |
| Native | Swift platform channel `navmaas/files` (M1, keeps the database out of iOS backups); `home_widget` + Kotlin Screen Rest channel (P2) | The build expiry (M5a) is read in Dart from the app bundle, so it needs no channel (ADR 033) |
| Planned (Phases 2–3) | `pdf` (M9 visit summary), an unzip + XHTML parser such as `archive` + `html` (M9 EPUB), `home_widget` (M10), `local_auth` (M10) | Candidates only. Each is added only after the owner approves it at its milestone's start, then recorded here and in an ADR (§15). All must work offline |

Versions are pinned in `pubspec.lock`. M1 started on Flutter 3.47.3 / Dart 3.13.3 with the latest stable packages; upgrades are deliberate.

## 4. Project structure

Feature-first. Screens and widgets live in `lib/features/<feature>/`. A feature adds `data/` (repositories, table access), `domain/` (models, pure logic) and `presentation/` (screens, widgets, controllers) subfolders once it has more than screens. Tables used by several features (`pregnancy`, `settings`) live with their repositories in `core/db/`.

```
pregnancy-care/
├─ lib/
│  ├─ main.dart
│  ├─ app/                 # NavmaasApp, router, tab bar, theme mode, reminder sync + actions
│  ├─ core/
│  │  ├─ theme/            # AppTheme (tokens → ThemeData light/dark), NavmaasColors, brand mark, prototype icons
│  │  ├─ db/               # drift database, tables, key handling, attachment store, shared repositories, delete all data
│  │  ├─ pregnancy/        # pregnancy engine (pure Dart)
│  │  ├─ reminders/        # planner (pure), scheduler adapter, calm-notification settings, data reminders (build expiry)
│  │  ├─ content/          # content-pack loaders (weeks, India care template, daily activities)
│  │  ├─ widgets/          # shared widgets: pill segmented control, step button, icon motion, amber notice
│  │  ├─ platform/         # audio playback (M4a), steps (M4b), iPhone build expiry (M5a); later screen-rest channel
│  │  └─ utils/            # clockNow, todayProvider / nowProvider (clock), date-only maths and formatting
│  ├─ features/
│  │  ├─ onboarding/
│  │  ├─ today/            # today screen, today's plan card, "How are you today?" card (M7a), Screen Rest card
│  │  ├─ journey/          # journey screen; data/ checklist repository
│  │  ├─ sessions/         # data/ presentation/: library, reader, listen, letters, path (M4a); walk, exercise, breathing (M4b); meditation and the shared screen-off overlay (M7b)
│  │  ├─ care/             # data/ domain/ presentation/: supplements (M3a); vaccines & tests, visits, vitals (M3b)
│  │  ├─ third_trimester/  # data/ domain/ presentation/: kick counter, contraction timer, her patterns (M5a)
│  │  ├─ backup/           # data/: the .navmaas file format, the backup service, the backup log; presentation/: Backup & restore
│  │  ├─ screen_rest/      # data/ time in Navmaas, eye-rest setting; domain/ rest windows and nudges (pure); presentation/ Screen Rest (M6a)
│  │  ├─ wellbeing/        # data/ mood, symptom, sleep and water logs; domain/ the week, water nudges, chip folding (pure); presentation/ Wellbeing, mood, symptoms, sleep, water (M7a)
│  │  └─ settings/         # me (with this iPhone build), edit details, your doctor, pause or end tracking and the quiet "tracking stopped" page, the delete-all-data dialog
│  └─ l10n/app_en.arb      # every string; gen/ is generated by `flutter pub get`
├─ assets/
│  ├─ content/             # weeks.json (M2), care_template_in.json (M3b), activities.json (M4a), routines.json (M4b)
│  ├─ audio/               # bell.wav and quiet.wav for meditation (M7b), generated by tool/bell.dart
│  └─ fonts/               # Nunito, Literata (OFL)
├─ test/                   # unit, widget, accessibility; drift/ migrations; goldens/
├─ integration_test/      # on-device checks (reminders scheduled by the OS, the iPhone build expiry)
├─ drift_schemas/          # schema snapshots per schemaVersion
├─ android/  ios/
├─ design/                 # navmaas-tokens.css (prototype tokens)
├─ docs/                  # content/*.md are the generated review copies of the content packs
├─ tool/                  # content_md.dart regenerates the content review copies; bell.dart generates Meditation's bell and quiet clip
├─ .github/workflows/ci.yml
├─ build.yaml              # drift + riverpod codegen order
└─ CLAUDE.md               # commands and conventions for Claude
```

## 5. Layers and state

- **Repositories** expose `Stream`s from Drift queries (`watch…`) and `Future` commands. Screens never touch the database directly.
- **Controllers** (`Notifier` / `AsyncNotifier`) combine repositories with domain logic for each screen. For example, `todayPlanProvider` merges supplement schedules, the session plan and the next appointment.
- **One wall clock** (`core/utils/clock.dart`). `clockNow()` is the only place the app reads the time: row stamps, session starts, "today". Widget tests pin it to 9:00 on their fixed day (`pumpApp`), and fake time moves it on, so what the app writes falls on the day the screens show (ADR 031).
- **`todayProvider`** gives today's calendar date, so date-dependent logic (gestational age, reminders, build expiry) can be tested with a fixed date. `nowProvider` gives the time for time-of-day wording (the greeting). Both read `clockNow`, and the app refreshes them when it returns to the foreground.
- **Startup:** `main()` opens the database and waits for the first pregnancy values (active and latest) and theme values and the content pack before the first frame. It *listens* to those providers: Riverpod 3 pauses streams nobody listens to, and a plain `read` would wait forever.
- **Side effects** (scheduling notifications, Health reads, audio, file export) go through adapter interfaces, overridden with fakes in tests.

## 6. Pregnancy engine

This is pure date-only maths on calendar dates in the device's time zone, with no `DateTime` time-of-day arithmetic, so it is safe across DST.

| Dating method | Pregnancy start (gestational day 0) |
|---|---|
| Last period (LMP) | `lmp + (cycleLength − 28)` days |
| Conception | `conception − 14` days |
| IVF, day-5 embryo | `transfer − 19` days |
| IVF, day-3 embryo | `transfer − 17` days |
| Due date from scan | `scanEdd − 280` days |

- **Due date** = start + 280 days.
- **Gestational age** = today − start → `weeks = ga ~/ 7`, `days = ga % 7` (shown as "24 weeks 4 days").
- **Trimester:** 1 for < 14 w, 2 for < 28 w, 3 otherwise (boundaries 13w6d / 27w6d).
- **Month (display):** `ga ~/ 30.44 + 1`, capped at 10, so 24w4d shows as "Month 6".
- **Edge cases:**
  - Gestational age below 0, or above 44 weeks (more than 308 days, so from 44w1d), prompts the user to review the dates.
  - Past the due date, the app shows "due date + N days".
  - A twins flag changes copy only.
  - A paused, ended or delivered pregnancy isn't shown at all: the router replaces the tabs with one quiet page (Plan decision 31).
- **Storage:** dates are UTC-midnight `DateTime`s in code and `yyyy-MM-dd` text in the database.
- **Tests:** table-driven unit tests for every method, cycle lengths 21–40, leap years, month and year ends, trimester boundaries, below 0 / above 44 weeks, and DST. Expected dates are computed independently (Python `datetime`), not with the formulas under test.

## 7. Reminder scheduler

Every notification goes through one place, so the calm rules always apply.

```mermaid
flowchart LR
  S1["Supplement doses<br/>(not yet taken) + refills"] --> P
  S2["Appointments & care items"] --> P
  S3["Screen Rest nudges<br/>(meal times, wind-down)"] --> P
  S5["Backup & build-expiry<br/>reminders"] --> P
  P["Planner (pure)<br/>next 7 days"] --> Q["Meal times, quiet hours<br/>move or drop"]
  Q --> D["Bundle<br/>items within 30 min"]
  D --> B["Daily limit by priority<br/>extras → morning digest"]
  B --> X["Diff vs OS schedule<br/>stable ids"]
  X --> N["flutter_local_notifications<br/>exact, OS-scheduled"]
```

The planner (`core/reminders/planner.dart`) is pure Dart and table-tested; `ReminderSync` (`app/reminders.dart`) feeds it and hands the result to the scheduler adapter.

Sources (M3): untaken supplement doses and refills; visits the evening before (7 pm, mentioning questions waiting) and 2 hours before; booked tests, scans and vaccines the evening before; an unbooked one when its week window opens (10:00). M5a: the iPhone build expiry, the day before at 10:00. M6a: Screen Rest's nudges, a gentle notice as each meal window starts ("Meal time · Phone down — enjoy your meal.") and the wind-down nudge (off by default, 9:00 pm). M7a: water nudges ("Water · A glass of water, whenever you're ready."), off by default, every 2 or 3 hours from the end of quiet hours to their start (7:00 am – 9:30 pm when bedtime rest is off); today's stop once her water goal is reached (Plan decision 41).

Pregnancy reminders (supplements, visits, care items), Screen Rest's nudges and water nudges come only from the *active* pregnancy, so pausing or ending tracking stops them at once. Data reminders (build expiry; the weekly backup in M5b) keep running, because they protect her data.

1. **Rest windows** (Screen Rest, M6a; times also in Me):
   - **Quiet hours** ("Bedtime rest", default on, 9:30 pm – 7:00 am): reminders inside them move to their end; nudges are dropped. Switched off, there are no quiet hours.
   - **Meal times** (default on, 1:00–1:45 pm and 8:00–8:45 pm; each window 45 minutes from its start): reminders inside one wait until it ends (and then for quiet hours, if it ends inside them); other nudges there are dropped; the window's own notice is not held.
2. **Bundling:** reminders within 30 minutes of each other become one notification at the first time ("Supplements: Folic acid · Calcium"). Bundling happens before the limit, so a bundle counts once.
3. **Daily limit** (default 4, 1–8 in Me), by priority:
   1. Appointments.
   2. Build expiry and backup.
   3. Supplements.
   4. Care items.
   5. Nudges (Screen Rest's meal-time notices and wind-down; water).

   Over the limit, the rest fold into one morning digest at the end of quiet hours. If that morning has already passed, today's digest is skipped (the items are still on Today and in Care). Nudges never wait for the digest: a nudge over the limit is dropped, and when only nudges are over it there is no digest. The digest names three items, then "and N more".
4. **Rolling window:** only the next 7 days, at most 60 pending (iOS allows 64).
5. **Stable ids** (FNV-1a of the keys and time) let the sync cancel or replace exactly what changed; a changed title or body is rescheduled too. Snoozed reminders are left alone.
6. **On time, even when locked** (owner requirement, ADR 019): notifications are scheduled with the OS. iOS fires them on time whether the app is open or the phone is locked. Android uses exact alarms (`exactAllowWhileIdle`, `USE_EXACT_ALARM`; `SCHEDULE_EXACT_ALARM` on Android 12), falling back to inexact only if exact alarms are switched off. The plugin's boot receiver reschedules after a reboot.
7. **Re-planning:** on start, on resume (which also re-reads the time zone and picks up doses logged from a notification), and whenever the calm-notification settings, supplements or taken doses change, or today's water goal is reached (not on every glass).
8. **Permission:** asked in onboarding (optional step), from Me → Reminders, and once after the first supplement is saved. Reminders stay off until it's granted.
9. **Taps** (M6a): tapping the digest opens Today; tapping wind-down opens Listen on the audio she played last, already in screen-off mode (Sessions if she has no audio). Others open the app where she left it. A tap that launches the app is handled after the first frame.
10. **Actions:** dose notifications have "Taken" (logs every dose in the notification, one off the stock) and "Snooze 30 min". They work from a background isolate that opens the encrypted database itself. Refills: a 10:00 reminder while stock is at or below the refill level.

## 8. Data model

All tables use `id` (UUID v7, text), `created_at`, `updated_at` and a nullable `deleted_at` (soft delete); timestamps are stored as ISO-8601 text. This keeps the schema ready for an optional sync later. M1 created `pregnancy` and `settings`, M2 `checklist_tick`, M3a `profile`, `supplement`, `supplement_schedule` and `dose_log`, M3b `care_item`, `appointment`, `visit_question`, `attachment` and `vital_reading`, M4a `library_item`, `session` and `letter`, M5a `kick_session`, `contraction` and `backup_log`, M7a `mood_entry`, `symptom_entry`, `sleep_log` and `water_log`; the other tables arrive with their milestones.

```mermaid
erDiagram
  PREGNANCY ||--o{ SUPPLEMENT : has
  SUPPLEMENT ||--o{ SUPPLEMENT_SCHEDULE : "taken at"
  SUPPLEMENT_SCHEDULE ||--o{ DOSE_LOG : records
  PREGNANCY ||--o{ CARE_ITEM : tracks
  PREGNANCY ||--o{ APPOINTMENT : has
  APPOINTMENT ||--o{ VISIT_QUESTION : collects
  APPOINTMENT ||--o{ ATTACHMENT : stores
  PREGNANCY ||--o{ VITAL_READING : logs
  PREGNANCY ||--o{ SESSION : logs
  LIBRARY_ITEM ||--o{ SESSION : "used in"
  PREGNANCY ||--o{ LETTER : writes
  PREGNANCY ||--o{ KICK_SESSION : logs
  PREGNANCY ||--o{ CONTRACTION : logs
  PREGNANCY ||--o{ CHECKLIST_TICK : ticks
  PREGNANCY ||--o{ MOOD_ENTRY : "checks in"
  PREGNANCY ||--o{ SYMPTOM_ENTRY : logs
  PREGNANCY ||--o{ SLEEP_LOG : logs
  PREGNANCY ||--o{ WATER_LOG : logs

  PREGNANCY {
    string id PK
    string status "active | paused | ended | delivered"
    string dating_method "lmp | conception | ivf | scan"
    date lmp
    int cycle_length
    date anchor_date "conception, transfer or scan EDD"
    int embryo_day
    date start_date "derived, stored"
    date due_date "derived, stored"
    bool twins
    bool high_risk
    bool exercise_cleared
  }
  SUPPLEMENT_SCHEDULE {
    string id PK
    string supplement_id FK
    int minute_of_day
    int weekday_mask
    string label "after breakfast"
  }
  DOSE_LOG {
    string id PK
    string schedule_id FK
    datetime due_at "unique with schedule_id"
    datetime taken_at
    string status "taken (M3a); skipped | missed reserved"
  }
  SESSION {
    string id PK
    string pregnancy_id FK
    string type "reading | listening | walk | exercise | breathing | meditation"
    string library_item_id FK
    string routine_key
    datetime started_at
    int duration_sec
    int steps
  }
  CARE_ITEM {
    string id PK
    string pregnancy_id FK
    string template_key "unique per pregnancy"
    string kind "vaccine | test | scan"
    string title
    int from_week
    int to_week
    datetime scheduled_at "booked"
    datetime done_at
    string notes
  }
```

Tables not shown in detail:

| Table | Purpose |
|---|---|
| `profile` | M3a. One row: doctor name, clinic, clinic phone and clinic address (all optional; used for Call clinic and Directions on visits). The owner's first name is the `first_name` setting |
| `supplement` | M3a. Name, dose text exactly as prescribed (never suggested), notes, stock (doses left) and refill level. Unmarked doses aren't stored; the weekday mask lives on each schedule |
| `appointment` | M3b. Time, doctor, place (default from `profile`), notes, bring-along items (one per line) |
| `visit_question` | M3b. Waits unlinked for the next visit; ticking it as asked links it to that visit |
| `attachment` | M3b. Encrypted file name (in `db/attachments/`), MIME type, the visit it belongs to |
| `vital_reading` | M3b. `weight` (kg) or `bloodPressure` (systolic / diastolic, mmHg) and time. Logged only, never interpreted |
| `library_item` | M4a. Kind (`pdf` / `text` / `audio`), title, file name inside `db/library/`, audio length, and where she left off: `position` (PDF page, 0-based, or thousandths of the way through a text) out of `total`, plus `last_opened_at`. Not tied to a pregnancy. Reading progress lives here, so there is no separate `reading_progress` table |
| `session` | M4a. A reading session is logged when she leaves the reader after at least a minute; listening is one session per item played, growing while it actually plays (from one minute). M4b: a walk (with the steps Health counted during it), a routine (`routine_key`) or breathing, each logged from one minute. A walk keeps counting with the screen off; the others pause in the background. M7b: `meditation`, logged like listening (playing time, from one minute) from the timer's track or her own audio (then with its `library_item_id`); Finish or the end bell closes it, so the next one is a new session |
| `letter` | M4a. Letters to baby (body text), in the encrypted database |
| `kick_session` | M5a. Movements counted (`count`) from the first tap (`started_at`) to the last (`ended_at`). Saved with Save, or when she leaves with a count |
| `contraction` | M5a. Start and end of each timed contraction, saved when it ends (or when she leaves mid-way) |
| `checklist_tick` | M2. Ticked items from the weekly checklists: `pregnancy_id`, `item_key` (the content pack's stable key, e.g. `w24-gtt`), unique together. Unticking soft-deletes the row |
| `mood_entry` | M7a. One check-in a day (`day`, unique with the pregnancy): `mood` is a key (`calm` / `happy` / `okay` / `tired` / `low`), plus an optional `note`. Only today's can change |
| `symptom_entry` | M7a. `logged_at`, `symptom_key` (a pick-list key such as `backache` or `swollenFeet`) or her own `custom_name`, `severity` (`mild` / `moderate` / `strong`) and a `note`. Removing one soft-deletes it |
| `sleep_log` | M7a. One night per wake-up `day` (unique with the pregnancy): `bed_at`, `woke_at`, `nap_minutes` and `rested` (`rested` / `bitTired` / `veryTired`, optional) |
| `water_log` | M7a. Glasses on a `day` (unique with the pregnancy); + / − change the count, never below zero |
| `backup_log` | M5a (written from M5b). `kind` (`backup` / `restore`), `size_bytes`, `includes_library`; the row's `created_at` is when. Never the password |
| `settings` | Key-value. M1: `theme_mode` (`light` / `dark` / `system`, default system), `first_name`. M3a: `reminders_on`, `daily_limit` (1–8, default 4), `quiet_start` / `quiet_end` (minutes after midnight, default 1290 / 420), `reminders_offered`. M4a: `night_reading` (default on). M4b: `step_goal` (default 6,000). M5b: `backup_day` (weekly backup reminder, 1–7 for Monday–Sunday or 0 for off; default 7, Sunday). M6a (Screen Rest, ADR 037): `quiet_on` (bedtime rest, default on), `meal_rest` (default on), `meal_lunch` / `meal_dinner` (window starts, default 780 / 1200), `eye_rest` (default on), `wind_down` (default off), `wind_down_at` (default 1260), and `use_day` / `use_seconds` (time in Navmaas on that day, saved when the app leaves the screen). M7a: `water_goal` (glasses, 4–16, default 8), `water_remind` (default off), `water_every` (2 or 3 hours, default 2) and `wellbeing_card_hidden` (the day Today's "How are you today?" card was closed) |

Migrations are versioned with Drift's `schemaVersion` (1 in M1, 2 in M2: adds `checklist_tick`, 3 in M3a: adds `profile`, `supplement`, `supplement_schedule`, `dose_log`, 4 in M3b: adds `care_item`, `appointment`, `visit_question`, `attachment`, `vital_reading`, 5 in M4a: adds `library_item`, `session`, `letter`, 6 in M5a: adds `kick_session`, `contraction`, `backup_log`, 7 in M7a: adds `mood_entry`, `symptom_entry`, `sleep_log`, `water_log`). Upgrades use drift's step-by-step helper (`app_database.steps.dart`, generated). Schema snapshots live in `drift_schemas/`. `test/drift/navmaas/migration_test.dart` checks that the tables match the latest snapshot and that every older version migrates to every newer one. After a schema change: bump `schemaVersion`, write the migration, run `dart run drift_dev make-migrations`.

## 9. Content

| Source | Where | Rules |
|---|---|---|
| Week-by-week notes, checklists, India care template, daily activities, exercise routines | `assets/content/*.json`, versioned with `schemaVersion` | **Only original or public-domain text.** General information, no doses, no outcome claims |
| Garbhasanskar books (PDF / text) and audio | Imported in-app with `file_picker`, streamed into `<app support>/db/library/` (the folder OS backups skip); the DB stores the file name | Never leaves the phone except inside a backup the owner makes. Never committed to the repo |

- `weeks.json` (`schemaVersion` 1) has one entry per week, 4–42: `week`, `size` (an Indian fruit or vegetable, read after "About the size of"), `baby`, `you`, and `checklist` items as `{key, text}`. The key stays stable when wording changes, so ticks survive edits. The trimester is worked out from the week number, not stored.
- The text is original, written to the standard of an experienced obstetrician and approved by the owner. `docs/content/weeks.md` is its review copy, generated by `dart run tool/content_md.dart`; a test fails if the two differ.
- `care_template_in.json` (M3b, `schemaVersion` 1) lists the tests, scans and vaccines commonly offered in India: `key`, `kind` (`test` / `scan` / `vaccine`), `title`, `fromWeek`, `toWeek`, `note`. Each pregnancy gets one `care_item` per entry, created once (new entries are added on update). Every note defers to her doctor; review copy: `docs/content/care_template.md`.
- `activities.json` (M4a, `schemaVersion` 1): about 30 calm activities (`key`, `title`, `text`), original, no claims about what they do for the baby. The path's Activity tile shows one a day, by day of pregnancy, cycling. Review copy: `docs/content/activities.md`.
- A test enforces the hard lines on the content: no dose or unit words, no sex prediction, no outcome claims, no emergency or danger-sign wording.
- Wellbeing's words (M7a, Plan decision 43): the database stores keys (mood, symptom, severity, rested); their words live in `app_en.arb` under `moodWord*`, `symptomPick*`, `severity*` and `restedWord*`, like the supplement quick-pick names. The content test checks that every key has a word (and every word a key), and that no Wellbeing string has advice, warning, verdict or good/bad wording.
- `routines.json` (M4b, `schemaVersion` 1): `key`, `title`, `trimesters`, `avoidIfHighRisk` and timed `moves` (`name`, `how`, `sec`). Sessions shows the routines for the current trimester, hides the cautious ones when "High-risk pregnancy" is on, and keeps them locked until "Doctor cleared me for exercise" is on (Me; stored on `pregnancy`). Walking is always open (Plan decision 27). Every routine and walk shows the same general line instead of a "stop if" list (Plan decision 26), so routines carry no note of their own. No move lies flat on the back (a test checks). Review copy: `docs/content/routines.md`.

## 10. Platform integrations

| Capability | MVP behaviour | Platform notes |
|---|---|---|
| Steps & walks (M4b) | Reads today's steps and the steps during a walk (asked on the first walk, re-read every 30 s); records walk sessions in Navmaas. Never writes to Health | iOS: HealthKit entitlement (`Runner.entitlements`, available to a free Apple ID) and a read-only usage string. Android: `health.READ_STEPS`, Health Connect queries, the permissions-rationale intent filter and the Android 14 `VIEW_PERMISSION_USAGE` alias; min SDK 26. On Android 9–13 the Health Connect app comes from the Play Store; Android 8 has none, so steps show "—" |
| Background audio (M4a) | Plays with the screen off and shows lock-screen controls (back / forward 15 s, play / pause); sleep timer of 10, 20 or 30 min. The audio service starts on first play, not at app start. M7b: the meditation timer plays as one track (bell, 30 s quiet clips with the last one clipped, bell at exactly 5–20 min), so it keeps time and rings with the phone locked; its position and length cover the whole track | iOS `UIBackgroundModes` → `audio` (available to a free Apple ID); Android `AudioService` media foreground service (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`) and `MainActivity` extends `AudioServiceFragmentActivity` |
| "Screen off — keep listening" | Switches to a near-black overlay that wakes on tap, and lets the phone lock normally | No wakelock is held |
| Calls and maps (M3b) | "Call clinic" opens the dialler; "Directions" opens Apple Maps or Google Maps (if installed) on iPhone, or the default maps app on Android, with the clinic address | Android declares `tel` and `geo` intent queries; iOS lists `comgooglemaps` to check Google Maps is installed. The maps app does any network use; Navmaas doesn't |
| Prescription photos (M3b) | Take or choose a photo; it's encrypted before it touches disk | iOS camera and photo-library usage strings; Android uses the system photo picker and camera, so no permission |
| Backup files | Save through the share sheet ("Save to Files" on iPhone; Files, Drive or another app on Android); open with the system file picker | Other apps (e.g. Google Drive) do the uploading; Navmaas itself stays offline |
| Build expiry (iOS) | Reads the signing expiry date from the app bundle's provisioning profile; shows it in Me and on Today, and reminds before it | §12 |
| Screen Rest (M6a) | In-app only: rest windows that hold reminders (§7), time in Navmaas today (`AppLifecycleListener`: counted while on screen, saved when it leaves), a 20-second eye rest every 20 minutes of reading, the wind-down nudge | No special permissions |
| Screen Rest (P2) | Gentle limits on apps she picks — **Android only** | `UsageStatsManager` + WorkManager (Kotlin). Not possible on iOS with a free Apple ID: Family Controls needs a paid membership |

## 11. Backup and restore

The backup is a single password-protected file (`navmaas-backup-YYYY-MM-DD.navmaas`) that the owner saves wherever she likes. It is the only way data survives a lost phone, a deleted app or a move to a new phone.

```mermaid
flowchart TB
  subgraph Create["Create backup"]
    C1["Password ×2<br/>(min 8 chars, never stored)"] --> C2["VACUUM INTO<br/>(consistent, still encrypted)"]
    C2 --> C3["Snapshot: DB copy,<br/>attachments,<br/>library (optional)"]
    C3 --> C4["manifest.json (last)<br/>DB key, attachment key, counts"]
    C4 --> C5["File stream<br/>(length-prefixed)"]
    C5 --> C6["Argon2id(password, salt)<br/>ChaCha20-Poly1305 in 1 MiB chunks"]
    C6 --> C7[".navmaas file<br/>Save to Files or share"]
  end
  subgraph Restore["Restore"]
    R1["Pick .navmaas file"] --> R2["Read header<br/>show date, size, app version"]
    R2 --> R3["Password → decrypt<br/>(tag failure = wrong password or damaged file)"]
    R3 --> R4["Unpack to a staging folder<br/>every piece authenticated"]
    R4 --> R5["PRAGMA rekey to<br/>this phone's DB key"]
    R5 --> R6["Move db/ aside (rollback),<br/>staging → db/, reopen<br/>(migrations run if older)"]
    R6 --> R7["Re-plan reminders<br/>delete staging + rollback"]
  end
```

### File format (version 1)

| Part | Content | Encrypted |
|---|---|---|
| Magic | `NAVMAAS` + format byte, 8 bytes | No |
| Header | JSON with format version, KDF parameters (`argon2id`, memory, iterations, parallelism, salt), cipher, chunk size, created date, app version, schema version, whether the library is included | No, but authenticated: its hash is part of every chunk's associated data |
| Body | The files one after another (each: 2-byte name length, name, 8-byte size, bytes; `manifest.json` last), split into 1 MiB chunks. Each chunk = 12-byte nonce + ChaCha20-Poly1305 ciphertext + 16-byte tag. Associated data = header hash + chunk index + "last chunk" flag, so chunks can't be reordered, dropped or truncated unnoticed | Yes |

### Rules

- **Password:**
  - At least 8 characters, typed twice, with a show/hide toggle.
  - Never stored, logged or included in `backup_log`.
  - There is no recovery: the screen says so before the backup is created.
- **Key derivation:** starts at Argon2id with 64 MiB memory, 3 iterations and 1 lane.
  - Measured in M5b (compiled Dart): 0.45 s on an M-series Mac, so a low-end phone should stay near the ~3 s target. Check on the phone; tune if it's slower.
  - Key derivation and encryption run in a background isolate, so the screen stays smooth.
  - The parameters live in the header, so they can change later without breaking old backups.
- **Consistent snapshot:** `VACUUM INTO` writes a consistent copy of the database, still SQLCipher-encrypted with its key (ADR 035). The DB key and the attachment key travel in the manifest, inside the password-encrypted body.
- **Integrity:** every 1 MiB piece is authenticated (ChaCha20-Poly1305 tag, header hash, index, last-piece flag), and each file's size is checked, so per-file hashes aren't needed. A failure on the first piece is reported as a wrong password, later ones as a damaged file. File names are checked so a crafted backup can't write outside its folder.
- **Streaming:** files are read and encrypted piece by piece into one reused buffer, so a 500 MB library never sits in memory (a test checks memory doesn't grow with its size).
- **Saving:** the finished file is handed to the share sheet ("Save to Files" on iPhone; Files, Drive or another app on Android). A picked backup is copied onto the phone first, so it can be read in pieces.
- **Library is optional:**
  - With the library off, a backup is small (a few MB) and quick to send.
  - With it on, the backup includes imported PDFs and audio.
  - When restoring a backup without the library, library entries stay listed. On the same phone the books and audio already there are kept; on a new phone, opening one asks her to choose the same file again ("Re-import file"), and her place in it stays.
- **Restore is all-or-nothing:**
  - Any failure (wrong password, damaged piece, a newer format or schema than this app understands) leaves the current data untouched.
  - The backup is unpacked into its own staging folder and its database rekeyed to this phone's key; the backup's attachment key replaces this phone's (ADR 036).
  - The swap moves `db/` aside to `db-before-restore/`, moves the staging folder in and reopens the database. If it doesn't open, everything (and the attachment key) is put back. If the app stops mid-swap, the next start puts the old data back.
  - Restore can be started from onboarding (a new phone), from Me, or from the "tracking stopped" page.
- **Reminders:**
  - A weekly backup reminder at 10:00 on her chosen day (Sunday by default, or off), skipped when she backed up in the 6 days before it (Plan decision 32).
  - On iOS, the reminder the day before the build expires also says "back up" (§12); no separate weekly reminder that day.
  - Both keep running while tracking is paused or ended.
- **What is not in a backup:** scheduled notifications and caches, which are re-created after restore. The backup also contains no password hint.

## 12. iPhone with a free Apple ID

Apple's [capabilities table](https://developer.apple.com/help/account/reference/supported-capabilities-ios) sets what a personal team (free Apple ID) can sign.

| Capability | Free Apple ID | Navmaas use |
|---|---|---|
| HealthKit | ✓ | Reading steps |
| Background Modes | ✓ | Audio with the screen off |
| Data Protection | ✓ | File protection classes (below) |
| Keychain | ✓ | DB and attachment keys |
| App Groups | ✓ | P2 home-screen widget |
| Family Controls | ✗ | Other-app Screen Rest is Android-only |
| Push notifications, iCloud | ✗ | Not needed: local reminders, file backups |

### The 7-day expiry

- **Behaviour:** a free-team build stops opening 7 days after it was signed. Running it again from Xcode (same Apple ID, same bundle ID) installs over the existing app and **keeps all data and Keychain items**.
- **Detecting it:**
  - Dart reads `embedded.mobileprovision` next to the app's executable (`Platform.resolvedExecutable`, inside `Runner.app`; ADR 033).
  - The profile is a signed envelope around a plain XML plist, so `parseProvisionExpiry` finds `ExpirationDate` as text.
  - On Android, the simulator, or when the file is absent, it's `null` and nothing is shown.
  - `integration_test/build_expiry_test.dart` checks it on the phone: within the next 7 days on an iPhone, `null` on the simulator.
- **Surfacing it:**
  - Me shows "This iPhone build · Expires Sat 10 Oct · in 6 days" (an amber card).
  - Today shows a quiet amber banner when 1 day is left.
  - The reminder planner schedules a notification the day before at 10:00 ("back up, then run it from Xcode again"). It keeps running while tracking is paused or ended.
  - If the build lapses, the app won't open (and reminders may stop) until it's run from Xcode again. Data stays on the phone.
- **Data-loss traps:**
  - **Deleting the app** deletes its data.
  - **Changing the Apple ID** changes the Team ID and Keychain group, so the stored DB key can't be read.
  - **Changing the bundle ID** installs a new, empty app.

  In all three cases, restore from the latest backup.

### Personal install steps

1. Enable Developer Mode on the iPhone (Settings → Privacy & Security). Trust the developer certificate after the first install (Settings → General → VPN & Device Management).
2. In Xcode, open `ios/Runner.xcworkspace` and choose the personal team. The bundle ID is `com.patelkeyur.navmaas`; keep it the same forever.
3. Install a **release** build (`flutter run --release` with the phone connected, or Xcode with the Release scheme). Flutter debug builds on iOS only start from the debugger, not from the home screen.
4. Repeat step 3 within 7 days. The app reminds you the day before.

**File protection.** The DB and library use `completeUntilFirstUserAuthentication` (the iOS default, so nothing is set explicitly), so notification actions and background audio work while the phone is locked. Attachments use `complete`. The DB key uses Keychain accessibility `first_unlock_this_device`.

**OS backups.** iCloud and Finder backups stay on, but the database folder is marked `isExcludedFromBackup` (through the `navmaas/files` channel) and its key never leaves the device. Restoring an iPhone backup therefore doesn't bring Navmaas data back; the `.navmaas` file (§11) does. Android behaves the same way (below).

**Android.** Install a release APK signed with a local keystore that is never committed: release builds read `android/key.properties` (git-ignored) and fall back to the debug key when it's missing, which keeps CI free of secrets. Auto Backup stays on (`allowBackup=true`), but `res/xml` backup rules exclude `files/db/` and the shared preferences that hold the key, because Android Keystore keys can't be restored on another phone. Keep the keystore safe: updates must be signed with the same key, or the old app has to be removed, which deletes its data. That case also needs a restore from backup.

## 13. Security and privacy

- **Network:** the app makes no network calls. Release Android builds omit the `INTERNET` permission (the main manifest removes it with `tools:node="remove"`, which also strips it from plugins), so the app itself cannot send data anywhere; debug and profile builds keep it for hot reload. Fonts are bundled.
- **Permissions (Android release):** `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM` (Android 12 only) and `VIBRATE` (added by the notification plugin); `WAKE_LOCK`, `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` for background audio (M4a); `health.READ_STEPS` for walks (M4b). Never `INTERNET`; `ACCESS_NETWORK_STATE`, which a plugin asks for, is removed the same way.
- **Database:** encrypted with SQLCipher. A random 256-bit raw key is generated on first run and kept in Keychain / Android Keystore. The app refuses to open the database on a build without SQLCipher. The database and its key are excluded from OS backups on both platforms (§12).
- **Attachments** (prescription photos, reports) are encrypted with AES-256-GCM under a separate stored key (`navmaas.attachments_key.v1`), as nonce + ciphertext + tag, in `db/attachments/` inside the folder OS backups skip. Photos are only decrypted in memory to show them. Imported books and audio stay as plain files in `db/library/`, skipped by OS backups; they are the owner's own media, not health data, and audio must stream to the player.
- **Backups:** encrypted with a key derived from the owner's password (§11). The password is never stored.
- **Optional app lock** with biometrics or the device passcode (`local_auth`), off by default (M10).
- **Deletion** (M6b): Me → Your data → "Delete all data" (red) opens a dialog that says what goes, shows when she last backed up with "Back up first", and a red "Delete everything". It cancels every reminder (snoozed ones too) and pauses audio, moves `db/` aside to `db-deleted/`, deletes both keys from Keychain / Keystore, opens a new, empty database under a new key (so the app starts again at onboarding), then deletes `db-deleted/`, any restore rollback, the backup work folders and the file picker's copies in the cache. If the app stops part-way, the next open deletes `db-deleted/`. It does not touch backup files saved elsewhere (ADR 040).
- **Repository hygiene:**
  - No keystores, provisioning profiles, `google-services` files or personal content in git.
  - `.gitignore` covers `*.jks`, `key.properties`, `*.mobileprovision`, `*.navmaas` and `/library`.

## 14. Theming and accessibility

- Tokens from [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) become `ThemeData.light/dark`: a `ColorScheme` plus the `NavmaasColors` extension. `ThemeMode` is user-selected (Light / Dark / System).
- The reader has its own Paper / Night palette. It opens in Night from 9 pm to 5 am when "Night reading after 9 pm" is on (the default), or whenever the app is dark.
- **Accessibility:**
  - `MaterialTapTargetSize.padded` and minimum 48 dp targets.
  - `Semantics` labels on icon-only buttons; password fields announce show/hide state.
  - Text follows `MediaQuery.textScaler` and is tested at 1.0, 1.3 and 2.0. Tab-bar labels stop growing at 1.5× so five tabs still fit; screens follow the full size.
  - `test/accessibility_test.dart` checks every screen: no overflow, Flutter's tap-target, labelled-target and text-contrast guidelines (light and dark), and reduce motion.
  - Motion respects `MediaQuery.disableAnimations`. The four icon micro-interactions are listed in DESIGN_SYSTEM §5; all are instant under reduce motion.

## 15. Delivery milestones

Phase 1 (the MVP, M1–M6) is complete. Phase 2 (M7–M11) adds the enhancements and Phase 3 (M12–M14) adds postpartum and baby mode. **Family sharing is out of scope** for both (Plan decision 37, ADR 042); everything else in the Plan's feature map is in scope.

### Phase 1 — MVP ✅ 2026-10-06

| Milestone | Scope | Done when |
|---|---|---|
| **M1 Foundation** ✅ 2026-10-05 (PR #2) | Flutter project, lints, CI, theme + fonts, router with 5 tabs, Drift + SQLCipher, pregnancy engine, onboarding, settings, release install on a free-Apple-ID iPhone | Onboarding stores a pregnancy; Today shows the correct week in light and dark on both phones |
| **M2 Today & Journey** ✅ 2026-10-05 (PR #4) | Content-pack loader, Journey (trimester tabs, week picker, notes, checklists, trimester progress), size line on Today. `weeks.json` text drafted (original) by Claude and approved by the owner. The prototype's own line icons with calm tap motion. Editable first name in Me. M1 screens matched to the prototype | Golden tests pass for both themes |
| **M3a Supplements & reminders** ✅ 2026-10-05 | Doctor profile (optional onboarding step 3 of 4, Me), calm-notification settings, supplements (quick-pick names, dose as prescribed), reminder planner + OS scheduler with exact alarms, Taken / Snooze actions, **Today's plan card** (supplements; reading joined in M4a, the walk in M4b), Journey's "supplements taken" tile | Reminders respect the limit and quiet hours in tests and are scheduled by the OS on a device |
| **M3b Care: tests, visits, vitals** ✅ 2026-10-05 | India care template (Claude drafts, owner approves), care items under "Coming up", visits with questions, bring-along, notes, encrypted prescription photo, next visit, Call clinic and Directions (Apple / Google Maps), weight and BP logs, next-visit card on Today | Visit and care-item reminders follow the same calm rules; a prescription photo is encrypted on disk |
| **M4a Library & reading** ✅ 2026-10-05 | Schema v5, library import (PDF / text / audio), Sessions tab with the Garbhasanskar path (read, listen, original daily activity, talk to baby), reader with 15-min timer and Paper / Night, background audio with lock-screen controls, sleep timer and screen-off, letters to baby, reading on Today's plan, Journey's "reading sessions" tile, "Night reading after 9 pm" in Me | A 15-min reading is logged end to end (widget test) |
| **M4b Walk & exercise** ✅ 2026-10-05 | Walk with Health steps and a daily step goal, exercise routines (Claude drafts, owner approves) locked behind "doctor cleared me" and filtered for high risk, slow breathing, Me → Exercise switches, Move & breathe on Sessions, walk on Today's plan, Journey's "walks logged" tile | A 20-min walk is logged end to end (widget test) |
| **M5a Third trimester & build expiry** ✅ 2026-10-06 | Schema v6, kick counter and contraction timer (Care tiles), pause / baby has arrived / end tracking with one quiet page, iPhone build expiry in Me, on Today and as a reminder | Pausing stops baby content and pregnancy reminders (widget test); the expiry date shows correctly on the iPhone |
| **M5b Backup & restore** ✅ 2026-10-06 | Backup & restore (§11) from Me, onboarding and the quiet page, weekly backup reminder, re-import for books and audio left out of a backup | A backup made on one phone restores on another; a wrong password changes nothing (unit tests with two "phones"; on the simulator: `integration_test/backup_test.dart`) |
| **M6a Screen Rest** ✅ 2026-10-06 | Screen Rest screen and Today card, rest rules (bedtime, meal times, eye rest, wind-down) in the planner, time in Navmaas today, digest polish (no nudges in the digest, "and N more", taps open Today or her audio) | Meal windows and quiet hours hold reminders in tests; wind-down opens her audio with the screen off (widget test) |
| **M6b Delete all data & release** ✅ 2026-10-06 | Delete all data (§13), accessibility pass (every screen has a heading; reader, listen, walk, breathing, sheets and dialogs fixed), release builds (README install steps, CI size check, universal limit 150 MB) | Signed APK installed; iPhone renewed through one 7-day cycle without data loss (owner checks on the phones) |

### How every Phase 2 and 3 milestone runs

These rules apply to every milestone below, on top of its own "done when":

1. **Design first.** The milestone's new screens are added to the prototype canvas, in light and dark, and approved by the owner before any code. The prototype is the exact visual spec (Plan decision 15, ADR 043).
2. **Owner decisions first.** Each milestone lists what the owner decides at its start. The answers go into the Plan's decision table.
3. **Packages.** Anything beyond §3 is approved by the owner at the milestone's start, then recorded in §3 and an ADR. Nothing may make network calls, and release builds keep no `INTERNET`.
4. **Content.** New content packs are original, drafted by Claude and approved by the owner. Each gets a review copy in `docs/content/`, and the content hard-line test is extended to it.
5. **Schema.** A milestone that adds tables or columns bumps `schemaVersion` once and adds migration tests for every version pair. The backup round-trip covers the new data, and a backup from an older version restores and migrates.
6. **Reminders** go only through `ReminderSync` and follow §7's calm rules.
7. **Quality bar:**
   - `dart format`, `flutter analyze` (zero issues) and every test green in CI.
   - Goldens for new screens in light and dark (macOS and Linux sets).
   - Every new screen added to `test/accessibility_test.dart`.
   - The phone APK stays under 100 MB.
8. **Docs in sync** in the same PR. Split a milestone into a/b PRs when it is too big to review in one, as in Phase 1.

### Phase 2 — Enhancements (M7–M11)

| Milestone | Focus | Schema |
|---|---|---|
| **M7** ✅ | Wellbeing: mood, symptoms, sleep, water, meditation. M7a ✅ 2026-10-06 (PR #18); M7b ✅ 2026-10-06 (PR #19) | v7 |
| **M8** | Body and birth prep: blood sugar, nutrition notes, hospital bag, birth plan | v8 |
| **M9** | Records vault, visit summary PDF, EPUB books | v9 |
| **M10** | Home-screen widgets and app lock | No change (settings only) |
| **M11** | Limits for other apps (Android) and the Phase 2 release | v10 |

#### M7 Wellbeing ✅

**Scope**
- Schema v7: `mood_entry`, `symptom_entry`, `sleep_log`, `water_log`, and a `meditation` session type.
- Care → **Wellbeing** screen with a 7-day view of everything below.
- **Mood:** one check-in a day from five words (no emoji), with an optional note. No scores, screening or advice.
- **Symptoms:** pick from common pregnancy discomforts or add her own; mild / moderate / strong; a note. It is a log for her and her doctor: never advice, never a warning list.
- **Sleep:** bedtime, wake time, naps and how rested she feels (in words); weekly average.
- **Water:** tap to add a glass toward a goal she sets. Optional reminders are nudges, off by default.
- **Meditation** (Sessions → Move & breathe): a 5, 10, 15 or 20-minute timer with a soft start and end bell (an original, generated sound), or her own imported audio. Works with screen-off; logged from one minute.
- **Today:** an optional, dismissible "How are you today?" card with water taps.

**Owner decides at the start:** the symptom pick-list, the five mood words, and whether water has a default goal.

**Done when**
- Mood, symptom, sleep and water entries are saved and shown in the 7-day view (widget tests, light and dark).
- Meditation logs a session from one minute, with and without screen-off (widget test).
- Water reminders respect quiet hours, meal windows and the daily limit, and never join the digest (planner tests).
- The content test rejects advice and warning wording in the symptom list and the mood words.

**Owner's answers** (Plan decisions 39–45): ten common discomforts plus her own; Calm · Happy · Okay · Tired · Low; water goal 8 glasses by default (4–16), reminders every 2 or 3 hours; a generated bell played as one background-audio track; keys in the database, words in `app_en.arb`; split into M7a and M7b (ADR 044).

**Status:** **M7a ✅ 2026-10-06 (PR #18)**: schema v7, Care → Wellbeing (today's four logs, the week and the weekly sleep average), mood check-in, symptom log (chips folded to two rows with More), sleep entry, water with its goal and reminders, Today's "How are you today?" card, water nudges through `ReminderSync`, backup and delete covering the new tables, goldens and accessibility for every new screen. **M7b ✅ 2026-10-06 (PR #19)**, stacked on M7a: Sessions → Meditation (5, 10, 15 or 20 minutes between two original bells from `tool/bell.dart`, played as one background-audio track), her own audio as meditation (Listen, logged as meditation), the screen-off overlay shared with Listen, the `meditation` session type.

#### M8 Body and birth prep

**Scope**
- Schema v8: a `context` column on `vital_reading`; new tables `meal_note`, `avoid_food`, `bag_item` and `birth_plan_answer`.
- **Blood sugar** in Vitals:
  - Each reading has mg/dL, a context (fasting, before a meal, 1 h or 2 h after, bedtime), a time and a note.
  - Readings are listed by day, with no ranges, colours or labels such as "high".
- **Nutrition notes** (Care):
  - Meal notes by day.
  - "Foods I avoid": her own list, with an optional reason such as "doctor's advice".
  - The app gives no food guidance of its own.
- **Hospital bag** (a Care tile from week 28, always reachable from Care):
  - An original template, `hospital_bag.json`, with items for her, for the baby and documents.
  - She can add her own items and tick each one as packed.
  - An optional reminder she sets.
- **Birth plan** (Care):
  - Original prompts in `birth_plan.json`: who will be with you, comfort preferences, after the birth, feeding wishes, anything else.
  - She answers in her own words, under the line "Talk this through with your doctor".

**Owner decides at the start:** the hospital bag template and the birth-plan prompts.

**Done when**
- Blood-sugar readings are saved and listed with their context, and no screen judges a value (widget tests; the content test covers the labels).
- Hospital bag ticks persist per pregnancy and survive template edits (stable keys, like `weeks.json`).
- Birth plan answers are saved and editable.
- Both content packs have generated review copies and pass the hard-line test.

#### M9 Records vault, visit summary PDF and EPUB

**Scope**
- Schema v9: `attachment` gains `category` (report / scan / prescription / other), `title`, `taken_on` and `size_bytes`, and its visit link becomes optional.
- **Records** (Care):
  - Add from the camera, photos or files (images or PDF), up to 25 MB each.
  - Encrypted through `AttachmentStore` like prescription photos, which now appear under Prescriptions.
  - Viewed in memory only; PDFs open through `pdfrx` from bytes.
  - Sharing a record hands a decrypted copy to the share sheet, says that copy isn't encrypted, and deletes it afterwards.
- **Visit summary PDF** (from a visit or from Me):
  - She chooses the sections and dates: pregnancy summary, supplements taken, vitals (weight, BP, blood sugar), questions, kick and contraction averages, wellbeing log, birth plan, list of records.
  - Made on the phone with `pdf` and the bundled fonts, showing values only.
  - Shared through the share sheet; the temporary file is deleted afterwards.
- **EPUB books:**
  - Import DRM-free `.epub` files.
  - Chapters become text in the existing reader, with Paper / Night, eye rest and her place kept.
  - Images and complex layout are skipped.

**Owner decides at the start:** the packages (`pdf`; for EPUB, e.g. `archive` + `html`), and the PDF's sections and default date range.

**Done when**
- Records on disk carry no image or PDF signature, and no plaintext copy is left anywhere after viewing or sharing (unit tests).
- The PDF contains only the chosen sections, and its text has no interpretation words (text-extraction test).
- A small EPUB built in the test opens with its chapters and reopens at the same place (widget test).
- Records are in backups, and the v9 migration shows existing prescription photos under Prescriptions.

#### M10 Home-screen widgets and app lock

**Scope**
- **Widgets** (`home_widget`):
  - An iOS WidgetKit extension (`com.patelkeyur.navmaas.widget`, App Group `group.com.patelkeyur.navmaas`; both are available to a free Apple ID, §12) and an Android app widget.
  - They show the week and day, the baby-size line and the next reminder. Tapping opens Today.
- **Widget privacy:**
  - The widget reads only a small snapshot the app writes whenever Today or the reminders change, never the database.
  - "Hide details on widget" (Me) leaves only the brand mark and the next reminder's time.
  - While tracking is stopped, the widget shows only the brand mark.
- **App lock** (Me → Your data, off by default, `local_auth`):
  - Face ID, Touch ID or fingerprint, falling back to the device passcode.
  - Locks on open, and after 1, 5 or 15 minutes away.
  - Notification actions keep working while locked.
  - With app lock on, the widget hides details by default.

**Owner decides at the start:** the default for "Hide details", and the lock-timeout choices.

**Done when**
- The widget updates within a minute of logging, on both phones (on-device check).
- The iPhone widget keeps working through one 7-day renewal (one Xcode run signs both targets).
- The hidden-details snapshot contains no week, size or baby text (unit test).
- A notification tap or widget tap can't open a screen without unlocking, and failed biometrics fall back to the passcode (widget tests with a fake authenticator).

#### M11 Limits for other apps (Android) and the Phase 2 release

**Scope**
- **Android only.** The card stays hidden on iPhone, because Family Controls needs a paid membership (§12, ADR 012).
- Screen Rest → **Limits for other apps** (the prototype's Phase 2 card):
  - She grants Usage access, picks launchable apps (via a launcher `<queries>` entry, no `QUERY_ALL_PACKAGES`) and sets daily minutes for each.
  - Today's minutes for each chosen app show on Screen Rest.
- **The notice:**
  - Once an app passes its limit, she gets one gentle notice per app per day. Nothing is blocked.
  - The notice counts as a nudge, so it follows quiet hours, meal windows and the daily limit.
- Schema v10: `app_limit` (package, label, minutes).
- **How it checks:**
  - Kotlin `UsageStatsManager` + WorkManager every 15 minutes, only while a limit is set.
  - How the native check hands the notice to the planner's rules is decided and recorded as an ADR at the start.
- **Phase 2 release:**
  - The integration tests deferred from Phase 1: onboarding → Today; Taken from a notification action; import a PDF and log a reading session.
  - An accessibility pass over all Phase 2 screens.
  - Release builds on both phones.

**Owner decides at the start:** the wording of the notice, and the minute steps for limits.

**Done when**
- The notice arrives within about 15 minutes of passing a limit, never in quiet hours, and once per app per day (on-device check on Android).
- Revoking Usage access shows a calm "turned off" state. With no limits set, no worker runs.
- The only new permission is `PACKAGE_USAGE_STATS`, and there is still no `INTERNET`.
- The deferred integration tests pass on both phones, and the Phase 2 release builds are installed (owner checks on the phones).

### Phase 3 — Postpartum and baby (M12–M14)

| Milestone | Focus | Schema |
|---|---|---|
| **M12** | Postpartum mode and her recovery | v11 |
| **M13** | Baby feeding and sleep | v12 |
| **M14** | Baby vaccines and visits, and the Phase 3 release | v13 |

#### M12 Postpartum mode and her recovery

**Scope**
- Schema v11: `baby` (pregnancy, optional name, birth date and time, birth weight and length as recorded).
- **"Baby has arrived"** now leads to **postpartum mode**, after a short baby-details step (twins get two babies), instead of the quiet page.
  - Pause and End still show the quiet page.
  - This changes Plan decision 31 for "Baby has arrived" only.
- **Postpartum tabs and Today** (designed first) show her recovery week by week and the baby's age in weeks and days.
- **Content:** `postpartum_weeks.json` covers weeks 0–12. It is original text about her body, rest and recovery, with nothing that needs a doctor's judgement, plus checklists such as booking her postnatal check-up.
- **What carries on:** her supplements, visits, records, wellbeing and letters continue from the pregnancy. Pregnancy-only content and reminders (week ring, Journey, pregnancy tests and scans) stop.
- **Ending it:** "End postpartum tracking" goes to the quiet page; "Start a new pregnancy" still works.

**Owner decides at the start:**
- The data model. Proposed: the delivered pregnancy stays the anchor and babies link to it, recorded as an ADR.
- The postpartum tabs.
- The content pack.

**Done when**
- Baby has arrived → baby details → postpartum Today shows the right ages, in light and dark (widget test).
- Twins get two babies, and Pause and End still show the quiet page (widget tests).
- In postpartum mode the week ring, Journey and pregnancy test reminders are gone, while supplement and visit reminders continue (widget and planner tests).
- The content pack's review copy and hard-line test pass.

#### M13 Baby feeding and sleep

**Scope**
- Schema v12:
  - `feed`: baby, kind (breast / bottle / pumping), side, start, end, amount in ml, milk type, note.
  - `baby_sleep`: baby, start, end, note.
- **Feeding:**
  - A breastfeeding timer with left / right, switch side and pause.
  - Bottle and pumping entries.
  - The last feed and which side; today's count and totals.
- **Baby sleep:** a start/stop timer or an entry added afterwards; naps; today's total.
- **Patterns:** her own averages, never a verdict, like the kick counter.
- **Night-friendly:** big one-handed targets, dark at night, and timers that keep running with the screen off or the app in the background.
- **Feeding reminders:** optional, at an interval she sets (never a suggested one), with her choice whether they ring during quiet hours.
- **Twins:** every log belongs to one baby.

**Owner decides at the start:** whether feeding reminders may ring in quiet hours (a planner rule change, recorded as an ADR), and the amount units.

**Done when**
- A feed and a sleep keep running in the background and are logged correctly (widget tests with fake time).
- Patterns match hand-computed averages and show no judgement (unit tests).
- Feeding reminders follow the chosen quiet-hours rule (planner tests).
- The new screens pass the accessibility test at 2.0× text in the dark theme.

#### M14 Baby vaccines and visits, and the Phase 3 release

**Scope**
- Schema v13: `care_item` and `appointment` gain an optional `baby_id`, and the pediatrician's details sit beside her doctor's in `profile`.
- **Baby vaccines:**
  - An India schedule by age, `baby_vaccines_in.json`: original wording that follows India's public national schedule, with every item deferring to the pediatrician.
  - Dates are worked out from the birth date.
  - Book, mark done, and calm reminders.
- **Baby visits:** questions, notes and records for the baby, using the existing visit screens with a "for me / for baby" choice.
- **Baby across the app:**
  - A baby filter in the records vault.
  - A baby section in the visit summary PDF (feeds, sleep, vaccines given).
  - In postpartum mode, the widget shows the last feed and the next vaccine.
- **Phase 3 release:** accessibility pass, release builds on both phones, and one iPhone 7-day renewal.

**Owner decides at the start:** the vaccine template (Claude drafts, the owner approves), and what the postpartum widget shows.

**Done when**
- Vaccine dates are right for any birth date, including month ends and leap years. Table-driven tests check them against independently computed dates, as for the pregnancy engine.
- Booked and due vaccines remind under §7's rules.
- A baby visit and its records show under the baby, and the PDF's baby section has only the chosen data.
- The Phase 3 release builds are installed and survive a renewal without data loss (owner checks on the phones).

### Out of scope

- **Family sharing** (Plan decision 37, ADR 042). It would need a backend and accounts; Navmaas stays local-only, with no network calls.

## 16. Testing and CI

- **Unit tests:** pregnancy engine; database encryption (no SQLite header or plaintext, unreadable without or with a wrong key); delete all data (only a new, empty database is left; the keys go before it opens; an interrupted delete finishes); reminder planner (window, quiet hours, meal windows and their notices, bundling, daily limit and digest, nudges never in the digest, water nudges in the day only and none once today's goal is reached, stable ids, cap); rest windows and time in Navmaas; notification text and tap targets; supplement reminders and Taken / Snooze against the database; the listening log (only playing time counts, from one minute, one session per item; meditation logged as meditation and ended at Finish or the end bell); the committed bell and quiet clip match `tool/bell.dart`; repositories on in-memory Drift (wellbeing: one mood a day, symptoms by key or her own name, one night per wake-up day, water never below zero, the week and the sleep average); build-expiry parser on sample profiles; kick and contraction patterns (most active window, last-hour averages).
- **Backup tests:**
  - Round-trip with and without the library.
  - Wrong password.
  - Truncated, reordered or tampered chunks.
  - Restoring an older schema (schema 5 and the pre-M7 schema 6 migrate) and rejecting a newer one; the round trip carries the wellbeing tables.
  - Interrupted swap (rollback works).
  - A 500 MB library needs about the memory of a 50 MB one (under 48 MB more; under 128 MB in all).
- **Widget and golden tests:** onboarding, Today, Journey, Sessions, Me, Screen Rest and (M7a) Wellbeing, mood, symptoms, sleep, water and (M7b) Meditation in light and dark; meditation logged from one minute with and without screen off, and her own audio logged as meditation; wellbeing entries saved and shown in the week, the symptom chips folding to two rows, Today's card (mood and water taps, hidden for the day, gone at the goal) and water nudges re-planned at the goal; the 15-min reading and 20-min walk logged end to end; kick counter and contraction timer logged; delete all data (explains, Back up first, starts again at onboarding, a failure says so); Screen Rest rules change what is planned and shown, time in Navmaas is counted and saved, the eye rest shows every 20 minutes of reading, and wind-down opens her audio with the screen off; pause, baby has arrived, end and resume (reminders stop and return); routines locked, unlocked and hidden for high risk at 1.0× and 2.0× text (`test/goldens/`). Goldens use Flutter's built-in test font, so they check layout, colour and icons, not letter shapes. Text rounds slightly differently on macOS and Linux, so each platform keeps its own exact set: `macos/` (local runs, `flutter test test/goldens --update-goldens`) and `linux/` (CI). When CI's tests fail, it uploads the diff images as `golden-failures` and fresh Linux renders as `linux-goldens` to copy in after an intended change.
- **Content tests:** weeks 4–42 complete, stable unique checklist keys, hard-line words absent (weeks, care template, activities, routines, and Wellbeing's words and strings: no advice, warning or good/bad wording), every wellbeing key has its word, routines for every trimester even when high-risk, no lying on the back, review copies in sync.
- **Integration tests (on a phone):** `integration_test/reminders_test.dart` checks the OS really schedules, re-syncs and snoozes reminders (needs notifications allowed); `integration_test/build_expiry_test.dart` reads the iPhone build's expiry; `integration_test/backup_test.dart` backs up, restores, deletes all data and restores again under new keys, with the real keychain and files (empty installs only, since it replaces data); later: onboarding → Today; take a supplement from a notification action; import a PDF and log a reading session.
- **GitHub Actions** (free for public repos), on every pull request, every push to `main` and on demand. Ubuntu, Flutter pinned (3.47.3), Java 17:
  - `dart format --set-exit-if-changed`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --release --target-platform android-arm,android-arm64` (the phone build; fails over 100 MB; uploaded as an artifact; signed only locally)
  - On a test failure: golden diff images (`golden-failures`) and regenerated Linux goldens (`linux-goldens`) are uploaded
  - iOS builds happen on the owner's Mac, because personal-team signing can't run in CI.

## 17. Decision log

| ADR | Decision | Why |
|---|---|---|
| 001 | Flutter for iOS and Android | Team works in Dart; one codebase; full control of the custom calm UI |
| 002 | Local-first, no backend, no network | Personal use; maximum privacy; nothing to host or pay for |
| 003 | Drift + SQLCipher | Relational health logs, typed queries, migrations, encryption at rest |
| 004 | Riverpod + go_router | Testable DI and state; tab shells with preserved stacks |
| 005 | Feature-first folders with data / domain / presentation | Features stay independent; pure domain logic is easy to test |
| 006 | Owner-supplied content on device; repo holds only original or public-domain text | Public repo; no licensing exposure |
| 007 | Single reminder planner with budget, quiet hours and a rolling 7-day window | Calm by default; works within the iOS 64-notification limit |
| 008 | Bundle fonts instead of fetching at runtime | No network calls; works offline |
| 009 | Tracking aid only; no SOS or emergency features | Owner handles emergencies manually, as the doctor advises |
| 010 | Password-protected `.navmaas` backup file (Argon2id + chunked ChaCha20-Poly1305; AES-256-GCM until Plan decision 33) instead of cloud sync | Survives phone loss and app deletion without a backend; streams large libraries |
| 011 | Design within free-Apple-ID capabilities; read and surface the 7-day expiry | No paid membership; avoids surprise lock-outs |
| 012 | Other-app Screen Rest limits are Android-only | Family Controls isn't available to a free Apple ID |
| 013 | SQLCipher through `package:sqlite3` build hooks (`source: sqlcipher`) | `sqlcipher_flutter_libs` reached end-of-life with `sqlite3` 3.x |
| 014 | OS backups stay on, but the database and its key are excluded on both platforms | Android Keystore keys can't be restored elsewhere; identical behaviour on both phones; the `.navmaas` file is the one transfer path |
| 015 | First name stored as the `first_name` setting | M1 needs no `profile` table; doctor and clinic details arrived in M3a (`profile`) |
| 016 | Prototype icons drawn from its SVG path data with `path_parsing` | Exact match to the prototype; `flutter_svg` would bring the `http` package into a no-network app |
| 017 | No `freezed` / `json_serializable` | One small model parsed by hand; fewer packages and no extra codegen; a test reads the real file |
| 018 | Goldens use the built-in test font, one exact set per platform (`macos/`, `linux/`) | Pixel-exact checks everywhere without a fuzzy tolerance; real-font screenshots are reviewed by eye |
| 019 | Exact, OS-scheduled reminders (`USE_EXACT_ALARM` on Android) | Owner requirement: reminders fire on time even when the phone is locked; the app is sideloaded, so Play's exact-alarm policy doesn't apply |
| 020 | Accept `timezone`'s `http` dependency | Required by `flutter_local_notifications`; only its data-download script uses it; release builds have no `INTERNET` |
| 021 | Supplements: quick-pick of common names, no suggested doses | Owner asked for suggestions; names only keeps the "no dose suggestions" hard line (Plan decision 20) |
| 022 | M3 split into M3a (supplements and reminders) and M3b (tests, visits, vitals) | Two reviewable PRs |
| 023 | India care template written as original content, reviewed by the owner | No medical reviewer (Plan decision 5); every item defers to her doctor |
| 024 | Directions open the phone's maps apps (Apple Maps / Google Maps) instead of an in-app map | No map SDK, no network calls from Navmaas |
| 025 | Attachments live in the `db/` folder | Already excluded from OS backups on both platforms (ADR 014) |
| 026 | Accept `audio_service`'s download cache (`flutter_cache_manager` → `http`, `sqflite`) | Needed for background audio with lock-screen controls; only used for network artwork, which Navmaas never sets. Release builds have no `INTERNET`, and the database still opens with SQLCipher (checked on the simulator) |
| 027 | Arm-only phone APK; universal kept as an option | PDFium pushed the universal APK to about 95 MB, close to the 100 MB limit; phones are Arm. Gradle drops any ABI not asked for, so the phone APK never claims x86_64. The universal APK's own limit is 150 MB since M6 (ADR 041) |
| 028 | Library files in `db/library/`, unencrypted; reading progress on `library_item` | Skipped by OS backups like the database (ADR 014); audio has to stream to the player; one table instead of two |
| 029 | M4 split into M4a (library, reading, listening, letters) and M4b (walk, exercise) | Two reviewable PRs, like M3 |
| 030 | Read steps only; never write walks or workouts to Health | Smaller permission request; the walk is logged in Navmaas |
| 031 | One wall clock, `clockNow`, for every time the app reads or stamps | Widget tests fix "today"; rows stamped with the real clock fell on another day once the real date moved on. Tests pin it; the app uses `DateTime.now` |
| 032 | Pause, baby has arrived and end tracking set the pregnancy's status; anything but active shows one quiet page instead of the tabs | Owner decision (Plan 30, 31). Every feature already reads only the active pregnancy, so baby content and pregnancy reminders stop at once with no per-screen checks. Never asks why |
| 033 | Read the build expiry in Dart from the app bundle, not through a Swift channel | The profile sits next to the executable; one small parser, testable on sample profiles; no native code (owner-approved change, Plan 33) |
| 034 | M5 split into M5a (third trimester, pause/end, build expiry) and M5b (backup and restore) | Two reviewable PRs, like M3 and M4 |
| 035 | Snapshot with SQLCipher's `VACUUM INTO`; no per-file hashes | A consistent, still-encrypted copy without pausing the app; the authenticated pieces already cover every byte |
| 036 | A restore rekeys the database to this phone's key and adopts the backup's attachment key | The DB key stays the one in this phone's Keychain / Keystore; re-encrypting every photo would gain nothing, since they arrive sealed and the key travels encrypted |
| 037 | Screen Rest rules live in `settings`, not a `screen_rest_rule` table | A few switches and times, like quiet hours already; no schema change. Time in Navmaas is saved only when the app leaves the screen, and equal reminder settings don't re-plan |
| 038 | Nudges never fold into the morning digest | A meal-time or wind-down nudge at 7 am is pointless; over the limit they drop instead |
| 039 | M6 split into M6a (Screen Rest) and M6b (delete all data, accessibility, release) | Two reviewable PRs, like M3–M5 |
| 040 | Delete all data moves the database aside, deletes the keys, opens a new database, then deletes the old files | The open database keeps working until the swap, like a restore; a new key means nothing old could be read even if a file survived; an interrupted delete finishes on the next open |
| 041 | Universal APK limit 150 MB; phone APK stays at 100 MB | Owner decision 2026-10-06 (Plan 36); the universal APK is for emulators and passed 100 MB with Health Connect |
| 042 | Family sharing is out of scope for Phases 2 and 3 | Owner decision 2026-10-06 (Plan 37). It was the only feature needing a backend and accounts, so Navmaas stays local-only with no network calls |
| 043 | Phase 2 and 3 milestones are design-first: new screens join the prototype canvas and are approved before code | The prototype is the exact visual spec (Plan 15), and none of the Phase 2–3 screens were drawn in Phase 0 |
| 044 | M7 split into M7a (mood, symptoms, sleep, water, Today card, water reminders) and M7b (meditation) | Two reviewable PRs, like Phase 1; meditation needs its own bell tool and audio track (Plan decisions 42, 45) |
| 045 | Wellbeing stores keys, not words; the words live in `app_en.arb` and one `water_log` row holds a day's glasses | Wording can change without touching her data, and the content test can check every word; one row per day makes + / − a single update (Plan decision 43) |
| 046 | The meditation timer plays as one background-audio track (bell, looped quiet clip clipped to the minute, bell) instead of an in-app timer | An in-app timer stops when the phone locks, so the end bell would not ring; as audio it keeps time locked, shows on the lock screen and is logged like listening. Silence sources are Android-only in `just_audio`, so the quiet is a 240 KB asset (Plan decision 42) |
