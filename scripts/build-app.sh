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

# Sign with the stable self-signed identity if it exists (run
# scripts/make-signing-cert.sh once to create it). A stable identity is what
# lets TCC keep the Accessibility/Microphone grants across rebuilds; ad-hoc
# signing changes identity every build and silently drops the grants.
SIGN_IDENTITY="Whisper Local Signing"
if security find-identity -p codesigning | grep -q "$SIGN_IDENTITY"; then
    codesign --force --sign "$SIGN_IDENTITY" "$APP"
    echo "Signed with '$SIGN_IDENTITY'."
else
    codesign --force --sign - "$APP"
    echo "WARNING: signed ad-hoc — Accessibility grant will be lost on each rebuild."
    echo "         Run scripts/make-signing-cert.sh once for a stable identity."
fi

# Install to /Applications and remove the staging copy: two identical-looking
# copies confuse the Accessibility permission list (the grant attaches to one
# copy and silently doesn't apply to the other).
rm -rf /Applications/Whisper.app
ditto "$APP" /Applications/Whisper.app
rm -rf "$APP"

echo "Installed /Applications/Whisper.app"
echo "Note: rebuilding changes the app's signature; macOS may require re-granting Accessibility."
