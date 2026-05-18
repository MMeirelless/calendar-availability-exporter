#!/usr/bin/env bash
# Install or update the locally built Calendar Availability.app into
# /Applications so it's discoverable via Finder, Spotlight, and Launchpad.
#
# Run this after ./build.sh whenever you want to refresh your daily-use
# install. The Mac App Store / Gatekeeper grant is per-signature, so an
# ad-hoc rebuild may prompt for Calendar permission again on next launch.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Calendar Availability"
SOURCE="$ROOT/build/${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

if [[ ! -d "$SOURCE" ]]; then
    echo "ERROR: $SOURCE not found. Build first with: ./build.sh" >&2
    exit 1
fi

# Quit any running instance so we can replace the bundle cleanly.
osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true
sleep 0.5

# Atomic replace: remove old bundle, ditto preserves bundle structure /
# executables / extended attributes / symlinks correctly.
if [[ -e "$DEST" ]]; then
    rm -rf "$DEST"
fi
/usr/bin/ditto "$SOURCE" "$DEST"

# Strip any quarantine attribute (none should be present for a local copy,
# but defensive in case the source was downloaded).
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo ""
echo "Installed: $DEST"
echo "Open with: open \"$DEST\" — or find it in Finder / Spotlight / Launchpad."
