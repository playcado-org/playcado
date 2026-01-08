# CI/CD Workflows

Three workflows live in `.github/workflows/`.

---

## CI (`ci.yml`)

**Trigger:** Push to `main` or pull request to `main`  
**Concurrency:** Cancels in-progress runs for the same branch

A single job that runs everything sequentially:

```
format → analyze → build_runner → build Android → build iOS
```

**Skip a check:** Include `[skip ci]` in the commit message.

---

## Release Android (`release-android.yml`)

**Trigger:** Manual dispatch only

Go to **Actions → Release Android → Run workflow** and pick a track:

| Track | When to use |
|-------|------------|
| `internal` | First upload — verify the build signed and uploaded correctly |
| `alpha` | Share with trusted testers |
| `beta` | Wider testing |
| `production` | Public release |

**What it does:**
1. Builds a signed, obfuscated release AAB
2. Uploads to Google Play at the chosen track
3. Creates a GitHub Release with the AAB attached

**Build number:** Uses `github.run_number` (auto-incrementing).

---

## Release iOS (`release-ios.yml`)

**Trigger:** Manual dispatch only

Same pattern as Android. Pick `testflight` or `app-store`.

---

## Secrets

All secrets are stored in **GitHub → playcado-org/playcado → Settings → Secrets and variables → Actions**.

| Secret | Used by | How to obtain |
|--------|---------|---------------|
| `SECRETS_JSON` | Release workflows | Copy contents of `config/secrets.json` |
| `ANDROID_KEYSTORE_BASE64` | Release Android | `base64 upload-keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | Release Android | From keystore creation |
| `ANDROID_KEY_PASSWORD` | Release Android | From keystore creation |
| `ANDROID_KEY_ALIAS` | Release Android | From keystore creation |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Release Android | Play Console service account |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Release iOS | `base64 certificate.p12 \| pbcopy` |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Release iOS | Set during export |
| `IOS_PROVISIONING_PROFILE_BASE64` | Release iOS | `base64 profile.mobileprovision \| pbcopy` |
| `APP_STORE_CONNECT_API_KEY_ID` | Release iOS | App Store Connect → Integrations |
| `APP_STORE_CONNECT_ISSUER_ID` | Release iOS | Same page as above |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Release iOS | `base64 AuthKey.p8 \| pbcopy` |

---

## Troubleshooting

### Formatting or analysis fails

```bash
dart format .
flutter analyze --fatal-infos
```

### Android build fails with signing errors

Verify the keystore:
```bash
echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > /tmp/keystore.jks
keytool -list -v -keystore /tmp/keystore.jks -storepass YOUR_PASSWORD
```

Ensure the alias in `ANDROID_KEY_ALIAS` matches what's in the keystore.

### iOS build fails with codesigning errors

```bash
echo "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode > /tmp/cert.p12
openssl pkcs12 -in /tmp/cert.p12 -nokeys -passin pass:YOUR_PASSWORD
```

Ensure the provisioning profile matches the certificate and bundle ID (`com.playcado.app`).

### Code generation errors

```bash
dart run build_runner build --delete-conflicting-outputs
```
