# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added — Mac app
- Differentiate events by `EKEventAvailability` class (busy / tentative / free / unavailable). Each class has its own color **and** texture so the rendered PNG is unambiguous even in greyscale or for colorblind viewers: Busy is solid pink, Tentative is yellow with diagonal stripes, Free is a green dashed outline with faded fill, Unavailable is mauve with cross-hatching. The bottom-right legend renders each visible class with the same fill + texture so it acts as a faithful key.
- New "Event Types" section in the sidebar with a toggle per availability class. By default Busy, Tentative, and Unavailable are shown; Free is hidden so events explicitly marked Free in Calendar.app don't bleed into the "blocked time" screenshot.
- `AnonymizedEvent` gains an `availability: EventAvailability` field. `EKEventAvailability.notSupported` (e.g. some Google Calendar accounts) is treated as `.busy`, matching how Calendar.app blocks the slot.

## [1.0.0] - 2026-05-18

### Added — Native Mac app (`macapp/`)
- Native SwiftUI Mac app with Liquid Glass UI targeting macOS 26 (Tahoe).
- EventKit access in Swift, preserving the same anonymization boundary as the Python CLI (only `start`, `end`, `calendar`, `isAllDay` are read).
- Live Canvas-based weekly chart that matches the Python renderer.
- Timezone picker (Common + All) with the selected timezone shown as a subtitle on the chart. Defaults to `TimeZone.current`. Switching timezone re-anchors the visible ISO week so the same Mon–Sun stays in view.
- "Include weekends" toggle — when off, only Mon–Fri are rendered and the five columns widen.
- Single `Theme.occupied` color for all events (matches the lunch band), with a "Filled = Unavailable" legend explaining the semantic.
- "Generate & Copy" (⌘↩) renders at 3600×2200 and copies PNG + TIFF to the clipboard for paste-anywhere workflows.
- "Save as PNG…" (⌘S) opens a save panel and also copies to the clipboard.
- `build.sh` produces an ad-hoc-signed `.app` bundle from Swift Package Manager output, with a macOS-26-SDK preflight check.
- `install.sh` copies the built bundle into `/Applications` (quits any running instance, strips quarantine) so the app is discoverable via Finder, Spotlight, and Launchpad.
- App icon pipeline: drop a 1024×1024 PNG at `macapp/Resources/AppIcon.png` and `build.sh` auto-generates `AppIcon.icns` via `sips` + `iconutil`. A neutral placeholder is checked in.
- GitHub Actions workflow that builds, packages, and publishes a GitHub Release on every push to `main` that touches `macapp/`. Releases attach a `.zip` of the `.app`, tagged `v0.0.<run_number>`.

### Changed
- Bumped `matplotlib` minimum to `>=3.9` for NumPy 2.x compatibility. Older builds fail with `_ARRAY_API not found` when NumPy 2 is present.
- Project status moved to *Production/Stable*.

### Documentation
- Root README rewritten to introduce both the Mac app and the Python CLI side by side.
- README installation now leads with `python -m venv`. Added an Anaconda-specific section and a troubleshooting note for the NumPy / matplotlib ABI mismatch.
- Fixed stale GitHub URLs to point at `MMeirelless/calendar-availability-exporter`.

## [0.1.0] - 2026-05-18

### Added
- Initial release of the Python CLI.
- EventKit client with cross-version permission handling (`requestAccessToEntityType:completion:` and `requestFullAccessToEventsWithCompletion:`).
- `AnonymizedEvent` dataclass as the anonymization boundary: only `start`, `end`, `calendar`, `all_day` are exposed.
- matplotlib weekly grid renderer with Catppuccin Mocha palette.
- CLI flags for date window, day window, lunch overlay, calendar filter, and time label toggle.
- `python -m calendar_availability` module entry point.
- `calendar-availability` console script entry point.
- Generic legend labels (`Calendar 1`, `Calendar 2`, …) so calendar names never leak into the output image.
- Makefile targets for install, lint, format, test, run, clean.
- Example launchd wrapper for weekly automation.

[Unreleased]: https://github.com/MMeirelless/calendar-availability-exporter/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/MMeirelless/calendar-availability-exporter/releases/tag/v1.0.0
[0.1.0]: https://github.com/MMeirelless/calendar-availability-exporter/releases/tag/v0.1.0
