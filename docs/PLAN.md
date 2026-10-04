# Navmaas — Product & Technical Plan

| | |
|---|---|
| **Status** | v2 — approved 2026-10-04 |
| **App name** | Navmaas (नवमास, "nine months") |
| **Platforms** | iOS + Android (Flutter) |
| **Audience** | Personal use, India, English only |
| **Cost** | Free — no subscription, no ads |
| **Last updated** | 2026-10-04 |

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

### What these decisions change

- **No backend in v1.** No accounts, CMS, Supabase or partner sync. The app makes no network calls at all, which keeps it simple and private.
- **Content is the owner's own.** Week-by-week notes ship as a small bundled content pack (general, well-known information). Books (PDF/EPUB/text) and audio are imported on the phone and never leave it.
- **Public repo means no copyrighted content in git.** Only original or public-domain text goes into the bundled content pack. Personal books and audio stay on the device.
- **Tracking aid positioning.** Without a medical reviewer, the app records and reminds; it does not interpret readings or recommend doses. One safety exception is kept on purpose (see 5.1).
- **No multilingual work** for now. Strings still go through Flutter's localisation system so a language can be added later without a rewrite.

## 2. Product principles

1. **Calm by default.** An app that asks her to use the phone less must itself be low-screen: audio-first sessions, few notifications, get in and get out.
2. **Track, don't diagnose.** The app records and reminds. Warning symptoms always route to "call your doctor" or emergency help.
3. **Private by design.** No account, data stays encrypted on the phone, no ads, no analytics.
4. **No guilt.** Gentle progress, no punishing streaks; every pregnancy day is different.
5. **Inclusive.** Garbhasanskar is optional; runs well on low-end Android phones.

## 3. Feature map

| Module | What it does | Phase |
|---|---|---|
| **Onboarding & pregnancy engine** | Due date from last period (with cycle length), conception date, IVF transfer or scan. Shows weeks + days, the month ("Month 6") and the trimester. Twins flag, high-risk flag ★, "doctor cleared me for exercise" ★ | MVP |
| **Today (home)** | Week ring, baby size (Indian fruit and vegetable comparisons), today's plan (supplements, session, walk), next visit, Screen Rest status, SOS | MVP |
| **Journey (trimester-wise)** | Trimester tabs, week picker, baby and body notes per week, weekly checklist, trimester progress from her own logs | MVP |
| **Garbhasanskar** | Daily path (read · listen · activity · talk to baby), library of **imported** books and audio, reading sessions with timer and night-reading mode, audio that keeps playing with the screen off, "Letters to baby" journal ★ | MVP |
| **Screen Rest** | Screen-free hours, meal-time rest, eye-rest nudge, wind-down audio. P2: opt-in limits on other apps | MVP → P2 |
| **Supplements** | Schedule as prescribed, reminders, mark taken, weekly adherence, refill alerts ★, personal notes | MVP |
| **Vaccines & tests** ★ | Editable India template (Td doses, GTT, scans, blood tests) with dates and status | MVP |
| **Doctor visits** | Appointments, reminders, "questions to ask" collected over weeks ★, what to bring, notes, prescription photo, next visit | MVP |
| **Walking** | Walk timer, steps from Apple Health / Health Connect, daily goal, history | MVP |
| **Exercise** | Trimester-filtered guided routines with timers, locked until "doctor cleared me" is on | MVP |
| **Vitals** ★ | Weight and blood pressure logs (blood sugar in P2). Logged values only — no interpretation | MVP / P2 |
| **Third-trimester tools** ★ | Kick counter (pattern-based), contraction timer; hospital bag checklist and birth plan in P2 | MVP / P2 |
| **Safety** ★ | SOS (108, doctor, family), share live location, emergency card, WHO danger-sign list | MVP |
| **Pregnancy loss handling** ★ | Pause or end tracking; immediately stops baby content and reminders | MVP |
| **Wellbeing** ★ | Mood and symptom journal, sleep log, water, meditation | P2 |
| **Nutrition** ★ | Owner-written meal notes and "foods I avoid" list | P2 |
| **Records vault** ★ | Encrypted on-device store for reports, scans, prescriptions; PDF summary for visits | P2 |
| **Widgets** ★ | Home-screen widget (week + next reminder) | P2 |
| **Postpartum & baby mode** ★ | Recovery, feeding, sleep, baby vaccine schedule | P3 |
| **Family sharing** ★ | Needs a backend; only if wanted later | P3 (optional) |

## 4. Interactive prototype

The prototype covers 16 screens, each in light and dark mode, with a clickable flow and the theme sheet: [Navmaas Screens](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8).

Screens: Onboarding · Today · Journey · Sessions · Reading session · Listen (screen-off) · Walk · Exercise · Screen Rest · Care · Supplements · Doctor visit · Kick counter · Contraction timer · SOS & emergency card · Me & settings.

## 5. Pushbacks still open

### 5.1 Keep one piece of safety content
Even as a tracking aid, the app keeps a **fixed list of pregnancy danger signs** (WHO) on the SOS screen, a "baby moving less → call now" line on the kick counter, and stop-signs on exercise sessions. These are short, static, sourced and never personalised. Removing them would make the app less safe without making it any simpler.

### 5.2 Screen Rest across other apps needs native work
- **iOS:** needs the Family Controls capability. For personal installs, the development entitlement works without Apple's approval; distribution through TestFlight or the App Store would need it approved.
- **Android:** needs "Usage access", which the user grants in Settings.
- **Plan:** MVP Screen Rest works inside Navmaas only; limits on other apps come in P2 through platform channels (Swift extension and Kotlin).

### 5.3 Installing on iPhone for personal use
A free Apple ID signs builds for only 7 days at a time. For a build that keeps working, enrol in the Apple Developer Program (paid, yearly). Android can install a signed APK directly.

### 5.4 Data loss risk
With no cloud account, a lost phone means lost data. The app offers an **encrypted backup file** that the user saves wherever they choose, such as Google Drive, iCloud Drive or WhatsApp to self, plus a weekly backup reminder.

### 5.5 Kick counting
The counter shows her usual pattern and always says "reduced movement → call now, don't wait". It never says everything is fine.

### 5.6 Notifications
There's a daily notification limit (default 4), digest bundling and quiet hours. iOS allows only 64 pending local notifications, so the scheduler uses a rolling window (see [Architecture](ARCHITECTURE.md#7-reminder-scheduler)).

### 5.7 Hard lines
- No sex prediction or sex-selection content (PCPNDT Act).
- No outcome claims ("raises IQ").
- No dose suggestions.
- No copyrighted text or audio committed to this public repo.

## 6. Roadmap

| Phase | Scope |
|---|---|
| **0 — Discovery & design** ✅ | Plan, name, theme, prototype, architecture |
| **1 — MVP** | Milestones M1–M6 in [Architecture §13](ARCHITECTURE.md#13-delivery-milestones) |
| **2** | Other-app Screen Rest, wellbeing, nutrition notes, records vault + PDF, widgets, blood sugar |
| **3** | Postpartum & baby mode, optional family sharing |
