<!--
Thanks for sending a pull request.

Please target the `dev` branch unless this is a release-coordinated merge
(`dev` → `test` or `test` → `main`). See CONTRIBUTING.md for the flow.
-->

## Summary

<!-- One or two sentences. What changed and why? -->

## Motivation

<!-- Link to the issue this addresses, or describe the user-facing problem. -->

Closes #

## Changes

<!-- Bullet the user-visible / behavior-visible changes. -->

-

## Testing

<!-- How did you verify this? Mention test commands, manual reproductions, screenshots. -->

- [ ] `make lint` clean (Python changes)
- [ ] `make test` passes (Python changes)
- [ ] `swift build` succeeds in `macapp/` (Swift changes)
- [ ] Manually verified the user-facing behavior

## Screenshots

<!--
If this changes UI, attach before/after screenshots.
Reminder: use a dummy calendar — never paste real event content.
-->

## Anonymization boundary

<!--
This project's contract is that event titles, notes, locations,
attendees, URLs, and attachments are NEVER read into memory.
-->

- [ ] This PR does not widen the `AnonymizedEvent` model in Python or Swift.
- [ ] This PR does not add any code path that reads restricted event fields (titles, notes, attendees, locations, URLs, attachments).
- [ ] If either box above is unchecked, I have opened an issue first to discuss the boundary change.

## Checklist

- [ ] PR targets `dev` (or is an explicit release-promotion PR).
- [ ] Commit messages have short imperative subjects.
- [ ] I have read [CONTRIBUTING.md](../CONTRIBUTING.md) and agree to license my contribution under Apache 2.0.
