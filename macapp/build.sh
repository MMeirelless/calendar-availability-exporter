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

# --- App icon -----------------------------------------------------------------
# Auto-generate AppIcon.icns from Resources/AppIcon.png (1024×1024). Drop in
# a replacement PNG at that path and rerun ./build.sh — nothing else needed.
ICON_SOURCE="$ROOT/Resources/AppIcon.png"
ICONSET_DIR="$ROOT/build/AppIcon.iconset"
ICNS_OUTPUT="$ROOT/build/AppIcon.icns"

if [[ -f "$ICON_SOURCE" ]]; then
    echo "Generating .icns from $(basename "$ICON_SOURCE")..."
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    for size in 16 32 128 256 512; do
        sips -z "$size" "$size" "$ICON_SOURCE" \
            --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
        sips -z "$((size * 2))" "$((size * 2))" "$ICON_SOURCE" \
            --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil --convert icns "$ICONSET_DIR" --output "$ICNS_OUTPUT"
else
    echo "Note: $ICON_SOURCE not found — building without an app icon."
fi

# --- Bundle -------------------------------------------------------------------
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$EXEC_PATH" "$APP_BUNDLE/Contents/MacOS/CalendarAvailability"
cp "$ROOT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [[ -f "$ICNS_OUTPUT" ]]; then
    cp "$ICNS_OUTPUT" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# --- Codesign (ad-hoc) --------------------------------------------------------
codesign --force --deep \
    --sign - \
    --entitlements "$ROOT/CalendarAvailability.entitlements" \
    "$APP_BUNDLE"

echo ""
echo "Built: $APP_BUNDLE"
echo "Run:   open \"$APP_BUNDLE\""
