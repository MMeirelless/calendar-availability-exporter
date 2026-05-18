# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Bumped `matplotlib` minimum to `>=3.9` for NumPy 2.x compatibility. Older matplotlib builds fail with `_ARRAY_API not found` when NumPy 2 is present.

### Documentation
- README installation now leads with `python -m venv`. Added an Anaconda specific section and a troubleshooting note for the NumPy/matplotlib ABI mismatch.

## [0.1.0] - 2026-05-18

### Added
- Initial release.
- EventKit client with cross-version permission handling (`requestAccessToEntityType:completion:` and `requestFullAccessToEventsWithCompletion:`).
- `AnonymizedEvent` dataclass as the anonymization boundary: only `start`, `end`, `calendar`, `all_day` are exposed.
- matplotlib weekly grid renderer with Catppuccin Mocha palette.
- CLI flags for date window, day window, lunch overlay, calendar filter, and time label toggle.
- `python -m calendar_availability` module entry point.
- `calendar-availability` console script entry point.
- Generic legend labels (`Calendar 1`, `Calendar 2`, ...) so calendar names never leak into the output image.
- Makefile targets for install, lint, format, test, run, clean.
- Example launchd wrapper for weekly automation.

[Unreleased]: https://github.com/mb2analytics/calendar-availability-export/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mb2analytics/calendar-availability-export/releases/tag/v0.1.0
