# Navmaas · नवमास

**Nine months, gently.** A calm, private pregnancy companion for iOS and Android, built with Flutter.

It combines:

- Garbhasanskar practice (reading, listening, talking to baby)
- low-screen habits (Screen Rest)
- care tracking (supplements, vaccines and tests, doctor visits, vitals)
- trimester-wise guidance
- walking and exercise sessions
- third-trimester logs (kick counter, contraction timer)
- password-protected backup and restore

> **Status:** M1–M4 are built (2026-10-05): onboarding, Today with its gentle plan and next visit, a trimester-wise Journey with original week-by-week notes, supplements with on-time reminders (even when the phone is locked), tests and vaccines from an India template, doctor visits with questions and encrypted prescription photos, vitals, Sessions with the Garbhasanskar path, your own books (PDF, text) and audio with a calm reader and screen-off listening, letters to baby, walks with steps from Apple Health / Health Connect, gentle exercise routines once the doctor has cleared you, slow breathing, and Me — all on an encrypted on-device database. Next is M5 (third trimester and backup).
>
> Navmaas is a personal tracking aid, not medical advice. It has no emergency features.
>
> The iPhone build is signed with a free Apple ID and renewed from Xcode every 7 days ([how](docs/ARCHITECTURE.md#12-iphone-with-a-free-apple-id)).

## Documents

| Document | What's inside |
|---|---|
| [Plan](docs/PLAN.md) | Approved decisions, feature map by phase, notes and constraints, roadmap |
| [Design system](docs/DESIGN_SYSTEM.md) | "Moonlit Sage" light/dark theme, contrast-checked tokens, type, components, Flutter mapping |
| [Architecture](docs/ARCHITECTURE.md) | Flutter stack, structure, pregnancy engine, reminder scheduler, data model, backup & restore, free-Apple-ID install, security, milestones, ADRs |
| [Interactive prototype](https://claude.ai/artifact/SQRrhaQU7odSc5FLNeKcJ8) | 16 clickable screens in light and dark, plus the theme sheet (private link; share from its Share menu) |
| [`design/navmaas-tokens.css`](design/navmaas-tokens.css) | The colour tokens used by the prototype |
| [`CLAUDE.md`](CLAUDE.md) | Commands (run, test, build, codegen), folder conventions and hard lines |

## Principles

1. **Calm by default** — audio-first, few notifications, low screen time.
2. **Track, don't diagnose** — records and reminds; medical decisions stay with the doctor.
3. **Private by design** — no account, no network calls, data encrypted on the phone.
4. **No guilt** — gentle progress, no punishing streaks.
5. **Inclusive** — Garbhasanskar is optional; runs well on low-end phones.

## Content note

This repository is public. It contains only original or public-domain content. Personal books and audio are imported inside the app. They leave the phone only inside a password-protected backup that you choose to make.
