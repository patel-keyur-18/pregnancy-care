# Pregnancy Care App — Product & Technical Plan

| | |
|---|---|
| **Status** | Draft v1 — awaiting approval |
| **Platforms** | iOS + Android |
| **Working name** | Matru (placeholder) |
| **Last updated** | 2026-10-04 |

Legend: ★ = feature added during brainstorming (not in the original brief).

---

## 1. Quick take

Most mainstream pregnancy apps are ad-funded content + tracker apps; the Garbhasanskar apps that exist are mostly content libraries. Very few combine **Garbhasanskar practice + a calm, low-screen experience + medical-care tracking** with strong privacy. That combination is the differentiator.

The biggest risks are not technical — they are **medical safety, data privacy and content rights**. This plan is built around those.

## 2. Product principles

1. **Calm by default** — an app that asks her to use the phone less must itself be low-screen: audio-first sessions, few notifications, get in and get out.
2. **Safe, not medical** — the app informs and tracks; it never diagnoses. Warning symptoms always route to "contact your doctor" or emergency help.
3. **Private by design** — works without an account, data stays on the device, no ads, never sells data.
4. **No guilt** — gentle progress, no punishing streaks; every pregnancy day is different.
5. **Inclusive** — Garbhasanskar is an optional module, not a requirement; multilingual; runs well on low-end Android; includes partners and family.

## 3. Feature map

| Module | What it does | Phase |
|---|---|---|
| **Onboarding & pregnancy engine** | Due date from last period, conception date, IVF transfer or scan. Shows weeks + days, the month ("Month 4" — many families count in months) and trimester. Twins support, high-risk flag ★, "doctor cleared me for exercise" setting ★ | MVP |
| **Today (home)** | Week and baby size (optional Indian fruit comparisons), today's plan (supplements, session, walk), next appointment, one gentle tip | MVP |
| **Journey (trimester-wise)** | Week by week: baby's development, body changes, symptoms and relief, tests/scans due, nutrition focus, safe exercises, partner tip. Trimester hub with checklist and progress summary | MVP |
| **Garbhasanskar** | Daily plan per week (reading + mantra/music + activity + talk-to-baby); library of books, chapters and stories; audio sessions that play with the **screen off** and download for offline use; reading log (in-app or physical book); "Letters to baby" journal ★ | MVP (starter library) → P2 full courses |
| **Screen Rest** (no-screen-time alerts) | Scheduled screen-free hours, bedtime wind-down, gentle nudges during long in-app sessions, eye-rest reminders. P2: opt-in limits on *other* apps | MVP → P2 |
| **Supplements** | Schedule as prescribed, reminders, mark as taken, adherence view, refill alerts ★ | MVP |
| **Vaccines & tests** ★ | Country template (India: Td; US: Tdap, RSV, flu) plus a timeline of scans and lab tests (NT scan, anomaly scan, glucose test, blood count, thyroid). All editable | MVP |
| **Doctor visits** | Appointments and reminders, "questions to ask" list collected over the weeks ★, visit notes, prescription photo, next-visit date | MVP; P2 adds a PDF summary for the doctor |
| **Walking** | Guided walk timer, steps from Apple Health / Health Connect, trimester-adjusted daily goal, history | MVP |
| **Exercise** | Trimester-filtered guided routines (prenatal yoga, stretches, pelvic floor, breathing/pranayama), session log. Requires doctor clearance | MVP |
| **Vitals** ★ | Weight with a recommended gain range based on pre-pregnancy BMI, blood pressure. Blood sugar (gestational diabetes) in P2 | MVP / P2 |
| **Third-trimester tools** ★ | Kick counter and contraction timer (MVP); hospital bag checklist and birth plan (P2) | MVP / P2 |
| **Safety** ★ | Warning-symptom guide; one-tap SOS (call doctor / partner / ambulance 108 or 102, share location); emergency card (blood group, doctor, hospital) | MVP |
| **Pregnancy loss handling** ★ | Pause or end tracking; immediately stops all baby content and notifications; support resources. Must ship in the MVP | MVP |
| **Wellbeing** ★ | Mood and symptom journal, sleep log with side-sleeping reminder (from week 28), water intake, meditation, mood screening (EPDS) routed to the Tele-MANAS 14416 helpline | P2 |
| **Nutrition** ★ | Trimester diet guidance (veg / non-veg / Jain), "Can I eat this?" lookup, recipes | P2 |
| **Family / partner** ★ | Shared view for partner or family, partner tips, reading sessions done together | P2 |
| **Records vault** ★ | Encrypted storage for reports, scans and prescriptions | P2 |
| **Postpartum & baby mode** ★ | Recovery, feeding and sleep tracking, baby vaccine schedule, postpartum mood checks | P3 |
| **Later ideas** ★ | Home-screen widgets and Live Activities (P2); AI assistant limited to reviewed content, smartwatch support, clinic portal, India ABHA health-record link (P3) | P2 / P3 |

## 4. Pushbacks and risks

### 4.1 Screen-time alerts are restricted by iOS and Android
- **iOS:** Apple's Screen Time API needs the Family Controls entitlement, which Apple must approve. The app never sees actual usage numbers — it only gets notified when a limit is crossed — and it needs native Swift extensions.
- **Android:** the user must grant "Usage access" manually in Settings. Real-time blocking would need the Accessibility API, which Google Play heavily restricts.
- **Recommendation:** MVP Screen Rest needs no OS permissions. Opt-in OS-level limits come in P2. Apply for Apple's entitlement during Phase 0 — approval can take weeks.

### 4.2 Medical and regulatory line
- An app that *interprets* readings ("your BP is dangerous") can be classified as Software as a Medical Device — CDSCO (India), FDA (US), MDR (EU) — and gets stricter store review (Apple guideline 1.4.1, Google Play health apps declaration).
- The app logs, educates and shows fixed "call your doctor" thresholds reviewed by a clinician.
- The app never recommends doses; she enters what her doctor prescribed.
- **An OB-GYN advisor must sign off all medical content.** The app shows "reviewed by" and the review date.

### 4.3 Garbhasanskar content rights and claims
- Most popular Garbhasanskar books are copyrighted. Options: licence, author partnership, public-domain texts (shlokas, classical stories) with original commentary, or commissioned content. Audio narration needs its own rights.
- No unproven outcome claims ("raises baby's IQ"); frame as bonding, calm and stress relief.
- **Hard legal line:** India's PCPNDT Act bans sex prediction and sex-selection content. No "boy or girl" feature, and some traditional texts need editing for this reason.

### 4.4 Privacy
- Pregnancy data is among the most sensitive personal data. Relevant rules include India's DPDP Act, GDPR (if serving the EU), and US laws such as Washington's My Health My Data Act and the FTC Health Breach Notification Rule.
- **Recommendation:** local-first storage, no account required, encrypted on-device database, no ad SDKs, opt-in analytics, one-tap export and delete.

### 4.5 Kick counting needs care
UK guidance discourages "count to 10" in favour of learning the baby's normal pattern. The counter shows the pattern and always says *"reduced movement → call now, don't wait"*. It never tells her everything is fine.

### 4.6 Notification overload works against the calm goal
- Supplements, water, walks, reading, Screen Rest and appointments could add up to 10+ alerts a day.
- A **daily notification limit** (≈4 by default), digest bundling and quiet hours.
- iOS allows only 64 pending local notifications, so reminders use a rolling scheduler.

### 4.7 No streaks or badges
They cause guilt on days with nausea or bed rest. Gentle weekly summaries replace them.

### 4.8 Scope
The full feature map is roughly 9–12 months of work for a small team. Ship a focused MVP and add the rest in waves.

### 4.9 Exercise safety
Placenta previa, preeclampsia, bleeding and some other conditions rule exercise out. Routines stay locked until she confirms doctor clearance; the high-risk flag hides some routines; every session lists warning signs to stop.

### 4.10 Monetization
No ads (privacy, trust, Apple's health-data rules). A pregnancy has a natural end, so a one-time **"pregnancy pass"** may fit better than an auto-renewing subscription. Safety features stay free forever.

## 5. Architecture decisions

All decisions below are **Proposed** until confirmed.

| # | Decision | Options | Recommendation |
|---|---|---|---|
| 1 | App framework | React Native (Expo) / Flutter / native Swift + Kotlin / Kotlin Multiplatform | **React Native + Expo (TypeScript).** One language across app, CMS and backend; over-the-air updates for content and fixes; mature HealthKit, Health Connect, background audio and notification libraries. Flutter is equally good if the team is Dart-first. Either way, iOS widgets and the Screen Time extension need some native Swift. |
| 2 | Where data lives | Device only / local-first with optional sync / cloud-first | **Local-first.** MVP is fully offline with no account (encrypted SQLite on device). P2 adds an optional account for backup, multi-device and partner sharing. Schema designed for sync from day 1. |
| 3 | Backend | Supabase / Firebase / custom (NestJS + Postgres) | **Supabase, Mumbai region.** Postgres suits relational health data; row-level security handles partner sharing; no lock-in. **MVP backend serves content only.** |
| 4 | Content management | Payload / Sanity / Strapi | **Payload CMS** (TypeScript, self-hosted). Draft → medical review → publish workflow, multilingual, content packaged for offline download. |
| 5 | Market & languages | India-first / global | **India first, English + Hindi at launch**, ready for regional languages. |
| 6 | Sign-in (P2) | Phone OTP / email / Apple & Google | **Phone OTP + Apple and Google sign-in.** |
| 7 | Monetization | Free / subscription / one-time pass / B2B | **Free core + premium Garbhasanskar content pass**; hospital partnerships later. |
| 8 | Analytics & crash reporting | — | **Sentry (personal data scrubbed) + opt-in, privacy-friendly analytics.** No ad or attribution SDKs. |

### 5.1 High-level architecture (preview)

```
┌──────────── Mobile app (iOS + Android) ──────────────────────────┐
│ UI: design tokens (light/dark) · Today · Journey · Sessions ·    │
│     Care · Me                                                     │
│ Core: pregnancy engine (due date / weeks) · reminder scheduler   │
│       (limits, quiet hours, digests) · safety rules              │
│ Data: encrypted SQLite on device · secure key storage · records  │
│ Native: HealthKit / Health Connect · local notifications ·       │
│         background audio · widgets · Screen Time extension (P2)  │
└──────────┬──────────────────────────────────┬────────────────────┘
           │ content packs (read-only)        │ P2: backup, sync, partner sharing
   ┌───────▼────────┐  publish   ┌────────────▼─────────────────────┐
   │ CDN: audio,    │◄───────────│ Payload CMS (writers, medical    │
   │ images, JSON   │            │ reviewer, translators)           │
   └────────────────┘            │ Supabase (P2): Auth, Postgres    │
                                 └──────────────────────────────────┘
```

- **Pregnancy engine** — pure, heavily unit-tested date maths: last period with cycle-length adjustment, conception date, IVF day-3 / day-5 transfer, re-dating from a scan. Trimester boundaries at 13w6d and 27w6d.
- **Reminder scheduler** — the single place notifications are created. Enforces the daily limit and quiet hours, bundles reminders, works offline, handles the iOS 64-notification cap with a rolling window.
- **Content packs** — the app ships with base content for an offline first run, then downloads delta updates.

## 6. Theme direction

Finalised in the design-system deliverable before any screens are designed.

- **Light mode** — warm cream background (never pure white), soft sage green primary, dusty rose accent, lavender for sleep and meditation, warm charcoal text (never pure black).
- **Dark mode** — warm deep plum-charcoal (never pure black) with muted versions of the same hues. A warm amber **night-reading mode** for bedtime sessions; dark mode can switch on by schedule.
- **Contrast** — text meets WCAG AA (4.5:1). Calm does not mean faint; vision changes are common in pregnancy.
- **Type** — soft rounded sans-serif for UI (e.g. Nunito), reading serif for long sessions (e.g. Literata), Noto / Mukta families for Indic scripts. Respects system text size.
- **Layout & motion** — touch targets ≥ 48dp for easy one-handed use, slow animations that respect "reduce motion", **red reserved for emergencies only**.

## 7. Roadmap

Rough estimates, assuming 2 mobile developers, 1 designer, a part-time backend developer, a content writer and a medical reviewer.

| Phase | Duration | Scope |
|---|---|---|
| **0 — Discovery & design** | ~2–3 weeks | This plan → architecture design → theme & design system → interactive screen prototype → content & medical-advisor plan → privacy policy draft → apply for Apple's Family Controls entitlement |
| **1 — MVP** | ~4 months | Everything marked MVP, in English + 1 Indian language, offline, no account |
| **2** | ~3 months | Accounts & sync, partner sharing, OS-level Screen Rest, wellbeing, nutrition, records vault, PDF visit summary, widgets, premium content |
| **3** | — | Postpartum & baby mode, AI assistant limited to reviewed content, smartwatches, clinic portal, ABHA link |

## 8. Phase 0 deliverables (after approval)

1. **Theme & design system** — light and dark colour tokens with contrast checks, typography, core components.
2. **Architecture design** — system diagram, module boundaries, data model, sync plan, notification scheduler, security & privacy model, integrations, testing and CI/CD.
3. **Interactive screen prototype** — clickable phone screens with a light/dark toggle:
   - onboarding, Today, Journey (week and trimester)
   - Garbhasanskar player with screen-off mode, Screen Rest
   - supplements, vaccines & tests, doctor visit
   - walk and exercise sessions, kick counter, contraction timer
   - SOS & emergency card, settings

## 9. Open questions

| # | Question | Default if unanswered |
|---|---|---|
| 1 | Is the plan and MVP scope approved? Anything to add or cut? | — (blocking) |
| 2 | Target market and launch languages? | India-first, English + Hindi |
| 3 | What does the team code in (JS/TS, Dart, native)? | React Native + Expo |
| 4 | Where will Garbhasanskar content come from (licence, author partnership, organisation, own/commissioned)? | — (blocking for content plan) |
| 5 | Is there an OB-GYN advisor, or does one need to be found? | Needs to be found |
| 6 | Monetization: free, premium pass, subscription, undecided? | Free core + premium content pass |
| 7 | App name? | "Matru" placeholder |
| 8 | Will this repository be public? It is MIT-licensed, so any licensed book/audio content must live outside the repo (in the CMS/CDN). | Private; content never committed |
