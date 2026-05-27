# Development Workflow

This document explains how code moves through the repository — from a fresh idea on a feature branch to a tagged release on `main`. If you only ever read one operations doc for this project, this is the one.

The high-level shape: **everyone works on short-lived feature branches off `dev`, `dev` is promoted into `test` to soak, and `test` is promoted into `main` to cut a release.**

```
feature/xyz ──▶ dev ──▶ test ──▶ main ──▶ tag vX.Y.Z ──▶ release
```

## The three long-lived branches

| Branch | Purpose | What lives here | Who pushes |
|--------|---------|-----------------|------------|
| `main` | **Production.** This is what users get when they clone the repo or download a prebuilt `.app`. | Only commits that have been promoted from `test`. Every commit on `main` should be tagged as a release. | Only via promotion PR from `test`. Never push directly. |
| `test` | **Preproduction / soak.** A release candidate lives here while you test the prebuilt `.app`, the CLI, and the install flow end-to-end. | Whatever was promoted from `dev` at the last release cut. | Only via promotion PR from `dev`. Never push directly. |
| `dev`  | **Integration.** Active line of development. Feature branches merge here. | The latest accepted work that has passed review. May break — that's what `test` is for. | Maintainer self-merges from feature branches, or merges contributor PRs. |

**Feature branches** (e.g. `feat/persisted-prefs`, `fix/timezone-rebase`, `docs/workflow`) are short-lived. They branch off `dev`, get a PR, get merged into `dev`, and are then deleted.

## Day-to-day: working on a feature

```bash
git switch dev
git pull
git switch -c feat/short-description
# ...edit, commit, push...
git push -u origin feat/short-description
```

Then open a pull request on GitHub targeting `dev`. Once it's merged:

```bash
git switch dev
git pull
git branch -d feat/short-description    # local cleanup
git push origin --delete feat/short-description   # remote cleanup (if you didn't use the GitHub "Delete branch" button after merging)
```

Naming convention for feature branches — pick a short prefix that hints at the kind of change:

- `feat/...` — new feature
- `fix/...` — bug fix
- `docs/...` — documentation only
- `chore/...` — tooling, CI, repo hygiene
- `refactor/...` — code restructuring with no behavior change

## Promoting `dev` → `test`

When `dev` accumulates enough features for the next release, promote it into `test` so the prebuilt `.app` can soak and you can verify the install flow end-to-end.

### Recommended path (via PR)

1. On GitHub, click **Pull requests → New pull request**.
2. Set **base: `test`** and **compare: `dev`**.
3. Title it `Promote dev → test for vX.Y.Z`. The body can just list the major user-visible changes since the last promotion.
4. Self-approve and merge once CI is green. Use **Create a merge commit** so the promotion event stays visible in `git log`.

### Quick path (direct fast-forward, solo only)

Skip the PR overhead when it's truly a one-person promotion:

```bash
git switch test
git pull
git merge --ff-only dev
git push
```

`--ff-only` will refuse the merge if `test` has diverged — that's a safety rail; if you see it fail, investigate before forcing anything.

After this step, **install and exercise the app from `test`**. The full smoke list:

- `cd macapp && ./build.sh && ./install.sh` succeeds.
- Launch the installed `.app`. Calendar permission flow works on a fresh user (or after revoking access in System Settings).
- Generate a chart for the current week. Copy to clipboard. Paste somewhere.
- Save as PNG. Open the saved file.
- Change a preference, quit, relaunch — preference survives.
- `pip install -e .` then `calendar-availability --start ... --end ...` produces a PNG.

If anything is broken, **fix it on a feature branch off `dev`**, merge to `dev`, then re-promote `dev → test`. Don't hotfix on `test`.

## Promoting `test` → `main` (cutting a release)

Once you're confident in `test`:

### Via PR

1. **Pull requests → New pull request**, base `main`, compare `test`.
2. Title: `Release vX.Y.Z`.
3. Body: paste the release notes — bullet list of user-visible changes, organized as "Added / Changed / Fixed / Removed".
4. Merge using **Create a merge commit** (keeps the release event visible).

### Direct fast-forward (solo only)

```bash
git switch main
git pull
git merge --ff-only test
git push
```

### Tag the release

Existing tags follow the `v0.0.X` pattern (see `git tag -l`). After `main` has the release commit:

```bash
git switch main
git pull
git tag -a v0.0.6 -m "Release v0.0.6"
git push origin v0.0.6
```

The `release-macapp.yml` workflow under `.github/workflows/` reacts to pushes that touch `macapp/`, so a tag push will trigger a fresh `.app` release on the GitHub Releases page.

If you adopt **semantic versioning** (recommended once 1.0 is reached): bump **major** for breaking changes, **minor** for new features that stay compatible, **patch** for bug fixes.

## Downloading a build per branch

The CI workflow (`.github/workflows/release-macapp.yml`) publishes a `.app` build for every push to `dev`, `test`, and `main` (when something under `macapp/` changes). Where it lands depends on the branch:

| Branch | Release behavior | Where to find it |
|--------|-----------------|------------------|
| `main` | Versioned release `v0.0.N` (N = workflow run number). Marked as **Latest**. Immutable. | [Releases page](https://github.com/MMeirelless/calendar-availability-exporter/releases) — top entry. |
| `test` | Rolling prerelease tagged `test-build`. **Always reflects the latest `test` commit** — the previous asset is replaced. | Releases page — look for *"Test build — test @ <sha>"*. |
| `dev`  | Rolling prerelease tagged `dev-build`. Always reflects the latest `dev` commit. | Releases page — look for *"Development build — dev @ <sha>"*. |

The rolling tags (`dev-build`, `test-build`) are *mutable on purpose* — they're channels, not versions. If you need a specific historical build of `dev` or `test`, the workflow run still has the artifacts available under the Actions tab for 90 days, and the commit SHA in the release body is the source of truth.

Only the `main` releases are immutable and counted as proper versions. **Don't link external docs to `dev-build` or `test-build` URLs** — only link to `v0.0.N` tags for anything you want to stay stable.

## Resetting `dev` after a release

Right after a release, `dev`, `test`, and `main` should all point at the same commit. New feature branches branch off `dev` as normal — no special reset step is needed if the promotion path used fast-forward merges. If you used merge commits, `dev` will already match `main` in content; just keep going.

## Hotfixes

If a critical bug is found in production and `dev` has unfinished work that can't go out:

1. Branch directly off `main`: `git switch main && git pull && git switch -c fix/critical-thing`.
2. Fix, commit, push, PR against `main`.
3. After it lands on `main`, tag a patch release and push the tag.
4. **Merge `main` back into `dev`** so the fix isn't accidentally reverted by the next promotion:
   ```bash
   git switch dev
   git pull
   git merge main
   git push
   ```

Hotfix branches should be the rare exception. Most fixes go through the normal `dev → test → main` flow.

## Branch protection (one-time setup)

Once branch protection is enabled in **Settings → Branches** (see the project's manual setup notes), direct pushes to `main` and `test` are blocked and the only way to get code there is via PR. That's intentional — it forces the promotion ritual.

For `dev`, branch protection is optional. Disallowing force-pushes and deletions is a reasonable minimum.

## Quick reference

| You want to… | Run |
|---|---|
| Start a new feature | `git switch dev && git pull && git switch -c feat/short-name` |
| Sync your feature branch with latest `dev` | `git switch dev && git pull && git switch - && git rebase dev` |
| Promote `dev` → `test` (solo, fast path) | `git switch test && git pull && git merge --ff-only dev && git push` |
| Promote `test` → `main` (solo, fast path) | `git switch main && git pull && git merge --ff-only test && git push` |
| Tag a release | `git tag -a vX.Y.Z -m "Release vX.Y.Z" && git push origin vX.Y.Z` |
| See what's on `dev` that isn't on `main` | `git log main..dev --oneline` |
| Roll a hotfix from `main` | `git switch main && git pull && git switch -c fix/...` |
