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
cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature: required for TCC (microphone/accessibility) to remember grants.
codesign --force --sign - "$APP"

# Install to /Applications and remove the staging copy: two identical-looking
# copies confuse the Accessibility permission list (the grant attaches to one
# copy and silently doesn't apply to the other).
rm -rf /Applications/Whisper.app
ditto "$APP" /Applications/Whisper.app
rm -rf "$APP"

echo "Installed /Applications/Whisper.app"
echo "Note: rebuilding changes the app's signature; macOS may require re-granting Accessibility."
