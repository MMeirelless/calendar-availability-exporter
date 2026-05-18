#!/usr/bin/env bash
# Build the CalendarAvailability.app bundle.
#
# Requires Xcode 26 (for the macOS 26 SDK that ships Liquid Glass APIs).
# After installing Xcode 26, run:
#   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
# then re-run this script.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Calendar Availability"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"

# --- Preflight: macOS 26 SDK present? -----------------------------------------
SDK_VER="$(xcrun --show-sdk-version 2>/dev/null || echo unknown)"
if [[ ! "$SDK_VER" =~ ^26 ]]; then
    cat >&2 <<EOF
ERROR: macOS 26 SDK not found (xcrun reports SDK $SDK_VER).

Liquid Glass requires Xcode 26 with the macOS 26 SDK. Install Xcode 26
from the App Store, then point xcode-select at it:

  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

Then re-run: ./build.sh
EOF
    exit 1
fi

# --- Build --------------------------------------------------------------------
cd "$ROOT"
echo "Building with SDK $SDK_VER..."
swift build -c release

EXEC_PATH="$(swift build -c release --show-bin-path)/CalendarAvailability"

# --- Bundle -------------------------------------------------------------------
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$EXEC_PATH" "$APP_BUNDLE/Contents/MacOS/CalendarAvailability"
cp "$ROOT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# --- Codesign (ad-hoc) --------------------------------------------------------
codesign --force --deep \
    --sign - \
    --entitlements "$ROOT/CalendarAvailability.entitlements" \
    "$APP_BUNDLE"

echo ""
echo "Built: $APP_BUNDLE"
echo "Run:   open \"$APP_BUNDLE\""
