# Whisper — local voice dictation for macOS

**Date:** 2026-06-12
**Status:** Approved

## Goal

A free, fully local alternative to superwhisper's core feature: hold a hotkey
anywhere on the Mac, speak, release — the words are transcribed on-device by
Whisper and inserted into whatever app has focus. No cloud, no subscription.

## Decisions

- **Scope (v1):** core dictation only. No AI cleanup modes, custom vocabulary,
  history, or file transcription. Architecture leaves room to add these later.
- **Stack:** native Swift + SwiftUI menu bar app.
- **Engine:** WhisperKit (Whisper on CoreML, optimized for Apple Silicon).
  Default model `large-v3_turbo` (~1.5 GB, downloaded once on first launch);
  smaller models selectable in settings.
- **Target machine:** Apple M3 Pro, 18 GB RAM, macOS 26.
- **Packaging:** SwiftPM executable assembled into a `.app` bundle by a build
  script, ad-hoc codesigned for personal use. `LSUIElement` so there is no
  Dock icon.

## Components

1. **Menu bar shell** — `MenuBarExtra` with status icon (idle / recording /
   transcribing / downloading), dropdown menu, settings window.
2. **Hotkey listener** — global `NSEvent` monitor. Default: hold **Right
   Option** to record, release to transcribe. Configurable; toggle mode
   supported.
3. **Audio recorder** — `AVAudioEngine`, converted to 16 kHz mono Float32
   (Whisper's input format). Publishes an audio level for the HUD.
4. **Transcriber** — WhisperKit wrapper: model download/load lifecycle,
   `transcribe(audioArray:)`, language setting.
5. **Recording HUD** — small floating non-activating `NSPanel`, bottom-center:
   live level meter while recording, then "transcribing…", then fades out.
6. **Text inserter** — saves clipboard, sets transcript, synthesizes ⌘V via
   `CGEvent`, restores previous clipboard contents after a short delay.
7. **Settings** — hotkey, model, language, launch at login (`SMAppService`).
8. **Permissions helper** — detects missing Microphone / Accessibility /
   Input Monitoring grants and deep-links to System Settings.

## Data flow

hotkey down → HUD appears + recording starts → hotkey up → samples to
WhisperKit → transcript → paste into focused app → HUD fades out.

## Error handling

- Empty/silent recording → HUD shows "didn't catch that", nothing pasted.
- Accessibility not granted → transcript left on clipboard + notification.
- Model download failure → retryable from the menu, error surfaced in HUD.
- Mic permission denied → menu shows warning, links to System Settings.

## Testing

- Unit tests for clipboard save/restore logic and audio sample conversion.
- Manual smoke test: build, launch, grant permissions, dictate into TextEdit.
