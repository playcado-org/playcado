# Release Process

## Releasing a new version

1. Push your code to `main` — CI runs automatically to verify it builds
2. Go to **https://github.com/playcado-org/playcado/actions/workflows/release-android.yml**
3. Click **Run workflow**
4. Select the track: `internal` → `alpha` → `beta` → `production`
5. Click **Run workflow**

The workflow builds a signed, obfuscated AAB, uploads it to Google Play at the chosen track, and creates a GitHub Release with the AAB attached.

## Promoting a release

To move a release from internal → alpha → beta → production:

1. Go to **Google Play Console** → Playcado → **Release** → **Internal**
2. Click **Promote release** → choose the next track
3. Or just run the release workflow again with the next track selected

## Notes

- Build number uses `github.run_number` — no manual version bumps needed
- `pubspec.yaml` version can stay as-is (CI overrides the build number)
- For iOS, use the Release iOS workflow with `testflight` or `app-store`
