# Contributing

Thanks for your interest in improving Calendar Availability Exporter. This document covers everything you need to file a useful issue, set up the project locally, and get a pull request merged.

## A note on the license

The project is published under the **Prosperity Public License 3.0.0**. Prosperity is a *source-available* / *non-commercial* license — it lets anyone read, modify, and share the source for personal, hobby, academic, or other noncommercial use forever, with a 30-day commercial trial. **It is not an OSI-approved open-source license**, because it restricts commercial use. That distinction matters to some people, so it is called out here up front.

If you contribute back, the license's "Contributions Back" clause asks that those changes be offered under a standard permissive license so they can be folded into the main project without ambiguity. **By submitting a pull request you agree that your contribution is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).** Apache 2.0 includes an explicit patent grant, which keeps the project safe to redistribute.

## How to report a bug or request a feature

- Search [existing issues](https://github.com/MMeirelless/calendar-availability-exporter/issues) and [Discussions](https://github.com/MMeirelless/calendar-availability-exporter/discussions) first.
- For **usage questions**, open a thread under **Discussions → Q&A**, not an issue.
- For **bug reports** and **feature requests**, use the structured forms on the *New issue* page.
- Found a security or privacy issue? See [SECURITY.md](SECURITY.md) — do **not** open a public issue.

When attaching screenshots, remember the project's whole point is that you never need to leak real calendar content. Please don't paste in screenshots of your real (un-anonymized) calendar.

## Development setup

### Python CLI

```bash
git clone https://github.com/MMeirelless/calendar-availability-exporter.git
cd calendar-availability-exporter
python3 -m venv .venv
source .venv/bin/activate
make install        # editable install + dev deps
```

Useful targets:

| Command       | What it does                              |
|---------------|-------------------------------------------|
| `make lint`   | `ruff check` on `src` and `tests`         |
| `make format` | `ruff format` then `ruff check --fix`     |
| `make test`   | `pytest`                                  |
| `make clean`  | Remove caches and build artifacts         |

### macOS app

```bash
cd macapp
swift build                     # debug build
./build.sh                      # produce a .app bundle
./install.sh                    # copy to /Applications, clear quarantine
```

Requires macOS 26 (Tahoe) and Swift 6 toolchain. There is no Swift test target yet — adding one is a welcome contribution.

## Branch flow

The repository uses three long-lived branches:

- **`main`** — production. Tagged releases are cut from here. Treated as protected; only release PRs from `test` should land here.
- **`test`** — preproduction / release candidate. `dev` is promoted into `test` when a release is being prepared, so it can soak.
- **`dev`** — active integration branch. **This is the default target for pull requests.**

Branch your feature off `dev`:

```bash
git switch dev
git pull
git switch -c feat/short-description
# ...commits...
git push -u origin feat/short-description
```

Then open a PR against `dev`.

## Pull request checklist

Before requesting a review, make sure:

- [ ] PR targets `dev` (not `main` or `test`).
- [ ] `make lint` is clean (Python changes).
- [ ] `make test` passes (Python changes).
- [ ] `swift build` succeeds in `macapp/` (Swift changes).
- [ ] The anonymization boundary is preserved — no PR should add code that reads event titles, notes, attendees, locations, URLs, or attachments. The `AnonymizedEvent` model in both Python (`src/calendar_availability/models.py`) and Swift (`macapp/Sources/CalendarAvailability/Models/AnonymizedEvent.swift`) is the contract; do not widen it without explicit discussion in an issue first.
- [ ] Commit messages use a short imperative subject; an optional body explains *why*, not what.
- [ ] You have read and agree to license your changes under Apache 2.0 (see top of this file).

## Code of conduct

This project follows the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md). Be kind. Disagreement is fine, contempt is not.

## Maintainer

Matheus Meirelles — [@MMeirelless](https://github.com/MMeirelless).
