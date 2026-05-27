# Security Policy

## The anonymization model

Calendar Availability Exporter is built so that there is **nothing sensitive to leak** in the first place. The `AnonymizedEvent` model — both the Python (`src/calendar_availability/models.py`) and Swift (`macapp/Sources/CalendarAvailability/Models/AnonymizedEvent.swift`) versions — exposes only four fields:

- `start`, `end` — when the event begins and ends
- `calendar` — the source calendar's display name (used only for grouping/filtering)
- `all_day` — whether to render as a top strip

Event titles, attendees, notes, locations, URLs, and attachments are **never read** from the underlying EventKit objects. They cannot end up in logs, debug output, swap, or the rendered PNG because they are never loaded.

If you find a code path that violates this boundary — including indirectly, e.g. through a logging call or a future feature — treat it as a **security issue** and report it privately using the channel below.

## Reporting a vulnerability

**Do not open a public GitHub issue for security problems.** Instead use one of:

1. **GitHub private vulnerability reporting** — go to the [Security tab](https://github.com/MMeirelless/calendar-availability-exporter/security) and click *Report a vulnerability*. This keeps the report private until a fix ships.
2. **Email** — [matheus.meirellessilva@hotmail.com](mailto:matheus.meirellessilva@hotmail.com) with the subject line `[security] calendar-availability-exporter`.

Please include:

- The affected component (Python CLI, macOS app, or shared model).
- A description of the issue and its impact.
- Steps to reproduce, or a minimal proof of concept.
- Any suggested mitigation if you have one.

You should expect an acknowledgement within a few days. Once a fix is ready, a coordinated disclosure will be published with credit to the reporter (unless you ask to remain anonymous).

## Supported versions

Only the **latest released version** receives security fixes. The project is small and pre-1.x-stable; please update to the newest release before reporting.

## Scope

In scope:

- The Python CLI (`src/calendar_availability/`).
- The macOS app (`macapp/`).
- Build scripts and CI workflows (`.github/workflows/`).

Out of scope:

- macOS, EventKit, or third-party calendar provider bugs — please report those upstream.
- Issues that require the attacker to already have full local access to your machine and Calendar.app data.
