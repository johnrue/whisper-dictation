# Whisper

Local voice dictation for macOS, in the style of superwhisper. Hold a hotkey
anywhere, speak, release — your words are transcribed on-device by
[WhisperKit](https://github.com/argmaxinc/WhisperKit) and pasted into whatever
app has focus. No cloud, no subscription. Personal-use project, not published.

## Requirements

- Apple Silicon Mac (arm64 only; uses the Neural Engine)
- macOS 14 or later
- Xcode (to build only — installing a built app needs nothing)
- ~2 GB disk for the default model

## Usage

- **Hold Right Option**, speak, release. The transcript is pasted at the cursor.
- A floating HUD at the bottom of the screen shows recording level, then
  "Transcribing…".
- The menu bar mic icon shows status; its dropdown has Settings (hotkey,
  hold/toggle behavior, language, model size, launch at login).
- If Accessibility isn't granted, the transcript is left on the clipboard
  instead of pasted, and the dropdown shows a grant shortcut.

## Build & install (on a dev machine)

```sh
./scripts/build-app.sh
```

This builds the SwiftPM executable, assembles the bundle with the icon,
ad-hoc signs it, and installs it to `/Applications/Whisper.app` (removing any
staging copy — two identical copies confuse the permission system).

First launch: grant **Microphone** and **Accessibility**, then wait for the
model — one-time ~1.5 GB download plus a few minutes of Neural Engine
compilation. Later launches are ready in seconds.

**After every rebuild you must re-grant Accessibility** (System Settings →
Privacy & Security → Accessibility → toggle Whisper off/on). Ad-hoc signatures
change per build and macOS ties the grant to the signature.

## Installing on another Mac (no Xcode needed)

1. On a machine that has the app, zip it:
   ```sh
   ditto -c -k --keepParent /Applications/Whisper.app ~/Desktop/Whisper.zip
   ```
2. Transfer the zip (AirDrop, iCloud, scp) and unzip into `/Applications`.
3. Clear quarantine — the app isn't notarized, so macOS blocks it otherwise:
   ```sh
   xattr -dr com.apple.quarantine /Applications/Whisper.app
   ```
4. Launch, grant Microphone + Accessibility, wait out the one-time model
   download/compile, and enable "Launch at login" in Settings.

Optional: copy `~/Documents/huggingface/models/argmaxinc/whisperkit-coreml`
to the same path on the target Mac first to skip the model download.

## Caveat: this folder syncs via Syncthing

This project lives in `~/Projects`, which is a Syncthing-shared folder — it is
already present on the Mac Mini (M4, Apple Silicon, supported). That makes the
transfer steps above unnecessary:

- A zip of the latest installed app is kept at `dist/Whisper.zip` and syncs
  automatically. On the target Mac, just unzip it into `/Applications` and
  launch — files arriving via Syncthing are **not** quarantined, so the
  `xattr` step isn't needed. Refresh the zip after a rebuild with:
  ```sh
  ditto -c -k --keepParent /Applications/Whisper.app dist/Whisper.zip
  ```
- The model cache (`~/Documents/huggingface/...`) is outside the synced
  folder, so each Mac still does its own one-time model download and compile.
- Permissions (Microphone/Accessibility) are per-machine; grant them on the
  Mini on first launch.
- Build artifacts should not sync between machines: `~/Projects/.stignore`
  ignores `/Whisper/.build` and `/Whisper/build` so Swift's incremental build
  state (hundreds of MB, machine-specific) stays local to each Mac.

## Troubleshooting

- **Stuck on "Transcribing…" / takes minutes:** first-run model compilation.
  One-time per model per machine.
- **Hotkey works but text only lands on the clipboard / dropdown still says
  "Grant Accessibility":** macOS doesn't consider *this exact copy* of the app
  trusted — usually after a rebuild. Reset and re-grant:
  ```sh
  tccutil reset Accessibility com.john.whisper
  open /Applications/Whisper.app
  ```
- **Logs:** status transitions are logged via NSLog; view with
  `log show --process Whisper --last 10m` or run the binary directly in a
  terminal to capture stdout.

## Project layout

- `Sources/Whisper/` — the app (hotkey monitor, recorder, WhisperKit wrapper,
  paste inserter, HUD, settings)
- `scripts/build-app.sh` — build + install
- `scripts/make-icon.sh` — regenerates `Support/AppIcon.icns`
- `docs/plans/` — design doc
