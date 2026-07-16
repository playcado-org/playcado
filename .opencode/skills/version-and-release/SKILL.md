---
name: version-and-release
description: Bumps version numbers, updates changelogs, creates branches, and manages pull requests for releases. Activates when the user asks to release, bump versions, or prepare a PR for a version change.
---

When the user asks to bump a version, prepare a release, or create a PR with version/changelog changes, follow this workflow. All inputs (version number, branch prefix, changelog entries) are determined automatically — never prompt the user.

## Workflow

### 1. Determine Branch State

Run `git branch --show-current`.

- If **main**: create a new branch (step 2)
- If **not main**: stay on the current branch, skip to step 3

### 2. Create a Branch (only if on main)

Auto-detect the branch prefix by examining commits since the last tag and any uncommitted changes:

```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
COMMITS=""
if [ -n "$LAST_TAG" ]; then
  COMMITS=$(git log "$LAST_TAG..HEAD" --oneline)
fi
```

- If any commits or uncommitted changes contain `feat(` or start with `feat:` or `feature:`, use `feat/`
- Else if any commits or uncommitted changes contain `fix(` or start with `fix:`, use `fix/`
- Else use `chore/`

Derive a short kebab-case description from the version bump context (e.g. `update-dependencies`, `fix-login-crash`). Use the most recent commit message or a summary of uncommitted changes.

```bash
git checkout -b <prefix>/<description>
git push -u origin <prefix>/<description>
```

### 3. Update Version

Find the project's version definition — look for `pubspec.yaml`, `package.json`, `Cargo.toml`, `VERSION`, `pyproject.toml`, etc. Read the current version and auto-determine the next version:

**Determine what's changed:**
```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -n "$LAST_TAG" ]; then
  HAS_NEW_COMMITS=$(git log "$LAST_TAG..HEAD" --oneline | head -1)
fi
```

- If there are new commits since the last tag, analyze conventional commit types:
  - Any `feat:` or `feat(` → **minor** bump
  - Any `fix:` or `fix(` → **patch** bump
  - `chore:`, `docs:`, `refactor:`, `test:`, `ci:` → **patch** bump
- If there are **no** new commits since the last tag, check for **uncommitted changes** (`git diff HEAD`). Analyze the diff to determine the nature of the change (new feature, bug fix, or other) and apply the same rules.
- If there are neither new commits nor uncommitted changes, abort with a message that there's nothing to release.

Apply the bump to the current version:
- **patch**: increment the patch segment (X.Y.Z → X.Y.(Z+1))
- **minor**: increment the minor segment and reset patch to 0 (X.Y.Z → X.(Y+1).0)

Update the version file with the new version.

### 4. Update Changelog

Find `CHANGELOG.md`. Insert a new entry at the top matching the existing format (typically `## [version]` with sections like `### Added`, `### Changed`, `### Fixed`).

**Derive changelog entries from:**
1. Conventional commits since the last tag — group by type:
   - `feat:` / `feature:` → `### Added`
   - `fix:` → `### Fixed`
   - `chore:`, `docs:`, `refactor:`, `test:`, `ci:`, `style:` → `### Changed`
2. If there are **no** new commits since the last tag, derive entries from uncommitted changes (`git diff HEAD`). Analyze the file paths and diff content to write descriptive entries. For each file changed, determine if it's an addition, fix, or change and place it in the appropriate section.
3. Strip conventional commit prefixes from the commit subject and capitalize the first letter for the changelog entry.

### 5. Commit

```bash
git add -A
git commit -m "chore: bump version to <new-version>"
git push
```

### 6. PR Management

Check whether a PR already exists for the branch:

```bash
gh pr list --head <branch-name> --json number,title,url --jq '.[0]'
```

- **If no PR exists**: create one with `gh pr create --title "<title>" --body "<body>" --fill`
- **If a PR exists**: update it with `gh pr edit <number> --title "<title>" --body "<body>"` and ensure the changelog and version are still correct

### 7. Report Back

Summarise to the user:
- New version
- Branch name (if created)
- PR number and URL (if created/updated)
