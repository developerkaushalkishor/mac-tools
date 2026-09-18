#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_DIR/scripts/environment.sh"
sw_vers
printf "Project developer directory: %s\n" "${DEVELOPER_DIR:-system default}"
xcode-select -p
swift --version
xcrun --show-sdk-path
if [ -d /Applications/Xcode.app ]; then
    printf 'Full Xcode found. You can open Package.swift in Xcode.\n'
else
    printf 'Full Xcode not found at /Applications/Xcode.app. Command Line Tools can build this starter.\n'
fi
