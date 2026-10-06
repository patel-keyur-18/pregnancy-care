# Navmaas — Product & Technical Plan

| | |
|---|---|
| **Status** | v12 — approved 2026-10-04, updated 2026-10-06 (MVP built, M1–M6; owner decisions 12–38; Phase 2 and 3 milestones M7–M14 planned) |
| **App name** | Navmaas (नवमास, "nine months") |
| **Platforms** | iOS (free Apple ID, signed from Xcode) + Android (signed APK) — Flutter |
| **Audience** | Personal use, India, English only |
| **Cost** | Free — no subscription, no ads, no paid developer account |
| **Last updated** | 2026-10-06 |

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

### What these decisions change

- **No backend, ever.** No accounts, CMS, Supabase or partner sync; family sharing is out of scope (decision 37). The app makes no network calls at all, which keeps it simple and private.
- **Content is the owner's own.** Week-by-week notes ship as a small bundled content pack (general, well-known information). Books (PDF and text) and audio are imported on the phone and never leave it.
- **Public repo means no copyrighted content in git.** Only original or public-domain text goes into the bundled content pack. Personal books and audio stay on the device.
- **Tracking aid only.** The app records and reminds. It does not interpret readings, recommend doses or provide emergency features: no SOS, no emergency card, no danger-sign list.
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
| **Today (home)** | Week ring, baby size (Indian fruit and vegetable comparisons), today's plan (supplements, session, walk), next visit, Screen Rest status | MVP |
| **Journey (trimester-wise)** | Trimester tabs, week picker, baby and body notes per week, weekly checklist, trimester progress from her own logs | MVP |
| **Garbhasanskar** | Daily path (read · listen · activity · talk to baby), library of **imported** books (PDF, text; EPUB in P2) and audio, reading sessions with timer and night-reading mode, audio that keeps playing with the screen off, "Letters to baby" journal ★ | MVP; EPUB P2 (M9) |
| **Screen Rest** | Screen-free hours, meal-time rest, eye-rest nudge, wind-down audio. P2: opt-in limits on other apps (**Android only**) | MVP → P2 (M11) |
| **Supplements** | Quick-pick of common names, dose as prescribed, schedule, on-time reminders with Taken / Snooze, mark taken, weekly adherence, refill alerts ★, personal notes | MVP |
| **Vaccines & tests** ★ | India template (tests, scans, vaccines with week windows); book a date, mark done; gentle reminders | MVP |
| **Doctor visits** | Appointments, reminders, "questions to ask" collected over weeks ★, what to bring, notes, prescription photo (encrypted), next visit, Call clinic and Directions | MVP |
| **Walking** | Walk timer, steps from Apple Health / Health Connect, daily goal, history; always open | MVP |
| **Exercise** | Trimester-filtered guided routines with timers, locked until "doctor cleared me" is on | MVP |
| **Vitals** ★ | Weight and blood pressure logs (blood sugar in P2). Logged values only — no interpretation | MVP / P2 (M8) |
| **Third-trimester tools** ★ | Kick counter (pattern log), contraction timer (log to show the doctor); hospital bag checklist and birth plan in P2 | MVP / P2 (M8) |
| **Backup & restore** ★ | Password-protected `.navmaas` backup file, optional books and audio, weekly reminder, restore with password | MVP |
| **iPhone build-expiry reminder** ★ | Reads the 7-day signing expiry; shows it in Me; reminds the day before to back up and re-run from Xcode | MVP |
| **Pregnancy loss handling** ★ | Pause tracking, baby has arrived, or end tracking (never asks why); one quiet page; immediately stops baby content and pregnancy reminders | MVP |
| **Wellbeing** ★ | Mood and symptom journal, sleep log, water, meditation | P2 (M7) |
| **Nutrition** ★ | Owner-written meal notes and "foods I avoid" list | P2 (M8) |
| **Records vault** ★ | Encrypted on-device store for reports, scans, prescriptions; PDF summary for visits | P2 (M9) |
| **Widgets** ★ | Home-screen widget (week + next reminder) with a "hide details" option; App Groups work with a free Apple ID | P2 (M10) |
| **App lock** ★ | Optional Face ID / fingerprint lock with the device passcode as fallback; off by default | P2 (M10) |
| **Postpartum & baby mode** ★ | Her recovery, baby feeding and sleep, baby vaccine schedule and visits | P3 (M12–M14) |
| **Family sharing** ★ | Would need a backend and accounts | **Out of scope** (decision 37) |

## 4. Interactive prototype

The prototype covers 16 screens, each in light and dark mode, with a clickable flow and the theme sheet: [Navmaas Screens](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8).

Screens: Onboarding · Today · Journey · Sessions · Reading session · Listen (screen-off) · Walk · Exercise · Screen Rest · Care · Supplements · Doctor visit · Kick counter · Contraction timer · Backup & restore · Me & settings.

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
| **2 — Enhancements** | M7 Wellbeing · M8 Body and birth prep (blood sugar, nutrition notes, hospital bag, birth plan) · M9 Records vault, visit summary PDF and EPUB · M10 Home-screen widgets and app lock · M11 Limits for other apps (Android) and the Phase 2 release. Scope and done-when criteria: [Architecture §15](ARCHITECTURE.md#phase-2--enhancements-m7m11) |
| **3 — Postpartum and baby** | M12 Postpartum mode and her recovery · M13 Baby feeding and sleep · M14 Baby vaccines and visits, and the Phase 3 release. Scope and done-when criteria: [Architecture §15](ARCHITECTURE.md#phase-3--postpartum-and-baby-m12m14) |
| Out of scope | Family sharing (decision 37) |
