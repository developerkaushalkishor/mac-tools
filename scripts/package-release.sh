#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/ScreenInk.app"
RELEASE_DIR="$PROJECT_DIR/dist/release"

/bin/bash "$PROJECT_DIR/scripts/build.sh"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_DIR"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_DIR/Contents/Info.plist")"
ARCHITECTURE="$(/usr/bin/uname -m)"
ARCHIVE_NAME="ScreenInk-${VERSION}-macOS-${ARCHITECTURE}.zip"

if [[ "${REQUIRE_DISTRIBUTION_SIGNATURE:-0}" == "1" ]]; then
    SIGNATURE_DETAILS="$(/usr/bin/codesign --display --verbose=4 "$APP_DIR" 2>&1)"
    if [[ "$SIGNATURE_DETAILS" != *"Authority=Developer ID Application:"* ]]; then
        printf '%s\n' 'Public packaging requires a Developer ID Application signature.' >&2
        printf '%s\n' 'Set SCREENINK_SIGNING_IDENTITY and rebuild with an installed Apple signing identity.' >&2
        exit 1
    fi
fi

/bin/rm -rf "$RELEASE_DIR"
/bin/mkdir -p "$RELEASE_DIR"

if [[ -n "${SCREENINK_NOTARY_PROFILE:-}" ]]; then
    UPLOAD_ARCHIVE="$RELEASE_DIR/ScreenInk-notarization-upload.zip"
    /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$UPLOAD_ARCHIVE"
    /usr/bin/xcrun notarytool submit "$UPLOAD_ARCHIVE" \
        --keychain-profile "$SCREENINK_NOTARY_PROFILE" --wait
    /usr/bin/xcrun stapler staple "$APP_DIR"
    /usr/bin/xcrun stapler validate "$APP_DIR"
    /bin/rm -f "$UPLOAD_ARCHIVE"
fi

ARCHIVE_PATH="$RELEASE_DIR/$ARCHIVE_NAME"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE_PATH"
(
    cd "$RELEASE_DIR"
    /usr/bin/shasum -a 256 "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
)

/usr/bin/unzip -tq "$ARCHIVE_PATH"
printf 'Packaged ScreenInk %s (%s) for %s:\n%s\n' \
    "$VERSION" "$BUILD" "$ARCHITECTURE" "$ARCHIVE_PATH"
printf 'Checksum: %s.sha256\n' "$ARCHIVE_PATH"
