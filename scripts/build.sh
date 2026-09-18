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
/usr/bin/codesign --force --sign - "$APP_DIR"
printf 'Built local app: %s\n' "$APP_DIR"
