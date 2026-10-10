# Navmaas — Product & Technical Plan

| | |
|---|---|
| **Status** | v15 — approved 2026-10-04, updated 2026-10-09 (MVP built, M1–M6; owner decisions 12–76; Phase 2 and 3 milestones M7–M14 planned; M7 Wellbeing built; M10 widgets and app lock built, M8 and M9 deferred; enhancements E1–E4 planned, E1–E4 built, Navmaas 1.2.0; 2026-10-10: one signing key for both apps, Navmaas 1.2.1; M8a built: blood sugar, foods I avoid, hospital bag and birth plan, Navmaas 1.3.0; M8b built: meals from Nourishly, Navmaas 1.4.0) |
| **App name** | Navmaas (नवमास, "nine months") |
| **Platforms** | iOS (free Apple ID, signed from Xcode) + Android (signed APK) — Flutter |
| **Audience** | Personal use, India, English only |
| **Cost** | Free — no subscription, no ads, no paid developer account |
| **Last updated** | 2026-10-09 |

Related: [Design system](DESIGN_SYSTEM.md) · [Architecture](ARCHITECTURE.md) · [Interactive prototype](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8) (private link — share it from its Share menu)

Legend: ★ = feature added during brainstorming (not in the original brief).

---

## 1. Decisions (approved)

| # | Question | Decision |
|---|---|---|
| 1 | Plan and MVP scope | Approved |
| 2 | Market & languages | India first, **English only** |
| 3 | Tech stack | **Dart + Flutter** |
| 4 | Garbhasanskar content | No author partnership — **the owner adds books and audio manually** inside the app |
| 5 | Medical reviewer | None — the app is a **tracking aid, not a medical reference** |
| 6 | Monetization | **Personal use, free.** No subscription tier |
| 7 | App name | **Navmaas** — *nav* (nine, also "new") + *maas* (month). Lunar months tie into the moon logo. A web search found no pregnancy app, brand or product using the name; a formal trademark search is still advised before any public store release |
| 8 | Repository | **Public**, MIT-licensed |
| 9 | SOS / emergency features | **Not included.** Emergencies are handled manually, as the doctor advises |
| 10 | iPhone install | **Free Apple ID.** The owner re-runs the app from Xcode every 7 days to renew it |
| 11 | Backup & restore | **In the MVP.** Password-protected backup file plus restore |
| 12 | Bundle ID | **`com.patelkeyur.navmaas`** on iOS and Android. It never changes: a new ID installs a new, empty app |
| 13 | OS backups | **Stay on for both platforms**, but Navmaas's encrypted database and its key are left out of them on both, so behaviour is the same. The `.navmaas` backup file is how data moves between phones |
| 14 | App size | **Up to 100 MB** for the phone APK is fine; the universal APK (emulators) may be up to 150 MB (decision 36) |
| 15 | Prototype fidelity | Screens follow the prototype **exactly**, including its own line icons (drawn in M2) |
| 16 | Week-by-week text and India care template | Claude drafts **original** text; the owner reviews it and decides what ships |
| 17 | First name | Optional during onboarding; **editable in Me** (M2) |
| 18 | Today's plan | **Moved from M2 to M3**, where supplements give it real items; reading joined in M4a, the walk in M4b |
| 19 | Icon motion | Small, calm tap animations on icons (DESIGN_SYSTEM §5); instant when the phone asks to reduce motion |
| 20 | Supplement suggestions | **A quick-pick of common pregnancy supplement names** (folic acid, iron + folic acid, calcium + vitamin D, vitamin D3, B12, DHA, multivitamin). She enters the dose exactly as prescribed; the app never suggests doses or which to take |
| 21 | Reminder timing | **On time even when the phone is locked**: scheduled with the OS, exact alarms on Android |
| 22 | Notification permission | Asked in onboarding (optional step), switchable in Me, and offered once after the first supplement |
| 23 | Doctor details | Optional onboarding step (3 of 4, skippable), editable in Me: doctor, clinic, phone and address; Call clinic and Directions (Apple / Google Maps) on visits in M3b |
| 24 | Book formats | **PDF and plain text (`.txt`, `.md`)** for now; EPUB later. Audio: MP3, M4A, AAC, WAV |
| 25 | APK build | The phone build is **Arm only** (`--target-platform android-arm,android-arm64`, about 65 MB). The universal APK (adds x86_64 for emulators) stays available as an option; since M4b it is over 100 MB (about 103 MB at M6), so it's for emulators only |
| 26 | Safety note on Walk and Exercise | A gentle general line ("Go gently. Stop and rest if anything feels uncomfortable, and check with your doctor.") plus the talk test, **not** the prototype's symptom list, which would be a danger-sign list (§5.5) |
| 27 | Walking | **Always open** ("it is always good to walk daily"). Only the exercise routines wait for "doctor cleared me" |
| 28 | Slow breathing and Activity | Breathing is a quiet 5-minute paced timer (no audio in the repo). The path's Activity tile shows one of about 30 original calm activities a day, drafted by Claude for the owner's review |
| 29 | Audio package dependencies | Accept `audio_service`'s download cache (`flutter_cache_manager`, which brings `http` and `sqflite`). Navmaas never calls it, and release builds have no `INTERNET` (ADR 026) |
| 30 | Pause or end tracking | Three choices in Me: **Pause tracking**, **Baby has arrived** (a short, gentle congratulation) and **End tracking**. The app never asks why. Any of them can be undone with Resume |
| 31 | While tracking is stopped | **One quiet page** instead of the tabs: Resume, or Start a new pregnancy, and Backup & restore. No baby content, no week numbers. Everything she logged stays on the phone. Pregnancy reminders stop; build-expiry and backup reminders keep running |
| 32 | Weekly backup reminder | On by default, **Sundays at 10:00**, day changeable (or off) on the Backup screen; skipped when she backed up in the last 6 days |
| 33 | M5 technical changes | Backups use **ChaCha20-Poly1305** (as strong as AES-256-GCM, twice as fast in pure Dart) and a simple list of files inside the encrypted body instead of ZIP, so `archive` isn't needed. The iPhone build expiry is read in Dart (no Swift channel). Backups are saved through the share sheet, since the save dialog needs the whole file in memory |
| 34 | Screen Rest rules | Four rules, as drawn: **Bedtime rest** (the quiet hours), **Meal times** (hold reminders until each 45-minute window ends, and send one gentle notice as it starts), **Eye-rest nudge** (a 20-second rest every 20 minutes of reading, in the reader only) and **Wind-down audio** (off by default; a 9:00 pm nudge that opens the audio she played last with the screen off, or Sessions if she has none). Time in Navmaas today is counted on the phone. The prototype's Phase 2 "Limits for other apps" card is left out until P2 |
| 35 | Delete all data | **In the MVP (M6).** Me → Your data → "Delete all data" (red). A dialog says what goes, shows the last backup with "Back up first", then "Delete everything" wipes the phone's Navmaas data and keys and starts again at onboarding. Backup files saved elsewhere stay |
| 36 | Universal APK size | Up to **150 MB** (it's for emulators); the phone APK stays at 100 MB at most |
| 37 | Family sharing | **Out of scope** for Phases 2 and 3. Navmaas never needs a backend or accounts (ADR 042) |
| 38 | Phase 2 and 3 scope | **Everything else in the feature map is in scope.** Phase 2 is M7–M11 and Phase 3 is M12–M14, each with scope, owner decisions and done-when criteria in [Architecture §15](ARCHITECTURE.md#15-delivery-milestones). Each milestone draws its new screens in the prototype first (ADR 043) |
| 39 | Wellbeing symptom log (M7) | Pick from ten common discomforts (nausea, heartburn, backache, swollen feet, headache, leg cramps, constipation, tiredness, trouble sleeping, bloating) or add her own; mild / moderate / strong in words, no colours; a note. **A log, never advice and never a warning list**: nothing says a symptom is serious, normal or a reason to act |
| 40 | Mood words (M7) | Five equal words, not a scale: **Calm · Happy · Okay · Tired · Low**. No emoji, colours or scores. One check-in a day; only today's can be changed |
| 41 | Water (M7) | Default goal **8 glasses** (4–16), counted in glasses only. Reminders are nudges, **off by default**, every 2 or 3 hours (her choice, default 2) between the end and start of quiet hours; the rest of the day's nudges are skipped once the goal is reached. They rank last under the daily limit and are dropped over it, never in the digest (ADR 038); the Water screen says so |
| 42 | Meditation (M7) | 5, 10, 15 or 20 minutes, or her own imported audio. The timer plays as one track through the background audio player: an original bell generated by `tool/bell.dart` (about 175 KB WAV), a looped quiet clip, the bell again; so it keeps time and rings with the phone locked. Logged as a `meditation` session from one minute |
| 43 | Wellbeing keys and labels (M7) | The database stores keys only (mood, symptom, severity, rested); labels live in `app_en.arb` under fixed prefixes, like the supplement quick-pick. The content hard-line test checks those labels and every Wellbeing string for advice, warning and good/bad words |
| 44 | Sleep, mood and Today card (M7) | Sleep: one entry per night, dated by the wake-up day: bedtime, wake time, nap minutes and how rested (Rested · A bit tired · Very tired); the weekly average counts night plus naps. Today's "How are you today?" card shows while today has no mood or water is under the goal, has + / − water taps and hides for the day when dismissed |
| 45 | M7 split | **M7a** (schema v7, mood, symptoms, sleep, water, Wellbeing, Today card, water reminders, backup and delete) and **M7b** (meditation), stacked PRs |
| 46 | M10 packages | **`home_widget`** (the widget snapshot in the App Group / shared preferences, widget reloads and Android update alarms) and **`local_auth`** (app lock). Neither makes network calls |
| 47 | Widget details (M10) | "Hide details on widget" is **off by default** while app lock is off; with app lock on it is on unless she turns it off. Hidden, the widget shows only the brand mark and the next reminder's time; while tracking is stopped, only the mark |
| 48 | App lock timeout (M10) | Always locks on a fresh open; after leaving Navmaas for **1, 5 or 15 minutes** (default 1), so a file picker, share sheet or Health dialog never locks her out mid-task |
| 49 | Widget's next reminder (M10) | **Whatever notification fires next**, nudges and the digest included, as the notification titles it |
| 50 | M10 split | **M10a** (widgets, hide details) and **M10b** (app lock), stacked PRs |
| 51 | App-limit notice wording (M11) | Title **"Time for a pause"**, body **"{minutes} min on {app} today. Phone down, baby time."**. One per app per day; nothing is blocked |
| 52 | App-limit minute steps (M11) | **15 · 30 · 45 · 60 · 90 · 120** minutes a day per app, default 30 |
| 53 | How the Android check follows the calm rules (M11) | **A rules snapshot.** Dart writes, for the week ahead, the times a notice may go out (outside quiet hours and meal windows, so a notice waits until a window ends, the same day), each day's room under the daily limit after the planned reminders, and the ready-made notice per app. A Kotlin WorkManager job every 15 minutes, only while a limit is set, applies it. Over the daily limit the notice is dropped. No new pub package; WorkManager is already in the app through `home_widget` (ADR 050) |
| 54 | M11 split | **M11a** (schema v8, Usage access, app picker, limits, the check and notice) and **M11b** (the deferred integration tests, accessibility pass over Phase 2 screens, version 1.1.0, release builds), stacked PRs |
| 55 | Enhancements E1–E4 | The owner's requests of 2026-10-08, built one at a time, each on its own branch from `main` with its own PR, planned and approved before it starts: **E1** Sessions fixes (schema v9), **E2** links to YouTube, YouTube Music and Spotify (v10), **E3** voice letters (v11), **E4** mood scenes on Today. Version **1.2.0** comes with E4. Small prototype changes for them need no separate approval; the prototype and docs are updated in the same PR (ADR 053) |
| 56 | Reading progress (E1) | The library shows **how far she has read** (`furthest`, which only goes up), not the page she is on, so going back to page 1 of a finished book keeps it **"Finished"**. The book still reopens where she left off. No "read again" action |
| 57 | Reading ticked by hand (E1) | For a printed book: Today's reading row is always there, even with no book in the library, and its tick logs a **15-minute** reading session with no book. Unticking takes it back. Reading done in the reader ticks it for the day and can't be unticked |
| 58 | Walk timer (E1) | The walk waits for **Start**, then Pause / Resume and **Finish walk**. Leaving pauses it, and the unfinished walk is kept (even if the app closes) until Finish, so she carries on from the same time. Only Finish logs it, from one minute, with the steps counted while she walked. A walk left from an earlier day is logged to that day (ending at its midnight at the latest) and a fresh one starts |
| 59 | Exercise timer (E1) | Every routine (Gentle flow, Pelvic floor, Seated stretches) waits for **Start**, then Pause / Resume and **Finish**. Leaving without Finish still logs it from one minute |
| 60 | Library actions (E1) | A visible **⋯** button on each library row opens Rename / Remove; long press still works |
| 61 | Links (E2) | She can add, edit and remove links to **YouTube, YouTube Music and Spotify** (her own title) in the library: `youtube.com` / `youtu.be`, `music.youtube.com`, `open.spotify.com` and `spotify.link`, with `https://` added when missing; anything else is refused. A tap opens the **service's app**, or the browser when the app isn't there; Navmaas itself still makes no network calls and logs no listening time for links. With nothing added, the Listen tile offers audio or a link; otherwise it shows whatever she opened last
| 62 | Voice letters (E3) | Talk to baby takes a **voice note** recorded with the microphone, as well as or instead of words (`record` package and microphone permission approved): **one per letter, up to 10 minutes**. Letters opens with **Write** and **Speak**; Speak opens the letter with Record ready, never recording by itself. Voice notes are **encrypted** like prescription photos. Backups include them only when Backup & restore's **"Include voice letters"** switch is on (**off by default**, remembered). Restoring a backup without them keeps the letters' words and says "This voice note isn't on this phone"
| 63 | Mood scenes on Today (E4) | Each of the five mood words gets its **own gentle scene** on Today, under the week card, from the moment she picks today's mood until midnight, so no mood is marked as bad: Calm a lotus with ripples, Happy a sun and swaying flowers, Okay drifting clouds and a sprout, Tired a baby asleep on a crescent moon, Low a baby curled in a soft circle with a small heart. One line each, promising nothing: "A calm day, shared with baby." · "Baby is along for your happy day." · "One gentle day at a time, together." · "You and baby, resting together today." · "You and baby, together today." Drawn originally in Flutter (no Lottie or downloaded animation). The lines live in `app_en.arb` (`moodSceneLine*`), so the owner can reword them there alone
| 64 | Replace file (E2) | An audio file's ⋯ offers **Replace file** next to Rename and Remove: she picks a new audio file, the title stays and the length is read again (playing, it stops first) |
| 65 | Recording a voice letter (E3) | While she records, **the screen stays on** (no dimming or auto-lock). Leaving Navmaas or locking the phone **stops the recording and keeps** what she said; it never records in the background. Recording and playing need a short-lived plain copy in the app's private temporary folder, deleted at once after recording and when the letter closes, and swept when the app starts (ADR 055) |
| 66 | Mood scene motion (E4) | It moves gently for **about 12 seconds each time the app opens to Today** (not on every tab switch) and **again when tapped**, then rests; with reduce motion it is a still picture and a tap doesn't move it. This is the one exception to "nothing plays on its own" (DESIGN_SYSTEM §5) |
| 67 | Release 1.2.0 | **Navmaas 1.2.0 (build 3)** carries E1–E4, released with E4 |
| 68 | App icon | The **sprout** from the app-switcher cover, a little larger: dark sage on `primary-soft`, the same on iPhone and Android (Android 13+ themed icons get the sprout alone). It replaces Flutter's default icon; the moon stays the brand mark in the name's story and on the quiet page |
| 69 | GitHub releases | Release tags follow the app's version: `v` + `version` in `pubspec.yaml` (first tag **v1.2.0**). Bumping the version in a PR and merging it publishes a GitHub release with the phone APK (`navmaas-<version>.apk`, signed with the owner's key since 1.2.1, Arm only); merges that don't bump publish nothing |
| 70 | One signing key | One keystore, made by the owner (`keytool`) and never committed, signs Navmaas and Nourishly, on the Mac (`android/key.properties`) and in CI (four repository secrets the owner sets; Claude never sees the passwords). GitHub releases then update in place, and Navmaas can read Nourishly's meals (M8b). The owner keeps the keystore backed up in two places. **Navmaas 1.2.1 (build 4)** (ADR 060) |
| 71 | Nutrition from Nourishly | Navmaas shows the meals she logs in Nourishly (the owner's own diet tracker) instead of its own meal notes: Nourishly writes a small share file (her profile only, the last 90 days, each day's meals and six totals, never targets or scores), served on Android by a `signature`-protected provider and on iPhone through a shared App Group; Navmaas reads it on open and resume and stores nothing. "Share with Navmaas" is off by default in Nourishly. Totals: energy (kcal), protein, iron, calcium, folate, fibre, values only. `meal_note` is dropped (ADR 061; built in M8b, Navmaas 1.4.0) |
| 72 | M8 split | M8a (Navmaas: blood sugar, foods I avoid, hospital bag, birth plan), then a Nourishly PR (the share file), then M8b (Navmaas reads it) |
| 73 | M8a content | The hospital bag template (31 items: for me, for baby, documents) and six birth-plan prompts, as drafted (`docs/content/hospital_bag.md`, `birth_plan.md`); pain relief and feeding stay, and she may leave any prompt empty |
| 74 | Care by week | The kick counter shows at every week; the contraction timer joins it from week 28; Hospital bag and Birth plan show from week 32 and not before, twins included. Before week 28 the kick counter spans the row (owner, 2026-10-10; changes the M5a layout, where the contraction timer was always shown) |
| 75 | Blood sugar | Whole mg/dL from 1 to 999 (a decimal, as from a mmol/L meter, saves nothing rather than turning 5.6 into 56), when it was taken (fasting, before a meal, 1 h or 2 h after a meal, bedtime), a time today and a note; listed by day with no ranges, colours or labels. **Navmaas 1.3.0 (build 5)** |
| 76 | M8b meals from Nourishly | Care → Nutrition shows "From Nourishly" above Foods I avoid: a week of days (‹ › move a week, back as far as she likes, never past today; a dot marks days with meals), each meal with its items and amounts, then the day totals in a fixed order (energy, protein, iron, calcium, folate, fibre). A nutrient Nourishly had no data for is left out, never shown as 0; "{nutrients}: some foods had no data" marks partial ones. "Updated" shows the time Nourishly wrote the file, with its date when that isn't today, as written (never converted). Not shared: one calm line; a file it can't read: amber, never red. Care's Nutrition tile says "Today: N meals from Nourishly", or the foods-you-avoid count when there are none. Unit strings (kcal, g, mg, µg) are exempt from the word check as food measurements, not doses. Read on open and resume; nothing stored (owner approved the boards 2026-10-10). **Navmaas 1.4.0 (build 6)** |

### What these decisions change

- **No backend, ever.** No accounts, CMS, Supabase or partner sync; family sharing is out of scope (decision 37). The app makes no network calls at all, which keeps it simple and private.
- **Content is the owner's own.** Week-by-week notes ship as a small bundled content pack (general, well-known information). Books (PDF and text) and audio are imported on the phone and never leave it.
- **Public repo means no copyrighted content in git.** Only original or public-domain text goes into the bundled content pack. Personal books and audio stay on the device.
- **Tracking aid only.** The app records and reminds. It does not interpret readings, recommend doses or provide emergency features: no SOS, no emergency card, no danger-sign or warning list. Wellbeing's symptom pick-list is a log of what she felt, never advice (decision 39).
- **Built for a free Apple ID.** Everything the iPhone app needs is available to a free Apple ID: HealthKit, background audio, App Groups, Keychain and Data Protection. Three things are not: Family Controls, push notifications and iCloud. So:
  - Limits on other apps are Android-only.
  - There is no iCloud sync.
  - The app warns before its 7-day build expires.
- **Backup is the safety net.** No cloud means a lost or wiped phone loses data. The password-protected backup file is how data survives that, and how it moves to a new phone.
- **No multilingual work** for now. Strings still go through Flutter's localisation system so a language can be added later without a rewrite.

## 2. Product principles

1. **Calm by default.** An app that asks her to use the phone less must itself be low-screen: audio-first sessions, few notifications, get in and get out.
2. **Track, don't diagnose.** The app records and reminds; medical decisions stay with her doctor.
3. **Private by design.** No account, data stays encrypted on the phone, no ads, no analytics.
4. **No guilt.** Gentle progress, no punishing streaks; every pregnancy day is different.
5. **Inclusive.** Garbhasanskar is optional; runs well on low-end Android phones.

## 3. Feature map

| Module | What it does | Phase |
|---|---|---|
| **Onboarding & pregnancy engine** | Due date from last period (with cycle length), conception date, IVF transfer or scan. Shows weeks + days, the month ("Month 6") and the trimester. Optional first name, editable in Me. Twins flag, high-risk flag ★, "doctor cleared me for exercise" ★ | MVP |
| **Today (home)** | Week ring, baby size (Indian fruit and vegetable comparisons), a gentle scene for today's mood (E4), today's plan (supplements, session, walk), next visit, Screen Rest status | MVP |
| **Journey (trimester-wise)** | Trimester tabs, week picker, baby and body notes per week, weekly checklist, trimester progress from her own logs | MVP |
| **Garbhasanskar** | Daily path (read · listen · activity · talk to baby), library of **imported** books (PDF, text; EPUB in P2) and audio, plus links to YouTube, YouTube Music and Spotify (E2), reading sessions with timer and night-reading mode, voice letters to baby (E3), audio that keeps playing with the screen off, "Letters to baby" journal ★ | MVP; EPUB P2 (M9) |
| **Screen Rest** | Screen-free hours, meal-time rest, eye-rest nudge, wind-down audio. P2: opt-in limits on other apps (**Android only**) | MVP → P2 (M11a ✅ 2026-10-06, Android) |
| **Supplements** | Quick-pick of common names, dose as prescribed, schedule, on-time reminders with Taken / Snooze, mark taken, weekly adherence, refill alerts ★, personal notes | MVP |
| **Vaccines & tests** ★ | India template (tests, scans, vaccines with week windows); book a date, mark done; gentle reminders | MVP |
| **Doctor visits** | Appointments, reminders, "questions to ask" collected over weeks ★, what to bring, notes, prescription photo (encrypted), next visit, Call clinic and Directions | MVP |
| **Walking** | Walk timer (Start, pause, carry on later, Finish; E1), steps from Apple Health / Health Connect, daily goal, history; always open | MVP |
| **Exercise** | Trimester-filtered guided routines with timers (Start, pause, Finish; E1), locked until "doctor cleared me" is on | MVP |
| **Vitals** ★ | Weight, blood pressure and (M8a) blood sugar logs: mg/dL, when it was taken, a time and a note. Logged values only — no interpretation | MVP / P2 (M8a ✅) |
| **Third-trimester tools** ★ | Kick counter (pattern log), contraction timer (log to show the doctor; on Care from week 28); hospital bag checklist and birth plan (M8a, on Care from week 32) | MVP / P2 (M8a ✅) |
| **Backup & restore** ★ | Password-protected `.navmaas` backup file, optional books and audio, weekly reminder, restore with password | MVP |
| **iPhone build-expiry reminder** ★ | Reads the 7-day signing expiry; shows it in Me; reminds the day before to back up and re-run from Xcode | MVP |
| **Pregnancy loss handling** ★ | Pause tracking, baby has arrived, or end tracking (never asks why); one quiet page; immediately stops baby content and pregnancy reminders | MVP |
| **Wellbeing** ★ | Mood and symptom journal, sleep log, water, meditation | P2 (M7) |
| **Nutrition** ★ | "Foods I avoid", her own list with her own reasons (M8a); the meals she logs in Nourishly, read on the phone (M8b). No food advice | P2 (M8a ✅ / M8b ✅) |
| **Records vault** ★ | Encrypted on-device store for reports, scans, prescriptions; PDF summary for visits | P2 (M9) |
| **Widgets** ★ | Home-screen widget (week + next reminder) with a "hide details" option; App Groups work with a free Apple ID | P2 (M10 ✅ 2026-10-06) |
| **App lock** ★ | Optional Face ID / fingerprint lock with the device passcode as fallback; off by default | P2 (M10b ✅ 2026-10-06) |
| **Postpartum & baby mode** ★ | Her recovery, baby feeding and sleep, baby vaccine schedule and visits | P3 (M12–M14) |
| **Family sharing** ★ | Would need a backend and accounts | **Out of scope** (decision 37) |

## 4. Interactive prototype

The prototype covers 29 screens, each in light and dark mode, with a clickable flow and the theme sheet (the 6 M7 Wellbeing screens and the M10 widgets, lock screen and Me → Your data boards, and the M11 Screen Rest limits card, Limits for other apps and Usage access boards, were added on 2026-10-06, ADR 043; on 2026-10-08 E1 updated Walk and Exercise before Start, the library's ⋯ button and Today's reading tick; E2 added the Add sheet with links, the link dialog, the audio and link ⋯ sheets and a link row on Sessions; E3 added Letters to baby with Write and Speak, the letter's voice note before, during and after recording, and the "Include voice letters" switch on Backup & restore; E4 added Today with a mood scene and all five scenes): [Navmaas Screens](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8).

Screens: Onboarding · Today · Journey · Sessions · Reading session · Listen (screen-off) · Walk · Exercise · Screen Rest · Care · Supplements · Doctor visit · Kick counter · Contraction timer · Blood sugar · Nutrition · Hospital bag · Birth plan · Backup & restore · Me & settings · Wellbeing · Mood check-in · Symptom log · Sleep entry · Water · Meditation timer.

## 5. Notes and constraints

### 5.1 Free Apple ID limits
These come from Apple's [supported capabilities table](https://developer.apple.com/help/account/reference/supported-capabilities-ios) and free-account signing rules.

| Limit | Effect on Navmaas |
|---|---|
| Build stops opening 7 days after signing | In-app expiry banner plus a reminder the day before. Re-running from Xcode keeps all data |
| Up to 3 sideloaded apps per device, 10 App IDs | Navmaas plus a P2 widget extension uses 2 App IDs |
| No Family Controls | Limits on other apps are Android-only |
| No push notifications, no iCloud | Not needed: reminders are local; backup is a file |
| Deleting the app erases its data | Restore from the latest backup |

### 5.2 Screen Rest across other apps (P2)
- **Android:** uses "Usage access", which the user grants in Settings.
- **iOS:** not possible with a free Apple ID (Family Controls). In-app Screen Rest still works on both platforms.

### 5.3 Kick counter and contraction timer
These are logs to show the doctor. They show her usual pattern and averages; they never judge whether something is fine or urgent. The kick counter carries one plain line: "Fewer movements than usual? Follow your doctor's advice and contact them."

### 5.4 Notifications
There's a daily notification limit (default 4), digest bundling and quiet hours. iOS allows only 64 pending local notifications, so the scheduler uses a rolling window (see [Architecture](ARCHITECTURE.md#7-reminder-scheduler)).

### 5.5 Hard lines
- No sex prediction or sex-selection content (PCPNDT Act).
- No outcome claims ("raises IQ").
- No dose suggestions.
- No copyrighted text or audio committed to this public repo.

## 6. Roadmap

| Phase | Scope |
|---|---|
| **0 — Discovery & design** ✅ | Plan, name, theme, prototype, architecture |
| **1 — MVP** | Milestones M1–M6 in [Architecture §15](ARCHITECTURE.md#15-delivery-milestones). M1 Foundation, M2 Today & Journey, M3 Care (M3a + M3b) and M4 Sessions (M4a + M4b) ✅ 2026-10-05; M5 third trimester, build expiry and backup (M5a + M5b) ✅ 2026-10-06; M6 Screen Rest, delete all data and release (M6a + M6b) ✅ 2026-10-06 |
| **2 — Enhancements** | M7 Wellbeing ✅ 2026-10-06 (M7a mood, symptoms, sleep and water; M7b meditation) · M8 Body and birth prep: M8a ✅ 2026-10-10 (blood sugar, foods I avoid, hospital bag, birth plan; Navmaas 1.3.0), M8b ✅ 2026-10-10 (meals from Nourishly; Navmaas 1.4.0) · M9 Records vault, visit summary PDF and EPUB · M10 Home-screen widgets and app lock ✅ 2026-10-06 (M10a widgets; M10b app lock) · M11 Limits for other apps (Android) and the Phase 2 release ✅ 2026-10-06 (M11a limits; M11b the Phase 2 release, Navmaas 1.1.0, without the deferred M8 and M9). The owner deferred M8 and M9 on 2026-10-06 and took M10 first. Scope and done-when criteria: [Architecture §15](ARCHITECTURE.md#phase-2--enhancements-m7m11) |
| **3 — Postpartum and baby** | M12 Postpartum mode and her recovery · M13 Baby feeding and sleep · M14 Baby vaccines and visits, and the Phase 3 release. Scope and done-when criteria: [Architecture §15](ARCHITECTURE.md#phase-3--postpartum-and-baby-m12m14) |
| **Enhancements (E1–E4)** | The owner's requests of 2026-10-08 (decisions 55–67): E1 Sessions fixes ✅ 2026-10-08, PR #28 (reading progress, ⋯ on library rows, walk and exercise Start / Finish, reading ticked by hand) · E2 links ✅ 2026-10-08, PR #29 (YouTube, YouTube Music and Spotify links that open in their apps; Replace file for audio) · E3 voice letters ✅ 2026-10-09, PR #30 (record a voice note for baby, encrypted; optional in backups) · E4 mood scenes on Today ✅ 2026-10-09, PR #31 (a gentle scene for each mood) and **Navmaas 1.2.0**. Scope: [Architecture §15](ARCHITECTURE.md#enhancements-e1e4) |
| Out of scope | Family sharing (decision 37) |
