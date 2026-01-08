# CI/CD Documentation

This document covers the GitHub Actions CI/CD pipelines for Playcado.

## Overview

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [PR Checks](#pr-checks) | Pull request to `main` | Lint, analyze, test, verify builds |
| [Staging Build](#staging-build) | Push to `main` | Build staging artifacts |
| [Release Android](#release-android) | `v*` tag or manual | Build & upload to Google Play |
| [Release iOS](#release-ios) | `v*` tag or manual | Build & upload to TestFlight |

```
PR opened ──► PR Checks (lint + test + build verify)
                │
Merge to main ──► Staging Build (APK artifact, 14-day retention)
                │
Tag v1.0.0+15 ──► Release Android (Google Play)
               ──► Release iOS (TestFlight)
```

---

## Workflows

### PR Checks

**File:** `workflows/pr-checks.yml`

Runs on every pull request targeting `main`. Concurrent runs for the same branch are cancelled when a new push arrives.

**Jobs:**

1. **Analyze & Lint** — checks formatting (`dart format --set-exit-if-changed`) and runs `flutter analyze --fatal-infos`
2. **Test** — runs the full test suite with coverage and uploads results to Codecov
3. **Build Android** — builds a dev APK to verify compilation (runs after analyze + test pass)
4. **Build iOS** — builds iOS without codesigning to verify compilation (runs after analyze + test pass)

Build jobs use dummy secrets (`{"SENTRY_DSN":""}`) since they only verify compilation.

### Staging Build

**File:** `workflows/build-staging.yml`

Runs on every push to `main` (i.e., after a PR is merged). Also available via manual dispatch.

- Builds a staging APK (Android) and staging iOS binary (no codesign)
- Uploads the APK as a GitHub Actions artifact with 14-day retention
- Uses staging secrets for Sentry DSN configuration

### Release Android

**File:** `workflows/release-android.yml`

Triggered by pushing a `v*` tag (e.g., `v1.0.0+15`) or via manual dispatch.

**Manual dispatch options:**
- `track` — Google Play track to upload to: `internal` (default), `alpha`, `beta`, or `production`

**What it does:**
1. Sets up Java 17 and Flutter
2. Runs code generation
3. Decodes the signing keystore from secrets
4. Builds an obfuscated release App Bundle (`.aab`)
5. Uploads the AAB and debug symbols as GitHub Actions artifacts
6. Uploads the AAB to Google Play via the configured track

### Release iOS

**File:** `workflows/release-ios.yml`

Triggered by pushing a `v*` tag or via manual dispatch.

**Manual dispatch options:**
- `destination` — `testflight` (default) or `app-store`

**What it does:**
1. Sets up Flutter on a macOS runner
2. Runs code generation
3. Installs the Apple distribution certificate and provisioning profile into a temporary keychain
4. Builds an obfuscated release IPA using `ios/ExportOptions.plist`
5. Uploads the IPA and debug symbols as GitHub Actions artifacts
6. Uploads to TestFlight via `xcrun altool`
7. Cleans up the temporary keychain (runs even if the build fails)

---

## Secrets Configuration

All secrets must be configured in **GitHub → Repository → Settings → Secrets and variables → Actions**.

### Application Secrets

| Secret | Description | How to obtain |
|--------|-------------|---------------|
| `SECRETS_PROD_JSON` | Full contents of `config/secrets_prod.json` | Copy the file contents |
| `SECRETS_STAGING_JSON` | Full contents of `config/secrets_staging.json` | Copy the file contents |

### Android Signing

| Secret | Description | How to obtain |
|--------|-------------|---------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded upload keystore | `base64 -i upload-keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | From your keystore creation step |
| `ANDROID_KEY_PASSWORD` | Key password | From your keystore creation step |
| `ANDROID_KEY_ALIAS` | Key alias | From your keystore creation step |

### Android Distribution

| Secret | Description | How to obtain |
|--------|-------------|---------------|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Play API service account JSON | [Google Play Console → API access](https://play.google.com/console) → Create service account |

### iOS Signing

| Secret | Description | How to obtain |
|--------|-------------|---------------|
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64-encoded `.p12` distribution certificate | Export from Keychain Access, then `base64 -i certificate.p12 \| pbcopy` |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for the `.p12` file | Set during export from Keychain Access |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` file | Download from Apple Developer Portal, then `base64 -i profile.mobileprovision \| pbcopy` |

### iOS Distribution

| Secret | Description | How to obtain |
|--------|-------------|---------------|
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API key ID | [App Store Connect → Users and Access → Integrations → Keys](https://appstoreconnect.apple.com) |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID | Same page as above |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded `.p8` API key file | Download the `.p8` key, then `base64 -i AuthKey_XXXXXXXX.p8 \| pbcopy` |

### Optional

| Secret | Description |
|--------|-------------|
| `CODECOV_TOKEN` | Upload token from [codecov.io](https://codecov.io) for coverage reporting |

---

## Creating a Release

### 1. Bump the version

Update the version in `pubspec.yaml`:

```yaml
version: 1.0.1+16  # major.minor.patch+buildNumber
```

Commit the change:

```bash
git add pubspec.yaml
git commit -m "bump version to 1.0.1+16"
git push
```

### 2. Tag and push

```bash
git tag v1.0.1+16
git push origin v1.0.1+16
```

This triggers both `release-android` and `release-ios` workflows automatically.

### 3. Manual release (optional)

If you need to re-release or choose a specific track/destination:

1. Go to **Actions** in GitHub
2. Select the release workflow (Android or iOS)
3. Click **Run workflow**
4. Choose the track (Android) or destination (iOS)
5. Click **Run workflow**

### Promoting an Android release

To promote from internal testing to production:

1. Run the **Release Android** workflow manually
2. Select the `production` track
3. Or promote directly in the [Google Play Console](https://play.google.com/console)

---

## Troubleshooting

### PR checks failing on formatting

Run locally before pushing:

```bash
dart format .
```

### PR checks failing on analysis

Run locally:

```bash
flutter analyze --fatal-infos
```

### iOS build fails with codesigning errors

Verify your secrets are set correctly:

```bash
# Check certificate is valid
echo "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode > /tmp/cert.p12
openssl pkcs12 -in /tmp/cert.p12 -nokeys -passin pass:YOUR_PASSWORD
```

Ensure the provisioning profile matches the certificate and bundle ID (`com.playcado.app`).

### Android build fails with signing errors

Verify the keystore:

```bash
echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > /tmp/keystore.jks
keytool -list -v -keystore /tmp/keystore.jks -storepass YOUR_PASSWORD
```

Ensure the alias in `ANDROID_KEY_ALIAS` matches what's in the keystore.

### Code generation errors

If builds fail during `build_runner`, ensure your models are valid:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Workflow not triggering on tag push

Ensure the tag matches the `v*` pattern:

```bash
# Correct
git tag v1.0.0+15

# Will NOT trigger
git tag 1.0.0+15
git tag release-1.0.0
```
