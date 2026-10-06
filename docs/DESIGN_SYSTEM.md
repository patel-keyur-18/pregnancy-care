# Navmaas Design System — "Moonlit Sage"

| | |
|---|---|
| **Status** | v1.12 — decided 2026-10-04, updated 2026-10-06 (motion in §5; M3–M11 components; implementation notes in §8) |
| **Prototype** | [Navmaas Screens](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8) — theme sheet plus 29 screens in light and dark (M7 Wellbeing, M10 widgets, lock screen and Me → Your data, and M11 app-limit boards added 2026-10-06) |
| **Web tokens** | [`design/navmaas-tokens.css`](../design/navmaas-tokens.css) (used by the prototype) |

## 1. Why this theme

Pregnancy often brings tired eyes, headaches, nausea and sometimes changes in vision. Late-night use is common too, whether for reading to the baby or for sleepless hours. The theme is built to be easy on the eyes **without losing legibility**.

- **No pure white.** Backgrounds are a warm cream (`#FAF6F0`), which reduces glare.
- **No pure black.** Dark mode is a warm plum-charcoal (`#1B1820`). This avoids the harsh contrast and OLED smearing that pure black causes.
- **Calm ≠ faint.** Every text and background pair meets WCAG AA (≥ 4.5 : 1). Most body text sits at 6–14 : 1.
- **Muted, natural hues.** Sage (calm, growth), dusty rose (warmth), lavender (sleep, rest), amber (gentle notices).
- **Red only for destructive actions.** Restore (which replaces data), delete and error messages are the only red elements, so red always means "this changes or loses data".
- **Night reading.** A warm amber page with low blue light for bedtime Garbhasanskar sessions.

The name comes from *maas* (month), which follows the moon. The logo is a sage crescent moon cradling a small rose seed.

## 2. Colour tokens

### Light · "Dawn"

| Token | Hex | Use | Contrast |
|---|---|---|---|
| `bg` | `#FAF6F0` | Screen background | Text 13.2 : 1 |
| `surface` | `#FFFDF9` | Cards, sheets, tab bar | Text 13.9 : 1 |
| `surface-2` | `#F3EDE4` | Inputs, segmented controls, quiet panels | Text 12.2 : 1 |
| `border` | `#E6DDD1` | Dividers and card edges | Decorative |
| `text` | `#2F2A28` | Primary text | 13.2 : 1 on bg |
| `text-2` | `#5E5650` | Secondary text | 6.7 : 1 |
| `text-3` | `#6E655E` | Captions, hints | 5.3 : 1 |
| `primary` (sage) | `#4A6F5D` | Main buttons, progress, selected state | 5.6 : 1 with `on-primary` `#FFFDF9` |
| `rose` | `#A85A61` | Supplements, baby moments | 4.8 : 1 on surface |
| `lavender` | `#6E63A0` | Sessions, sleep, Screen Rest | 5.2 : 1 |
| `amber` | `#9A6416` | Visits, tests, notices | 4.9 : 1 |
| `danger` | `#B3261E` | Restore, delete, errors only | 6.5 : 1 with white |
| `track` | `#E9E1D6` | Empty part of progress bars and switches | — |

### Dark · "Moonlit"

| Token | Hex | Use | Contrast |
|---|---|---|---|
| `bg` | `#1B1820` | Screen background | Text 13.4 : 1 |
| `surface` | `#24202A` | Cards, sheets, tab bar | Text 12.2 : 1 |
| `surface-2` | `#2D2833` | Inputs, quiet panels | Text 11.0 : 1 |
| `border` | `#3B3542` | Dividers | Decorative |
| `text` | `#E8E0D8` | Primary text | 13.4 : 1 on bg |
| `text-2` | `#C2B8B0` | Secondary text | 9.0 : 1 |
| `text-3` | `#A99F98` | Captions | 6.8 : 1 |
| `primary` (sage) | `#9CC2AE` | Main buttons, progress | 8.6 : 1 with `on-primary` `#15201A` |
| `rose` | `#E2A6A6` | Accents | 7.8 : 1 |
| `lavender` | `#B9AFE3` | Accents | 7.8 : 1 |
| `amber` | `#E2B464` | Accents | 8.3 : 1 |
| `danger` | `#F2B8B5` | Restore, delete, errors only | 9.9 : 1 with `on-danger` `#3B0B08` |
| `track` | `#39323F` | Empty progress | — |

### Soft containers

Each soft container is always paired with its own "on" text colour.

| Pair | Light bg / text | Dark bg / text |
|---|---|---|
| Sage | `#E2ECE5` / `#2C4638` (8.5 : 1) | `#2B3A33` / `#CFE4D7` (9.0 : 1) |
| Rose | `#F6E5E2` / `#743840` (7.2 : 1) | `#3E2A2E` / `#F4D4D2` (9.6 : 1) |
| Lavender | `#ECE8F6` / `#433B6B` (8.4 : 1) | `#302A42` / `#DDD6F5` (9.8 : 1) |
| Amber | `#FAEEDB` / `#65420E` (7.8 : 1) | `#3A2F1F` / `#F2DAAA` (9.6 : 1) |
| Danger | `#FBE4E1` / `#7F1D17` (8.3 : 1) | `#4E201D` / `#FFDAD6` (10.5 : 1) |

> **Rule:** accent hues (rose, lavender, amber) are for icons and fills. On their own soft containers they fall to 4.0–4.4 : 1, so text there always uses the matching "on" colour.

### Reading modes

| Mode | Background / text | Contrast |
|---|---|---|
| Paper | `#F6EEDF` / `#3B2F25` | 11.3 : 1 |
| Night reading | `#1E1913` / `#E3CDA8` | 11.3 : 1, low blue light |
| Screen-off overlay | `#0E0C10` / `#A99F98` | 7.5 : 1 |

## 3. Typography

Both fonts are SIL Open Font License and are **bundled with the app**; there is no runtime font download (see [Architecture ADR-008](ARCHITECTURE.md#17-decision-log)).

| Style | Font | Size / line | Weight |
|---|---|---|---|
| Display | Nunito | 32 / 40 | 800 |
| Title | Nunito | 26 / 32 | 800 |
| Heading | Nunito | 18 / 24 | 800 |
| Body | Nunito | 16 / 24 | 500 |
| Label | Nunito | 14 / 20 | 800 |
| Caption | Nunito | 13 / 18 | 600 |
| Reading | Literata | 19 / 32 | 400 |

- Nunito is rounded and friendly, and stays clear at small sizes. Literata is designed for long reading on screens.
- Minimum text size is 12 px. All sizes follow the phone's text-size setting and are tested at 100 %, 130 % and 200 %.
- Both ship as Google Fonts' variable files (`Nunito[wght]`, `Literata[opsz,wght]`) in `assets/fonts/`, next to their `OFL-*.txt` licences. Flutter maps `fontWeight` onto the `wght` axis.

## 4. Shape, space, touch

- **Spacing:** 4-point grid (4 · 8 · 12 · 16 · 20 · 24 · 32). Screen gutter is 20.
- **Radius:** 8 (chips) · 14 (icon tiles, inputs) · 20 (cards) · 28 (hero cards) · pill (buttons, segmented controls).
- **Touch targets:** at least 48 dp (the prototype draws some at 44 px; the app rounds them up to 48). Main actions sit in the lower half of the screen for one-handed use.
- **Icons:** 24-grid line icons, 1.8 stroke, round caps and joins. No emoji in the interface.
- **Elevation:** a very soft shadow in light mode only. Dark mode separates layers by tone (`bg` → `surface` → `surface-2`).

## 5. Motion

- 250–350 ms ease-out fades and short slides. No bounce, no flashing, no auto-playing animation.
- Respects "reduce motion" and the OS animation scale.

### Icon micro-interactions

Small, calm feedback when an icon is tapped (owner request, M2), plus the breathing pace (M4b). Only these five exist; anything new is added here first.

| Where | Trigger | What moves | Timing |
|---|---|---|---|
| Tab bar | A tab becomes active | The icon's line draws itself (stroke traced 0 → 100 %) while the sage pill fades in | 350 ms, ease-out |
| Icon buttons: tab bar, theme toggle, cycle stepper | Finger down / up | Shrinks to 92 % while pressed, returns on release | 120 ms down, 200 ms ease-out up |
| Theme toggle (Today) | Tap | Moon and sun cross-fade with a 30° turn | 300 ms, ease-out |
| Checklist tick (Journey) | Item ticked | Box fills sage, then the check mark draws itself | 250 ms, ease-out |
| Slow breathing circle (M4b) | Running | The inner circle grows from 60 % to 100 % over 4 s (in) and shrinks back over 6 s (out); only after she taps Start. With reduce motion it stays still and only the words change | Linear, one step a second |

- No overshoot, no bounce, nothing plays on its own. The breathing circle repeats only while she is breathing with it.
- With reduce motion on, every state change is instant and nothing scales.

## 6. Components (as drawn in the prototype)

| Component | Spec |
|---|---|
| Primary button | Pill, 52–56 h, `primary` fill, `on-primary` label 16/800 |
| Secondary button | Pill, 52 h, `surface` fill, 1.5 `border` |
| Destructive button | Pill, 52–54 h, `danger` fill, `on-danger` label 16/800; always next to a `danger-soft` note saying what will be replaced or lost |
| Password field | 48 h, radius 12, `surface-2` fill, 1 `border`; "Show / Hide" button beside it; live hint below (`text-3` → `primary` when valid, `danger` on mismatch) |
| Card | `surface`, 1 `border`, radius 20, soft shadow (light) |
| List row | 56+ h, 40 icon tile (soft pair), title 16/700, caption 13/600 `text-3`, divider `border` |
| Check (done) | 30 circle; done = `primary` fill + check; pending = 2 `border` ring |
| Checklist row (Journey) | 56+ h; 26 box, radius 8, 2 `border`; done = `primary` fill, check drawn in `on-primary`, text turns `text-3` |
| Week chip (Journey) | 52 × 60, radius 16, 1.5 border; selected = `primary` fill with `on-primary` text |
| Take / Taken pill (Care, Supplements) | Pill, 1.5 border; taken = `primary` fill, `on-primary` label 14/800 |
| Week dose dots (Supplements) | 36 circles with "taken/due"; all taken = `primary`, some = `primary-soft`, today = `primary` ring |
| Notice row | Radius 12, 8/10 padding, 13/700: note = `surface-2`; low stock = `amber-soft` with a bell |
| Care row (Coming up, Tests) | 40 icon tile by kind (test = `amber-soft` flask, vaccine = `lavender-soft` shield, scan and visit = `primary-soft`), title 16/800, caption 13/600 `text-3`; optional "Book" chip (`amber-soft`, 12/800) |
| Visit header | `amber-soft` card, radius 24: overline ("IN 3 DAYS"), date and time 22/800, doctor · clinic; two `surface` pill buttons (Call clinic, Directions) |
| Vital tile | Card: label 13/700 `text-3`, value 24/800, detail 13/600, "Log …" pill on `surface-2` |
| Switch | 52 × 32 track (`primary` / `track`), 26 thumb `surface` |
| Segmented control | `surface-2` pill container; selected = `surface` + shadow |
| Progress | 6–8 h bar on `track`, or ring (stroke 8–10) |
| Tab bar | 84 h, 5 tabs (Today, Journey, Sessions, Care, Me); active = `primary-soft` pill behind the icon |
| Word chip (M7) | Pill, 1.5 `border`, `surface`, label 14/800 (16/800 for mood and rested words); chosen = `primary` fill, `on-primary` label with a tick. A selection, never a verdict: no colour per word |
| More chip (M7) | Dashed 1.5 `border` pill, `text-2` label "More · N" / "Fewer" with a chevron; folds the symptom chips to two rows |
| Wellbeing tile (M7) | Card, 40 icon tile (mood `rose-soft` heart, symptoms `surface-2` notes, sleep `lavender-soft` bed, water `primary-soft` drop), label 13/700 `text-3`, value 16/800 |
| App limit row (M11) | 40 app icon (her launcher's, or its first letter on `surface-2`), name 16/800, "18 of 30 min today" 13/600 `text-3`, a 6 px `primary` bar on `track`; past the limit "32 min today · past your 30 min", same colours. On the Limits screen the limit 14/800 `text-2` and a chevron |
| App lock screen (M10) | `bg`; 88 `primary-soft` circle with the lock 36; "Navmaas is locked" 22/800 (heading); the way to unlock 15/600 `text-2`; full-width Unlock (`primary`, 56) |
| Home-screen widget (M10) | `surface`, radius 22, 16 padding. Brand row: 28 `primary-soft` circle with the sprout, "Navmaas" 13/800 `text-3`. Small: week 22/800, "Day N · size" 13/700 `text-2`, bell + "time · title" 13/800 `primary`. Medium: "Week N · day N" 22/800 and the size line 14/600 `text-2`, beside a 128-wide `primary-soft` box (radius 16, 12 padding): bell, "Next" 12/700, title and time 15/800. Hidden: "Next reminder" 12/700 `text-3` over the time 22/800. Stopped: the sprout in a 56 circle |
| Week row (Wellbeing) | Day 15/800 over date 12/700 `text-3`; mood word in an 8-radius `surface-2` chip; sleep · water and symptoms 14/600 `text-2`; "Nothing logged" in `text-3` |

## 7. Flutter mapping

Tokens map onto Material 3 `ColorScheme`. Brand-only colours live in a `ThemeExtension`.

| Token | Flutter |
|---|---|
| `primary` / `on-primary` | `ColorScheme.primary` / `onPrimary` |
| `primary-soft` / `on-primary-soft` | `primaryContainer` / `onPrimaryContainer` |
| `rose` + soft pair | `secondary`, `secondaryContainer`, `onSecondaryContainer` |
| `lavender` + soft pair | `tertiary`, `tertiaryContainer`, `onTertiaryContainer` |
| `danger` + soft pair | `error`, `onError`, `errorContainer`, `onErrorContainer` |
| `surface` / `text` | `surface` / `onSurface` |
| `surface-2` | `surfaceContainerHighest` |
| `text-2` | `onSurfaceVariant` |
| `border` | `outlineVariant` |
| `text-3` | `outline` |
| `bg` | `ThemeData.scaffoldBackgroundColor` |
| `amber` + pair, `track`, reading modes, screen-off | `NavmaasColors` extension |

```dart
// lib/core/theme/navmaas_colors.dart (sketch)
@immutable
class NavmaasColors extends ThemeExtension<NavmaasColors> {
  const NavmaasColors({
    required this.amber,
    required this.amberSoft,
    required this.onAmberSoft,
    required this.track,
    required this.readPaperBg,
    required this.readPaperText,
    required this.readNightBg,
    required this.readNightText,
    required this.sleep,
    required this.sleepText,
  });

  final Color amber, amberSoft, onAmberSoft, track;
  final Color readPaperBg, readPaperText, readNightBg, readNightText;
  final Color sleep, sleepText; // screen-off overlay

  static const light = NavmaasColors(
    amber: Color(0xFF9A6416),
    amberSoft: Color(0xFFFAEEDB),
    onAmberSoft: Color(0xFF65420E),
    track: Color(0xFFE9E1D6),
    readPaperBg: Color(0xFFF6EEDF),
    readPaperText: Color(0xFF3B2F25),
    readNightBg: Color(0xFF1E1913),
    readNightText: Color(0xFFE3CDA8),
    sleep: Color(0xFF0E0C10),
    sleepText: Color(0xFFA99F98),
  );

  // `dark`, copyWith and lerp follow the same shape.
}
```

Theme mode options are **Light / Dark / System**, plus "night reading after 9 pm" for the reader (Me → Appearance, on by default). The reader opens in Night colours from 9 pm to 5 am, or whenever the app is dark; Paper / Night can be switched while reading.

## 8. Implementation status (M11)

The prototype is the exact visual spec (Plan decision 15). M2 closed the M1 gaps: the prototype's own icons (drawn from its SVG paths), the pill segmented control with its soft shadow, and the one-row cycle stepper.

Deliberate, permanent differences:

| Area | Prototype | App | Why |
|---|---|---|---|
| Touch targets | Some buttons and segments 40–44 px | At least 48 dp | Accessibility (§4) |
| Tab-bar labels | Fixed size | Grow with text size up to 1.5× | Five tabs must still fit |
| Journey trimester caption | 11 px | 12 px | Minimum text size (§3) |
| Journey week chips | 52 × 60 | Grow with text size up to 1.6× | The week number never clips |
| Take / Taken pill | 40 px tall | 48 dp | Accessibility (§4) |
| Onboarding | 3 steps | 4 steps: an optional "Your doctor and reminders" step | Owner decision (Plan 22, 23) |
| Remove-time icon | (not drawn) | A × in the same line style | Needed for the supplement form; also on bring-along chips and photos |
| Scan icon | (not drawn) | A screen with a gentle wave, same line style | Scans needed their own icon |
| Past test windows | (not shown) | "Weeks 6–10", not "Due" | No guilt for a window that has passed |
| Reader subtitle | "Chapter 6 · The little lamp" | PDF: "Page 42 of 120"; text: none (the library row shows "42% read") | PDFs don't reliably mark chapters |
| Library row | "chapter 6 of 14" | "page 42 of 120" (PDF) or "42% read" (text) | Same reason |
| Library actions | (not drawn) | Long press a row (or the screen reader's custom action) to rename or remove | No room for a visible menu button in the row |
| Listen chips | "Sleep timer · 10 min" and "Downloaded" | Sleep timer only (tap: off → 10 → 20 → 30 min); 48 dp tall | Everything is already on the phone |
| Path tiles | Fixed text | "Add a book" / "Add audio" when the library is empty; Talk to baby shows "Today's letter is written" | Gentle prompts instead of empty tiles |
| Letters to baby | (not drawn) | A list of letters (date, first lines in Literata) and a writing screen, in the Visit screens' card style | Talk to baby needed somewhere to write |
| Me → Appearance | "Larger text" switch | Not built; the app follows the phone's text size (tested to 2.0×) | The phone's own setting already does this everywhere |
| Journey tiles | Reading sessions · walks logged · supplements taken | Same (M4b); the M2 "checklist done" stand-in is gone | — |
| Walk / Exercise note | Symptom list ("bleeding, dizziness…, call your doctor") with a warning triangle | One general line: "Go gently. Stop and rest if anything feels uncomfortable, and check with your doctor." (after the talk test on Walk) | No danger-sign list (Plan decision 26) |
| Walk screen | "Evening walk" | "Gentle walk"; steps show "—" and an "Allow" link until Health access is given; tap Today's steps to change the daily goal | Any time of day; Health access can be refused |
| Exercise header | "2nd trimester · step 2 of 4" | "Step 2 of 7" (the trimester is on the Sessions tile) | Shorter at large text |
| Exercise controls | Pause in the middle | Pause / Resume, then "Finish" when the last move ends | Clear end of the routine |
| Move & breathe tiles | Four fixed tiles (M7: Meditation as a full-width tile under them) | Walk, this trimester's routines, slow breathing and Meditation in the same two-column grid; locked routines show a lock and "Needs 'Doctor cleared me' in Me" and open Me | Routines follow trimester, high risk and clearance, so the number of tiles varies |
| Me → Exercise | "Unlocks walking and exercise routines" | "Unlocks exercise routines. Walking is always open." | Plan decision 27 |
| Slow breathing | Opens Listen | Its own quiet screen: a lavender circle that grows and shrinks, "Breathe in / Breathe out", 5 min, Start / Pause / Finish | No audio can ship in the repo (Plan decision 28) |
| Today's plan | Walk as an "Evening walk" row | "Gentle walk · 20 min · easy pace", ticked by a logged walk; the "add supplements" prompt is gone because the walk is always there | Walking is always open |
| Kick counter | Fixed sample count and times | The session starts at the first tap ("Started —" before it); leaving with a count saves it too; "Usually most active" appears from three sessions (the two-hour window with the most movements per minute); "Saved sessions appear here." when empty | Nothing is lost; a pattern needs a few sessions |
| Contraction timer | Sample log | Shows the last day's contractions (up to 12); averages cover the last hour, "—" until there are two; a contraction is also saved if she leaves mid-way | A log for the doctor, never a verdict |
| Me → Your data | "Last backup Sat 3 Oct · password protected" | Same row ("No backup yet · password protected" before the first); "Pause or end pregnancy tracking" opens a sheet: Pause tracking, Baby has arrived, End tracking | Plan decision 30 |
| Tracking stopped | (not drawn) | One quiet page in place of the tabs: the moon in a sage circle, a title ("Tracking is paused", "Tracking has ended", "Congratulations"), a calm line, Resume or Start a new pregnancy, and Backup & restore | Plan decision 31; no baby content |
| Backup header | "Saved to Files › Navmaas backups" | "Next reminder Sun 11 Oct" (or "— the day before this iPhone build expires", or "Weekly reminder is off"), and a "Remind me weekly · Sunday" row under it | The app can't know where the share sheet saved it; the reminder day needed a home |
| Backup screen | Fixed sample sizes and counts | Real sizes ("about 2.4 MB" / "about 184.8 MB" with books and audio) and counts; the restore card shows the file's date, size and Navmaas version before the password; Done after a restore goes to Today; the free-Apple-ID note shows on iPhone only | Real data; the note is about iPhone |
| Onboarding step 1 | (no restore) | A "Restore from a backup" link under Continue | A new phone needs to restore before onboarding |
| Library row after a restore without books | (not drawn) | Opening it explains "This file isn't on this phone" with "Re-import file" | ARCHITECTURE §11 |
| Today | (no expiry banner drawn) | An amber banner with the clock icon when the iPhone build expires within a day | ARCHITECTURE §12 |
| Screen Rest header | "Phone down, baby time." and "Next screen-free window starts at 9:30 pm…" | Same card; the line names whichever window is next (a meal time or bedtime), "This is a screen-free time. Navmaas will stay quiet until …" inside one, or an invitation when every rule is off | Real times |
| Screen Rest rules | Four switches with fixed times | Same four; tapping a rule's text changes its times (bedtime, both meal starts, wind-down) | The times needed somewhere to change |
| Limits for other apps | Dashed "Phase 2 · Coming later" card | Not shown | Owner decision: not built until P2, and iPhone can't have it (ADR 012) |
| Today → Screen Rest card | "Screen-free from 9:30 pm" · "Wind-down audio at 9:00 pm — phone down, baby time." | Same with wind-down on; "Phone down, baby time." when it's off; "Screen Rest" · "Set calm, screen-free times." when bedtime rest is off | Wind-down is off by default |
| Me → Quiet hours | "Matches your Screen Rest bedtime" | Same; shows "Off" when bedtime rest is off; still tappable to change the times | Same setting in both places |
| Reader eye rest | (not drawn) | A lavender banner over the top of the page: "Rest your eyes: look far away for 20 seconds.", a countdown and Close; gone after 20 seconds | Screen Rest → Eye-rest nudge |
| Me → Your data | Backup row and "Pause or end pregnancy tracking" | Also a red "Delete all data" text button under them; its dialog (title, what goes, last backup) has "Back up first", Cancel and a red "Delete everything" | Plan decision 35; red only for destructive actions |
| Steppers on Sleep and Water | SVG minus and plus in 44 px circles | The app's `StepButton` (48 dp, "−" / "+"); at large text the stepper moves under its title and the value wraps | Accessibility (§4) |
| Symptom chips | Five chips, then "More · 5" at this width | Folds to whatever fits in two rows at the phone's width and text size (measured), her recent symptoms (and her own) first; the chosen chip always shows | Two rows at every text size |
| Symptoms "Logged today" | Name · strength, time and note | Same, plus a × to remove one (tooltip "Remove …") | Mistakes need undoing |
| Wellbeing header rows | One row | "Your week" and its dates, and "What did you feel?" and "Add your own", wrap to two lines at large text | No overflow at 2.0× |
| Wellbeing tiles with nothing yet | (not drawn) | "Not logged yet"; the sleep card says "Log a night's sleep to see your weekly average." until one night is logged | Gentle empty states |
| Today's card "+" | 44 px `primary` circle | 48 dp filled icon button with the tooltip "Add a glass" | Accessibility (§4) |
| Meditation lengths | "5 min" … "20 min" segments, 40 px | Same labels, 48 dp segments (they wrap to two lines at large text) | Accessibility (§4) |
| Meditation, running | Pause and Finish as 52 px outlined pills; "Breathe softly" / "Paused" | Same, as the app's outlined buttons (48 dp); they wrap under each other at large text; Finish (or the end bell) brings back the length choice | — |
| Meditation, her own audio | One row, "Om chanting · 10:00" | The audio she played last; with more than one, a "Your audio" sheet to choose; it opens Listen headed "Meditation". With none: "Add audio in Sessions first", not tappable | Her library can hold many |
| Home-screen widget font | Nunito | The phone's system font: SF Rounded on iPhone, sans-serif on Android, same sizes and weights | Widgets are drawn by the home screen, outside the app, where its bundled fonts aren't loaded |
| Home-screen widget, Android | (drawn for iPhone) | One resizable widget with the medium layout | One layout keeps the RemoteViews code small; it resizes down to about 3 × 2 cells |
| Small widget's reminder line | "8:00 pm · Folic acid" | Shrinks to 85 % before it truncates | SF Rounded runs wider than Nunito |
| App lock screen | Lock, title and line centred on the whole screen | Centred in the space above Unlock, and it scrolls at large text | No overflow at 2.0× |
| Me → App lock subtitle | "Face ID or your passcode to open Navmaas" | Same on iPhone; "Fingerprint or screen lock to open Navmaas" on Android | Each phone's own words |
| Turning on app lock without a phone screen lock | (not drawn) | The switch stays off and a snackbar says "Set a screen lock on your phone first, then turn on app lock." | Otherwise she could lock herself out |
| App switcher cover | (described in a canvas note) | The sprout in an 88 `primary-soft` circle on `bg` | — |
| Screen Rest's limits card while Usage access is off | (not drawn) | "Paused: Usage access is off" in `on-amber-soft` instead of the app rows, then Manage limits | A calm notice in amber (§2) |
| Daily limit sheet | Minute chips in a three-column grid, 48 px | The same six choices as chips that wrap, 48 dp | They wrap at large text |
| Limits for other apps, the notice preview | Always shown | Shown once she has a limit, for her first one | It previews her own notice |
