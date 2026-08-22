# Changelog

Notable changes to Whisper Dictation are recorded here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and intends to use
[Semantic Versioning](https://semver.org/) once the initial public release
version is confirmed.

## [Unreleased]

### Added

- Local, on-device dictation powered by WhisperKit.
- Configurable hold or toggle hotkeys, language, and model selection.
- Menu-bar status, recording HUD, clipboard fallback, and launch-at-login.
- Source build, stable local signing, installation, and troubleshooting guides.

### Changed

- The recording HUD is now a Dynamic-Island-style overlay (via DynamicNotchKit)
  that expands from the notch on notched displays and floats as a pill on
  others, shown on the screen the mouse is on.
- The level meter is a live waveform: bar heights follow the mic level with a
  noise gate and speech-friendly response curve. While transcribing, the bars
  flatten and a shimmer sweeps across them instead of a spinner.
- Recording start and stop play subtle system sound cues (toggle in Settings).

### Fixed

- Dictation no longer transcribes silence hallucinations ("Thank you.") on
  macOS 26: the built-in mic now reports 3 channels, and AVAudioConverter's
  default multi-channel-to-mono downmix produces pure zeros. Capture now maps
  channel 0 explicitly. Each dictation also logs sample count, duration, RMS,
  and peak level (via NSLog) so silent-capture failures are diagnosable.
- Connecting or disconnecting an audio device (e.g. AirPods) no longer crashes
  or wedges the app. A fresh audio engine is built per recording, device
  changes mid-recording rebuild capture and keep the audio already recorded,
  and an unrecoverable mic loss ends the dictation gracefully.

### Known limitations

- Apple Silicon and macOS 14 or later are required.
- First launch downloads roughly 1.5 GB of model data and compiles it for the
  Neural Engine.
- Public binary distribution is not yet supported: local builds are self-signed
  or ad-hoc signed and are not notarized.
- Automated tests and CI are not yet configured.

[Unreleased]: https://github.com/johnrue/whisper-dictation/compare/HEAD...HEAD
