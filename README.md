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

> **Status:** M1 Foundation is built (2026-10-05): onboarding, the pregnancy engine, Today and Me on an encrypted on-device database. Next is M2 (Today & Journey).
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
