# Whisper Dictation

Local voice dictation for macOS, in the style of superwhisper. Hold a hotkey
anywhere, speak, release — your words are transcribed on-device by
[WhisperKit](https://github.com/argmaxinc/WhisperKit) and pasted into whatever
app has focus. No cloud, no account, no subscription. Everything stays on your
Mac.

## Requirements

- Apple Silicon Mac (arm64 only; uses the Neural Engine)
- macOS 14 or later
- Xcode or the Swift toolchain (to build from source)
- ~2 GB disk for the default model

## Usage

- **Hold Right Option**, speak, release. The transcript is pasted at the cursor.
- A floating HUD at the bottom of the screen shows recording level, then
  "Transcribing…".
- The menu bar mic icon shows status; its dropdown has Settings (hotkey,
  hold/toggle behavior, language, model size, launch at login).
- If Accessibility isn't granted, the transcript is left on the clipboard
  instead of pasted, and the dropdown shows a grant shortcut.

## Build & install

Clone the repo, then run the build script:

```sh
git clone https://github.com/johnrue/whisper-dictation.git
cd whisper-dictation
./scripts/make-signing-cert.sh   # one time — see "Code signing" below
./scripts/build-app.sh
```

`build-app.sh` builds the SwiftPM executable, assembles `Whisper.app` with the
icon, code-signs it, and installs it to `/Applications/Whisper.app`.

First launch: grant **Microphone** and **Accessibility**, then wait for the
model — a one-time ~1.5 GB download plus a few minutes of Neural Engine
compilation. Later launches are ready in seconds.

### Code signing (why the cert step matters)

macOS ties Accessibility and Microphone grants to the app's code-signing
identity. Ad-hoc signing (`codesign --sign -`) produces a **new identity on
every rebuild**, so every rebuild silently drops your grants and the app falls
back to copying to the clipboard instead of pasting.

`scripts/make-signing-cert.sh` creates a stable, self-signed code-signing
identity ("Whisper Local Signing") in your login keychain once, and
`build-app.sh` signs every build with it — so your permission grants survive
rebuilds. Run it a single time before your first build.

> The first build after creating the cert may show a one-time *"codesign wants
> to use a key in your keychain"* prompt — click **Always Allow**. If you skip
> the cert script entirely, the build still works (ad-hoc), but you'll re-grant
> Accessibility after every rebuild.

## Installing on another Mac (no build tools needed)

1. On a machine that has the app built, zip it:
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

Note: a zip transferred this way is signed with the *source* machine's identity,
which the target Mac doesn't trust — so on the target you'll grant Accessibility
once and it sticks. Building from source on each Mac is the more robust path.

Optional: copy `~/Documents/huggingface/models/argmaxinc/whisperkit-coreml` to
the same path on the target Mac first to skip the model download.

## Troubleshooting

- **Stuck on "Transcribing…" / takes minutes on first use:** first-run model
  compilation. One-time per model per machine.
- **Hotkey works but text only lands on the clipboard / dropdown still says
  "Grant Accessibility":** macOS doesn't consider *this exact copy* of the app
  trusted — usually after a rebuild with ad-hoc signing. Set up the signing cert
  (above), or reset and re-grant:
  ```sh
  tccutil reset Accessibility com.john.whisper
  open /Applications/Whisper.app
  ```
- **Every dictation comes out as "Thank you." / "you" / other short
  hallucinations:** Whisper is receiving silence. Check the per-dictation
  audio log line (`audio: N samples ... rms=... peak=...`); a peak of 0.00000
  means capture is broken, not the model. Known cause: a macOS update changing
  the built-in mic's channel count (macOS 26 made it 3-channel, which turned
  AVAudioConverter's default downmix into pure zeros — fixed by mapping
  channel 0 explicitly). Real speech shows peak ≥ ~0.1.
- **Hotkey stops responding after the Mac sleeps or sits idle:** the app holds a
  process-activity assertion to avoid App Nap and re-installs its global hotkey
  monitor on wake. If you still hit this, check the logs for a `wake:` line:
  ```sh
  log show --predicate 'process == "Whisper" AND eventMessage CONTAINS "wake:"' --last 1h
  ```
- **Logs:** status transitions are logged via NSLog; view with
  `log show --process Whisper --last 10m` or run the binary directly in a
  terminal to capture stdout.

## How it works

- **Global hotkey** — an `NSEvent` global monitor watches the configured
  modifier key (Accessibility-gated), re-installed on system wake.
- **Capture** — `AVAudioEngine` records the mic and resamples to 16 kHz mono
  Float32, the format Whisper expects.
- **Transcribe** — WhisperKit runs the model on the Neural Engine; the model is
  loaded and prewarmed at startup so the first dictation is fast.
- **Insert** — the transcript is placed on the clipboard and ⌘V is synthesized
  into the focused app (falling back to clipboard-only without Accessibility).

## Project layout

- `Sources/Whisper/` — the app (hotkey monitor, recorder, WhisperKit wrapper,
  paste inserter, HUD, settings, sleep/wake recovery)
- `scripts/make-signing-cert.sh` — creates the stable signing identity (run once)
- `scripts/build-app.sh` — build + sign + install
- `scripts/make-icon.sh` — regenerates `Support/AppIcon.icns`
- `docs/plans/` — design doc

## Support and contributing

Use [GitHub Issues](https://github.com/johnrue/whisper-dictation/issues) for
questions, reproducible bugs, and feature requests. Search existing issues and
review the troubleshooting section before opening a new one. Never include
private transcripts, credentials, or unredacted personal data in a public issue.

Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md) for the build,
verification, and pull-request expectations. Security reports must not be filed
publicly; private reporting guidance is still a release blocker and is tracked
in [RELEASE_STATUS.md](RELEASE_STATUS.md).

## License

[MIT](LICENSE) © John Rue. Built on
[WhisperKit](https://github.com/argmaxinc/WhisperKit) (MIT) and other
open-source dependencies listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The build script includes the
project license and third-party notices in the assembled app bundle.
