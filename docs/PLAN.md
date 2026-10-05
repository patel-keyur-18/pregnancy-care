# Navmaas — Product & Technical Plan

| | |
|---|---|
| **Status** | v4 — approved 2026-10-04, updated 2026-10-05 (M1 built; owner decisions 12–17) |
| **App name** | Navmaas (नवमास, "nine months") |
| **Platforms** | iOS (free Apple ID, signed from Xcode) + Android (signed APK) — Flutter |
| **Audience** | Personal use, India, English only |
| **Cost** | Free — no subscription, no ads, no paid developer account |
| **Last updated** | 2026-10-05 |

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
| 14 | App size | **Up to 100 MB** is fine |
| 15 | Prototype fidelity | Screens follow the prototype **exactly**, including its own line icons (drawn in M2) |
| 16 | Week-by-week text | Claude drafts **original** text; the owner reviews it and decides what ships |
| 17 | First name | Optional during onboarding; **editable in Me** (M2) |

### What these decisions change

- **No backend in v1.** No accounts, CMS, Supabase or partner sync. The app makes no network calls at all, which keeps it simple and private.
- **Content is the owner's own.** Week-by-week notes ship as a small bundled content pack (general, well-known information). Books (PDF/EPUB/text) and audio are imported on the phone and never leave it.
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
| **Garbhasanskar** | Daily path (read · listen · activity · talk to baby), library of **imported** books and audio, reading sessions with timer and night-reading mode, audio that keeps playing with the screen off, "Letters to baby" journal ★ | MVP |
| **Screen Rest** | Screen-free hours, meal-time rest, eye-rest nudge, wind-down audio. P2: opt-in limits on other apps (**Android only**) | MVP → P2 |
| **Supplements** | Schedule as prescribed, reminders, mark taken, weekly adherence, refill alerts ★, personal notes | MVP |
| **Vaccines & tests** ★ | Editable India template (Td doses, GTT, scans, blood tests) with dates and status | MVP |
| **Doctor visits** | Appointments, reminders, "questions to ask" collected over weeks ★, what to bring, notes, prescription photo, next visit | MVP |
| **Walking** | Walk timer, steps from Apple Health / Health Connect, daily goal, history | MVP |
| **Exercise** | Trimester-filtered guided routines with timers, locked until "doctor cleared me" is on | MVP |
| **Vitals** ★ | Weight and blood pressure logs (blood sugar in P2). Logged values only — no interpretation | MVP / P2 |
| **Third-trimester tools** ★ | Kick counter (pattern log), contraction timer (log to show the doctor); hospital bag checklist and birth plan in P2 | MVP / P2 |
| **Backup & restore** ★ | Password-protected `.navmaas` backup file, optional books and audio, weekly reminder, restore with password | MVP |
| **iPhone build-expiry reminder** ★ | Reads the 7-day signing expiry; shows it in Me; reminds the day before to back up and re-run from Xcode | MVP |
| **Pregnancy loss handling** ★ | Pause or end tracking; immediately stops baby content and reminders | MVP |
| **Wellbeing** ★ | Mood and symptom journal, sleep log, water, meditation | P2 |
| **Nutrition** ★ | Owner-written meal notes and "foods I avoid" list | P2 |
| **Records vault** ★ | Encrypted on-device store for reports, scans, prescriptions; PDF summary for visits | P2 |
| **Widgets** ★ | Home-screen widget (week + next reminder); App Groups work with a free Apple ID | P2 |
| **Postpartum & baby mode** ★ | Recovery, feeding, sleep, baby vaccine schedule | P3 |
| **Family sharing** ★ | Needs a backend; only if wanted later | P3 (optional) |

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
| **1 — MVP** | Milestones M1–M6 in [Architecture §15](ARCHITECTURE.md#15-delivery-milestones). M1 Foundation ✅ 2026-10-05 |
| **2** | Other-app Screen Rest (Android), wellbeing, nutrition notes, records vault + PDF, widgets, blood sugar |
| **3** | Postpartum & baby mode, optional family sharing |
