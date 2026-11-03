# E5–E7 Walk done, move breaks and the week's history — design

*Approved in conversation 2026-11-03. Adds enhancements E5–E7 to [ARCHITECTURE §15](../../ARCHITECTURE.md#enhancements-e1e4); the Plan, Architecture, Design System and `CLAUDE.md` are updated in the PRs that build them.*

## 1. Intent

The owner asked (2026-11-03) for three things:

1. **Walk done by hand, or by steps.** Today's walk row can't be ticked, and it is only done after a timed walk. She wants to tick it herself, and to see it done once she reaches her step goal (6,000 by default).
2. **Move breaks.** A reminder every hour to stand up and walk for 5 minutes, for a pregnant woman at a desk job who sits most of the day.
3. **The week's history.** For every week so far, not only the last one: supplements taken, walks, exercise and everything else she logged, shown in the app.

**Success:** she ticks the walk without starting a timer; the tick appears by itself on a 6,000-step day; on workdays she is reminded to move, gently and only in her working hours; and in Journey she can open any past week and see what she did.

## 2. Constraints carried over

- **No guilt** (Plan principle 4): no scores, streaks, percentages as grades, red or "missed". Weeks show what she did; empty rows are hidden.
- **Calm notifications:** off by default; every notification goes through `ReminderSync`; quiet hours and meal times still drop nudges.
- **No interpretation:** values only. The move-break text gives no medical reason.
- **No network, no new packages, no schema change** (owner: "whichever has less complexity").
- **Design first** (ADR 043): the Walk "Move breaks" card and Journey's "Your week" card get prototype boards, light and dark, approved before code. Today's walk tick is a small prototype change (no approval needed).
- **Process:** one branch from `main` and one PR each, version bumped, Conventional Commits title, docs in sync in the same PR.

## 3. Pieces and order

| # | PR | Branch | Version |
|---|---|---|---|
| E5 | `feat(today): tick the walk by hand or by steps` | `feat/e5-walk-done` | 1.9.0 |
| E6 | `feat(walk): hourly move breaks` | `feat/e6-move-breaks` (from `main` after E5) | 1.10.0 |
| E7 | `feat(journey): the week's history` | `feat/e7-week-history` (from `main` after E6) | 1.11.0 |

Plan decisions 81–83 and ADRs 067–069, one each.

## 4. E5 — Walk done by hand or by steps

- **Tick by hand** on Today's plan, exactly like reading (Plan decision 55): the tick logs a walk session of `walkGoalMinutes` (20 min) at `clockNow()`, no steps. Untick removes only hand-ticked walks; a timed walk keeps the row ticked and the circle not tappable.
- **Marker (owner: lowest complexity, no schema change):** a hand-ticked walk is a `walk` session with `routineKey = 'by-hand'` (`walkByHandKey`, documented in the data model). Walks never had a routine key, so nothing else reads it.
- **Done by steps:** the row is also done when `todayStepsProvider` ≥ `stepGoalProvider`. Nothing is logged. A step-done row can't be unticked (the circle isn't a button), like reading done in the reader. If she ticked by hand and then reaches the goal, untick still removes the hand walk; the row stays done by steps.
- **Fresh steps:** Today re-reads steps when the app resumes (invalidate `todayStepsProvider` on resume). Without Health access steps are null and only the tick and timed walks count.
- **Unchanged:** Journey's trimester walk count and the widget still count logged walks (a hand tick is a logged walk; a steps-only day is not).

## 5. E6 — Move breaks

- **Settings** (Walk screen, new "Move breaks" card under the step goal; `settings` keys):
  - `move_remind` — on/off, default **off**.
  - `move_every` — 1 or 2 hours, default 1.
  - `move_from` / `move_until` — minutes after midnight, default 600 / 1020 (10:00–17:00).
  - `move_days` — weekdays as digits 1–7 (Monday = 1), default `12345`; she can pick any days, every day included.
- **Times:** on each chosen day, every `move_every` hours after `move_from`, up to and including `move_until` (default 11:00, 12:00 … 17:00). Planned only for the active pregnancy.
- **Words** (`app_en.arb`, content-test checked): title "Move", body "Stand up and walk gently for 5 minutes, whenever you're ready."
- **Tap** opens Walk (`ReminderOpen.walk` when the notification is only move breaks).
- **Planner changes** (pure, table-tested):
  - Key prefix `move@`, kind `nudge`: dropped in quiet hours and meal windows, bundled with anything within 30 minutes (generic title then).
  - **Outside the daily limit** (owner approved): a bundle made only of move breaks is kept without counting toward `dailyLimit`. A bundle with anything else counts as before.
  - **Cap:** step 4 keeps every non-nudge first, then fills the rest of the 60 with nudges nearest first, so a week of move breaks can't push out a visit six days away.
  - **App limits** (`limit_rules`): a day's "room" doesn't count move-break-only notifications.
- `ReminderSettings` gains the move fields (in `_fields`), and the settings change re-plans.

## 6. E7 — The week's history

- **Where:** Journey. For the picked week, when it is the current week or earlier (in this pregnancy), a **"Your week"** card under the checklist. Every past week keeps its card, for as long as the data is there. Future weeks show none.
- **The week:** pregnancy week *w* = days `start + 7w` to `start + 7w + 6` (the engine's `gaDays ~/ 7`), up to today for the current week.
- **Rows** (hidden when nothing was logged; values only):
  - Supplements — "12 of 14 doses taken" (`adherence`).
  - Walk — days walked (a logged walk, or steps ≥ today's goal on that day), total minutes, steps that week from Health (shown only with access).
  - Exercise — sessions · minutes.
  - Reading, Listening, Meditation, Breathing — minutes each.
  - Water — average glasses a day (over days with a log).
  - Sleep — average hours.
  - Mood — the words logged, with counts ("Calm 3 · Tired 2"), no colours.
  - With nothing at all: one calm line ("Nothing logged this week.").
- **Code:** a pure `weekReport()` in `features/journey/domain/` from sessions, doses, wellbeing logs and per-day steps; unit-tested. Range-based reads (sessions and doses already have them; wellbeing gains range variants of its week providers). Steps per day come from `StepSource.steps(day, day+1)`, null without access.
- **Not in it:** kicks, contractions, blood sugar and visits (Care has them), a PDF or export, earlier pregnancies.

## 7. Left to the builder

Card layouts follow the approved boards. Exact wording of row labels goes in `app_en.arb` and passes the content test. Tests: planner table cases (limit exemption, cap order, chosen days, meal and quiet drops), `weekReport` cases (empty week, partial current week, step days), widget tests for the tick (tick, untick, timed walk stays, steps done) and the cards, goldens and the accessibility pass for every changed screen.
