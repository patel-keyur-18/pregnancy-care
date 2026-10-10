# Release signing (one key for Navmaas and Nourishly) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every release APK of Navmaas and Nourishly, whether from CI or the owner's Mac, is signed with the one keystore the owner made. Updates then install in place, and the M8b signature permission works.

**Architecture:** Gradle already (Navmaas) or newly (Nourishly) reads `android/key.properties` and falls back to the debug key without it. CI writes `key.properties` and the keystore from four repository secrets before `flutter build apk`, and prints the APK's cert digest. No key material is committed.

**Tech Stack:** Gradle Kotlin DSL, GitHub Actions, `apksigner`.

**Spec:** `docs/superpowers/specs/2026-10-10-m8-body-birth-prep-design.md` §4

## Global Constraints

- Never commit a `.jks`, `.keystore` or `key.properties` (CLAUDE.md hard line). Both repos already git-ignore them.
- Claude never sees or handles the keystore passwords. The owner runs `keytool` and `gh secret set`.
- Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.
- Without the secrets (fork PRs), builds still pass on the debug key.
- Navmaas PR title `ci: sign release APKs with the owner's key`; version `1.2.0+3` → `1.2.1+4` in `pubspec.yaml` and `appVersion` in `lib/features/backup/data/backup_service.dart`.
- Nourishly follows its own conventions: Conventional Commits drive its tag action, so `ci:` makes a patch release.

## Review Focus

- **Secrets missing (a fork PR):** the signing step must be skipped, not fail, and the APK still builds. Covered by the `if:` guard in Task 1/2 Step 1, and checked by the owner's first PR run before the secrets are set.
- **A key password with shell-special characters** (`$`, quotes, spaces): `key.properties` must hold it literally. The step writes it with `printf '%s'` from `env:`, never interpolated into the script text.
- **The keystore secret pasted with line breaks:** `base64 --decode` with `-i` ignores garbage. The cert-digest step then shows whether the key is the expected one.
- **Release job reusing the PR's artifact:** the Navmaas `release` job publishes the APK built by `check-and-build`, so signing happens there, not in `release`.
- **Owner's Mac:** `key.properties` uses an absolute `storeFile` path. Gradle resolves relative paths from `android/app/`, which is a common mistake.

---

### Task 0: Owner creates the key and the secrets (owner, on the Mac)

**Files:** none in git.

- [ ] **Step 1: Make the keystore** (answer the prompts; remember both passwords):

```sh
keytool -genkeypair -v -keystore ~/keyur-android.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias release
```

- [ ] **Step 2: Back up** `~/keyur-android.jks` and its passwords in two places, one off this Mac (e.g. a password manager and an encrypted USB drive).

- [ ] **Step 3: `key.properties` in each repo** (git-ignored), Navmaas at `android/key.properties` and Nourishly at `app/android/key.properties`:

```properties
storeFile=/Users/pkeyur18/keyur-android.jks
storePassword=<store password>
keyAlias=release
keyPassword=<key password>
```

- [ ] **Step 4: Secrets in both repos.** Each `gh secret set` prompts for the value, so nothing lands in shell history:

```sh
for repo in patel-keyur-18/pregnancy-care patel-keyur-18/nourishly; do
  base64 -i ~/keyur-android.jks | gh secret set ANDROID_KEYSTORE_BASE64 -R "$repo"
  gh secret set ANDROID_STORE_PASSWORD -R "$repo"
  gh secret set ANDROID_KEY_PASSWORD -R "$repo"
  echo -n release | gh secret set ANDROID_KEY_ALIAS -R "$repo"
done
gh secret list -R patel-keyur-18/pregnancy-care
```

Expected: four secrets listed per repo.

- [ ] **Step 5: Note the cert digest** to compare against CI's later:

```sh
keytool -list -v -keystore ~/keyur-android.jks -alias release | grep SHA256
```

### Task 1: Navmaas CI signs with the owner's key

**Files:**
- Modify: `.github/workflows/ci.yml` (header comment lines 1–3; before "Build release APK" ~line 70; after the size check ~line 79)
- Modify: `README.md` (Android install section ~lines 32–50)
- Modify: `docs/ARCHITECTURE.md` §16 (CI signing), §17 (new ADR), milestones/status version mention
- Modify: `docs/PLAN.md` (new decision row: one owner keystore for both apps; Release decision version)
- Modify: `CLAUDE.md` (APK build line: signed with the owner's key when `key.properties` exists)
- Modify: `pubspec.yaml` (`version: 1.2.1+4`), `lib/features/backup/data/backup_service.dart` (`appVersion = '1.2.1'`)

**Interfaces:**
- Consumes: the four secrets from Task 0.
- Produces: CI artifacts `navmaas-release-apk` signed with the owner's cert. The log line `Signer #1 certificate SHA-256 digest: …`.

- [ ] **Step 1: Add the signing step** before "Build release APK":

```yaml
      # Signs with the owner's key (one key for Navmaas and Nourishly, ADR 060)
      # when the secrets exist; without them (fork PRs) Gradle falls back to
      # the debug key.
      - name: Use the owner's signing key
        if: ${{ env.KEYSTORE != '' }}
        env:
          STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
        run: |
          echo "$KEYSTORE" | base64 --decode -i > "$RUNNER_TEMP/release.jks"
          {
            printf 'storeFile=%s\n' "$RUNNER_TEMP/release.jks"
            printf 'storePassword=%s\n' "$STORE_PASSWORD"
            printf 'keyAlias=%s\n' "$KEY_ALIAS"
            printf 'keyPassword=%s\n' "$KEY_PASSWORD"
          } > android/key.properties
```

`if:` can't read `secrets` directly, so expose `KEYSTORE` at job level under the `check-and-build` job:

```yaml
    env:
      KEYSTORE: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
```

- [ ] **Step 2: Print the cert digest** after the size check:

```yaml
      - name: Show the APK's signing certificate
        run: |
          "$ANDROID_HOME"/build-tools/$(ls "$ANDROID_HOME"/build-tools | sort -V | tail -1)/apksigner \
            verify --print-certs build/app/outputs/flutter-apk/app-release.apk | grep -E 'DN|SHA-256'
```

- [ ] **Step 3: Fix the header comment** (lines 1–3) to say release APKs are signed with the owner's key from repository secrets, and are debug-signed only when the secrets are absent.

- [ ] **Step 4: Docs in the same commit.**
  - README: the Android section uses one key for both apps (`~/keyur-android.jks`, alias `release`), the absolute `storeFile`, and the four secrets.
  - ARCHITECTURE §16: CI signing.
  - New ADR 060 "One owner keystore signs Navmaas and Nourishly": context (random CI debug keys, the 2026-10-10 digests in spec §4), decision, consequences (back up the key; `flutter run` can't install over a release build).
  - ADR 059's row: its "no extra secret" now points to ADR 060 for the signing secrets.
  - PLAN: a decision row and the Release decision's version.
  - CLAUDE.md: the APK command note.
  - Version bump in both places.

- [ ] **Step 5: Verify locally**

Run: `dart format --set-exit-if-changed . && flutter analyze && flutter test test/features/backup`
Expected: no changes, zero issues, tests pass (the version-match test included).

Run: `flutter build apk --release --target-platform android-arm,android-arm64 && ~/Library/Android/sdk/build-tools/36.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk | grep SHA-256`
Expected: the digest from Task 0 Step 5 (needs Task 0 Step 3 done).

- [ ] **Step 6: Commit, push, PR**

```bash
git switch -c ci/release-signing origin/main
git add .github/workflows/ci.yml README.md docs CLAUDE.md pubspec.yaml lib/features/backup/data/backup_service.dart
git commit -m "ci: sign release APKs with the owner's key"
git push -u origin ci/release-signing
gh pr create --title "ci: sign release APKs with the owner's key" --body "…"
```

Expected on the PR run: the "Show the APK's signing certificate" step prints the Task 0 digest. The owner compares it.

### Task 2: Nourishly signs with the same key

Work in `~/Documents/Professional/nourishly` on a branch from its `main`.

**Files:**
- Modify: `app/android/app/build.gradle.kts` (top imports; `signingConfigs`; `buildTypes.release`)
- Modify: `.github/workflows/release.yml` (before "Build release APK" ~line 106; comment lines 101–104)
- Modify: Nourishly docs that mention debug signing (`grep -rn "debug key\|debug keys" docs README.md`), and add its ADR per its own numbering

**Interfaces:**
- Consumes: the four secrets and `app/android/key.properties` from Task 0.
- Produces: Nourishly release APKs with the same cert digest as Navmaas.

- [ ] **Step 1: Gradle reads `key.properties`.** At the top of `build.gradle.kts`:

```kotlin
import java.io.FileInputStream
import java.util.Properties

// Release signing reads android/key.properties (git-ignored, never committed).
// One owner keystore signs Nourishly and Navmaas, so updates install in place
// and Navmaas may read the share file (signature permission).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}
```

Inside `android { }`, before `buildTypes`:

```kotlin
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }
```

And replace the release `signingConfig` lines:

```kotlin
        release {
            // The owner's key when key.properties exists, else the debug key.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
```

- [ ] **Step 2: Release workflow.** Add a job-level `env: KEYSTORE: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}` to the build job. Then, before "Build release APK", add the same step as Task 1 Step 1 with `app/android/key.properties` as the output path:

```yaml
      - name: Use the owner's signing key
        if: ${{ env.KEYSTORE != '' }}
        env:
          STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
        run: |
          echo "$KEYSTORE" | base64 --decode -i > "$RUNNER_TEMP/release.jks"
          {
            printf 'storeFile=%s\n' "$RUNNER_TEMP/release.jks"
            printf 'storePassword=%s\n' "$STORE_PASSWORD"
            printf 'keyAlias=%s\n' "$KEY_ALIAS"
            printf 'keyPassword=%s\n' "$KEY_PASSWORD"
          } > app/android/key.properties
```

Then add, after the build, the cert-digest step from Task 1 Step 2 with the path `app/build/app/outputs/flutter-apk/app-release.apk`. Replace the comment at lines 101–104 to match.

- [ ] **Step 3: Verify locally**

Run: `cd app && flutter analyze && flutter build apk --release && ~/Library/Android/sdk/build-tools/36.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk | grep SHA-256`
Expected: zero issues. Same digest as Navmaas's Task 1 Step 5.

- [ ] **Step 4: Commit, push, PR**

```bash
git switch -c ci/release-signing origin/main
git add app/android/app/build.gradle.kts .github/workflows/release.yml docs README.md
git commit -m "ci: sign release APKs with the owner's key"
git push -u origin ci/release-signing
gh pr create --title "ci: sign release APKs with the owner's key" --body "…"
```

Nourishly's release workflow runs only on `main`, so the digest is checked on the first release after merge. The owner compares it with Navmaas's.

### Task 3: After both merge (owner)

- [ ] Download both new release APKs and compare their digests:

```sh
apksigner verify --print-certs <apk> | grep SHA-256
```

Both must match Task 0 Step 5.

- [ ] Her Android has neither app yet, so install both from these releases. On the owner's test phones, uninstall any older build signed with another key once.
