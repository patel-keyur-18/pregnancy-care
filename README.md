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
- wellbeing logs (mood, symptoms, sleep, water) and meditation

> **Status:** the MVP (M1–M6) is built: M1–M4 on 2026-10-05, M5 and M6 on 2026-10-06: onboarding, Today with its gentle plan and next visit, a trimester-wise Journey with original week-by-week notes, supplements with on-time reminders (even when the phone is locked), tests and vaccines from an India template, doctor visits with questions and encrypted prescription photos, vitals, Sessions with the Garbhasanskar path, your own books (PDF, text) and audio with a calm reader and screen-off listening, letters to baby, walks with steps from Apple Health / Health Connect, gentle exercise routines once the doctor has cleared you, slow breathing, a kick counter and contraction timer, pause or end tracking with one quiet page, the iPhone build-expiry reminder, password-protected backup and restore (with a weekly reminder), Screen Rest (bedtime and meal-time rest that keep reminders quiet, an eye rest while reading, a wind-down nudge and time in Navmaas today), and Me (with delete all data) — all on an encrypted on-device database.
>
> **Phase 2:** M7a (2026-10-06) adds Wellbeing in Care: a daily mood check-in in five calm words, a symptom log of common discomforts (a log, never advice), sleep with a weekly average, water toward a goal she sets with optional gentle reminders, and a "How are you today?" card on Today. M7b adds Meditation in Sessions: 5 to 20 minutes between two soft, original bells (they ring even with the phone locked), or your own audio. M10a adds home-screen widgets on iPhone and Android: your week and the next reminder, with "Hide details on widget" in Me.
>
> **Next:** the rest of Phase 2 (M8–M11: body and birth prep; records vault, visit PDF and EPUB; widgets and app lock; limits for other apps on Android), then Phase 3 (M12–M14: postpartum mode, baby feeding and sleep, baby vaccines and visits). Family sharing is out of scope. Each milestone's scope and done-when criteria are in [Architecture §15](docs/ARCHITECTURE.md#15-delivery-milestones).
>
> Navmaas is a personal tracking aid, not medical advice. It has no emergency features.
>
> The iPhone build is signed with a free Apple ID and renewed from Xcode every 7 days ([how](docs/ARCHITECTURE.md#12-iphone-with-a-free-apple-id)).

## Install on your phones

**Android** (once: make a signing key and keep it safe, outside this repo; every update must be signed with the same key, or the old app has to be removed, which deletes its data):

```sh
keytool -genkeypair -v -keystore ~/navmaas-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias navmaas
```

Then create `android/key.properties` (git-ignored, never committed):

```properties
storeFile=/Users/<you>/navmaas-upload.jks
storePassword=<the password you chose>
keyAlias=navmaas
keyPassword=<the password you chose>
```

Build the phone APK (Arm only, about 66 MB) and install it with the phone connected over USB (USB debugging on):

```sh
flutter build apk --release --target-platform android-arm,android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

`-r` installs over the existing app and keeps its data. Without `key.properties` the build is signed with the debug key, which is fine for a try-out but can't update a phone that has the release-signed app.

**iPhone** (free Apple ID): connect the phone, then `flutter run --release`, and do it again within 7 days; the app reminds you the day before. First-time steps (Developer Mode, the personal team, trusting the certificate) are in [Architecture §12](docs/ARCHITECTURE.md#personal-install-steps).

Before reinstalling or moving phones, make a backup in Me → Backup & restore.

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
