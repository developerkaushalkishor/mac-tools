#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_DIR/scripts/environment.sh"
cd "$PROJECT_DIR"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$PROJECT_DIR/dist/ScreenInk.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/ScreenInk" "$APP_DIR/Contents/MacOS/ScreenInk"
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"
SIGNING_IDENTITY="${SCREENINK_SIGNING_IDENTITY:--}"
/usr/bin/codesign --force --sign "$SIGNING_IDENTITY" "$APP_DIR"
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    printf '%s\n' 'Note: this build is ad-hoc signed. macOS may ask for Screen Recording permission again after the app binary changes.'
fi
printf 'Built local app: %s\n' "$APP_DIR"
