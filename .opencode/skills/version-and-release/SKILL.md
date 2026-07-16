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

Auto-detect the branch prefix by analyzing **all changes** compared to `main` — both committed (on the current branch since diverging from main) and uncommitted (staged and unstaged):

```bash
git diff main...HEAD --stat
git diff main...HEAD
git diff HEAD --stat
git diff HEAD
git status --short
```

Analyze the diff paths and content to determine the nature of the change and pick the most appropriate prefix:
  - `feat/` — new features, new files, new functionality (not just config/docs)
  - `fix/` — bug fixes, error handling, edge cases
  - `refactor/` — restructuring code without changing behavior
  - `docs/` — documentation-only changes
  - `test/` — test additions or modifications
  - `ci/` — CI/CD, build system, or tooling changes
  - `chore/` — fallback for everything else (config, deps, formatting, etc.)

If there are no changes at all (no diff against main and no uncommitted changes), default to `chore/`.

Derive a short kebab-case description that captures the **full scope** of all changes (compared to main — both committed and uncommitted). Run the same commands as above to see everything that changed. Pick a description broad enough to encompass all modifications — not just the most obvious one. For example, if changes include removing a directory from gitignore, renaming a file, and updating a config reference, a description like `track-opencode-config` captures all of them better than `rename-skill`.

```bash
git checkout -b <prefix>/<description>
git push -u origin <prefix>/<description>
```

### 3. Update Version

Read the current version from `pubspec.yaml` (format: `version: X.Y.Z`) and auto-determine the next version:

**Determine what's changed:**
```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -n "$LAST_TAG" ]; then
  git diff "$LAST_TAG" HEAD --stat
fi
```

```bash
git diff HEAD --stat
```

- If there are changes (committed since last tag, uncommitted, or both) that have not yet been released (i.e., no changelog entry exists for the next version), analyze the combined diff to determine the bump and add a new changelog entry.
- If the changes have already been documented in the changelog (i.e., a changelog entry already exists for the next version), do NOT bump the version again. Instead, update the existing changelog entry to reflect any new uncommitted changes.
- If there are no changes at all, abort with a message that there's nothing to release.

Apply the bump to `pubspec.yaml`:
- **patch**: increment the patch segment (`version: X.Y.Z` → `version: X.Y.(Z+1)`)
- **minor**: increment the minor segment and reset patch to 0 (`version: X.Y.Z` → `version: X.(Y+1).0`)

Update `pubspec.yaml` with the new version string.

### 4. Update Changelog

Find `CHANGELOG.md`. Insert a new entry at the top matching the existing format (typically `## [version]` with sections like `### Added`, `### Changed`, `### Fixed`).

**Derive changelog entries from:**
1. If there are new commits since the last tag, analyze the diff of all committed changes (`git diff <last-tag> HEAD`). Also check for uncommitted changes (`git diff HEAD`). Analyze the file paths and diff content to write descriptive entries. For each file changed, determine if it's an addition, fix, or change and place it in the appropriate section (`### Added`, `### Fixed`, `### Changed`).
2. If there are **no** new commits since the last tag, derive entries from uncommitted changes (`git diff HEAD`). Analyze the file paths and diff content to write descriptive entries.
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

- **If no PR exists**: create one with `gh pr create --title "<prefix>: <description>" --body "<body>" --fill`
- **If a PR exists**: update it with `gh pr edit <number> --title "<prefix>: <description>" --body "<body>"` and ensure the changelog and version are still correct

Where `<prefix>` matches the branch prefix (`feat` / `fix` / `chore` without the trailing `/`) and `<description>` is a short sentence summary (same as the branch description but with spaces instead of hyphens, no trailing period, not title-cased). For example: branch `chore/track-opencode-config` → PR title `chore: track opencode config`.

### 7. Report Back

Summarise to the user:
- New version
- Branch name (if created)
- PR number and URL (if created/updated)
