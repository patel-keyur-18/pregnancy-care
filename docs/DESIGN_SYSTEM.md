# Navmaas Design System — "Moonlit Sage"

| | |
|---|---|
| **Status** | v1.1 — decided 2026-10-04, updated 2026-10-05 (SOS removed; red now marks destructive actions) |
| **Prototype** | [Navmaas Screens](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8) — theme sheet plus 16 screens in light and dark |
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
- Minimum text size is 12 px. All sizes follow the phone's text-size setting and are tested at 200 %.

## 4. Shape, space, touch

- **Spacing:** 4-point grid (4 · 8 · 12 · 16 · 20 · 24 · 32). Screen gutter is 20.
- **Radius:** 8 (chips) · 14 (icon tiles, inputs) · 20 (cards) · 28 (hero cards) · pill (buttons, segmented controls).
- **Touch targets:** at least 48 dp. Main actions sit in the lower half of the screen for one-handed use.
- **Icons:** 24-grid line icons, 1.8 stroke, round caps and joins. No emoji in the interface.
- **Elevation:** a very soft shadow in light mode only. Dark mode separates layers by tone (`bg` → `surface` → `surface-2`).

## 5. Motion

- 250–350 ms ease-out fades and short slides. No bounce, no flashing, no auto-playing animation.
- Respects "reduce motion" and the OS animation scale.

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
| Switch | 52 × 32 track (`primary` / `track`), 26 thumb `surface` |
| Segmented control | `surface-2` pill container; selected = `surface` + shadow |
| Progress | 6–8 h bar on `track`, or ring (stroke 8–10) |
| Tab bar | 84 h, 5 tabs (Today, Journey, Sessions, Care, Me); active = `primary-soft` pill behind the icon |

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
  });

  final Color amber, amberSoft, onAmberSoft, track;
  final Color readPaperBg, readPaperText, readNightBg, readNightText, sleep;

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
  );

  // `dark`, copyWith and lerp follow the same shape.
}
```

Theme mode options are **Light / Dark / System**, plus "night reading after 9 pm" for the reader.
