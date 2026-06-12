#!/bin/bash
# Builds the SwiftPM executable and assembles a runnable Whisper.app bundle.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP=build/Whisper.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/Whisper "$APP/Contents/MacOS/Whisper"
cp Support/Info.plist "$APP/Contents/Info.plist"

# Ad-hoc signature: required for TCC (microphone/accessibility) to remember grants.
codesign --force --sign - "$APP"

echo "Built $APP"
echo "Run with: open $APP"
