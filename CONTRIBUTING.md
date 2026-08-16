# Contributing

Thanks for helping improve Whisper Dictation.

## Before opening an issue

- Search existing [issues](https://github.com/johnrue/whisper-dictation/issues).
- For setup or usage problems, check the README troubleshooting section first.
- Do not post credentials, private transcripts, system logs containing personal
  data, or unredacted crash reports in a public issue.

## Development

Requirements are an Apple Silicon Mac, macOS 14 or later, and Swift 5.9 or a
compatible Xcode toolchain.

```sh
git clone https://github.com/johnrue/whisper-dictation.git
cd whisper-dictation
swift package resolve
swift build
```

Before submitting a change, run:

```sh
swift test
swift build -c release
plutil -lint Support/Info.plist
git diff --check
```

The repository does not yet include an automated test target, so changes to
recording, permissions, hotkeys, or text insertion also need a manual dictation
smoke test. Describe what you tested and the macOS version in the pull request.

## Pull requests

Keep changes focused, explain user-visible behavior, update documentation when
needed, and avoid committing generated `.build`, `build`, or `dist` content.
By submitting a contribution, you agree that it is licensed under the project's
MIT License.

## Security issues

Do not disclose a suspected vulnerability in a public issue. Private
vulnerability reporting is not currently enabled, so secure reporting guidance
must be established by the maintainer before a public release.
