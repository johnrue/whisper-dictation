# Release status

Last inventory: 2026-08-15 13:30 CDT at `e108fcb6203e83dcd967c80bf33451fa8798d0e1`.

This is the release checklist and evidence log. Update the status and evidence column when a check is run. Do not tag, publish, or upload from a checklist run unless a separate release task explicitly authorizes it.

Status meanings:

- **PASS** — verified by the evidence shown.
- **PENDING** — applicable, but not yet run or reviewed for this release candidate.
- **BLOCKED** — a missing requirement or owner decision prevents a releasable result.
- **N/A** — deliberately not applicable, with a reason recorded.

## Disposition: PAUSED

**Whisper is paused for public release as of 2026-08-15. The next release review is scheduled for Monday, 2026-08-31.** This is not a release-ready candidate: no release tag was created, no artifact was approved or published, and there is no release URL. The declared `1.0.0` / `1` metadata remains a proposal rather than an approved release version. The ignored `dist/Whisper.zip` is validation output only and must not be uploaded.

The release remains paused until the following blockers have explicit dispositions:

| Blocker | Owner | Required disposition for the 2026-08-31 review |
|---|---|---|
| Version/build policy, first release version, and versioned release notes | Project owner (John) | Approve the version/build policy and release number; then date the changelog entry and record candidate artifact/checksum details. |
| Distribution, signing, and publication | Project owner (John) | Choose source-only distribution or an approved Developer ID/notarization path; name the publication destination, artifact naming/checksum convention, and final approver. |
| Automated tests | Project owner (John) for policy; implementation owner unassigned | Require and implement a test target, or record an explicit manual-only exception. Current `swift test` fails because no tests exist. |
| CI and lint/static-analysis gates | Project owner (John) for policy; implementation owner unassigned | Define and implement the gates, or explicitly approve the recorded compiler and shell-syntax checks as the release gate. |
| Public binary acceptance | Project owner (John) for signing decision; implementation owner unassigned | If a binary will be public, produce Developer ID-signed/notarized candidate evidence. The current self-signed app fails Gatekeeper and has no notarization ticket. |
| Private vulnerability reporting | Project owner (John) | Enable GitHub private vulnerability reporting or document another private maintainer channel. |
| Personal commit-email exposure | Project owner (John) | Accept the published Gmail metadata explicitly, or approve a GitHub-noreply history-cleanup plan before tagging. |
| Manual smoke and compatibility coverage | Project owner (John) or a named tester | Run every Manual smoke check below against one immutable candidate, including the oldest available supported macOS, and record results. No candidate smoke evidence exists yet. |
| Immutable-candidate rerun and final approval | Release approver unassigned | After the preceding decisions and changes, commit the release-preparation files, rerun all technical/public-readiness checks on that exact SHA, record evidence, and explicitly authorize tagging/publication. |

At the scheduled review, update this section to either (a) a release-ready/released record containing the approved version, tag, immutable SHA, artifact name and checksum, publication status/URL, and verification commands, or (b) a renewed pause with updated blockers, owners, and another concrete calendar date. Every current `BLOCKED` or `PENDING` checklist row is represented in the table above; none is deferred implicitly.

## Current release shape

- Product: Whisper Dictation, an arm64 macOS 14+ menu-bar app.
- Bundle identifier: `com.john.whisper`.
- Declared version/build: `1.0.0` / `1` in `Support/Info.plist`.
- Build system: SwiftPM; release executable is assembled into `Whisper.app` by `scripts/build-app.sh`.
- Repository: public `https://github.com/johnrue/whisper-dictation`, default branch `main`.
- Distribution documented today: build from source, or manually transfer a zip. The transferred app is self-signed or ad-hoc signed and is not notarized.
- Intended hosted binary destination is not documented. GitHub Releases is plausible, but must not be assumed.

## Inventory snapshot

| Area | Status | Current evidence | Verification / evidence required |
|---|---|---|---|
| Main branch baseline | PASS | `main` and `origin/main` both pointed to `e108fcb` during inventory; tree was clean before this file was added. | `git fetch origin && git status --short --branch && test "$(git branch --show-current)" = main && test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"` |
| Public repository | PASS | `gh repo view` reported `johnrue/whisper-dictation`, `PUBLIC`, default branch `main`, MIT. | `gh repo view johnrue/whisper-dictation --json nameWithOwner,url,visibility,defaultBranchRef,licenseInfo` |
| Release version | BLOCKED | `Support/Info.plist` contains marketing version `1.0.0` and build `1`; no versioning or bump policy is documented and there are no tags. | Owner must confirm the first release version and policy (for example, SemVer plus monotonically increasing bundle builds). Then verify with `/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist`, `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Support/Info.plist`, and `git tag --list` (read-only in checklist tasks). |
| Release notes / changelog | BLOCKED | `CHANGELOG.md` now records the unreleased feature set and known limitations, but notes cannot be assigned to a version until the owner confirms the first release version. | Move the Unreleased entry to the approved version, add the release date and artifact/checksum details, and verify the file is tracked with `git ls-files`. |
| Automated CI | BLOCKED | No `.github/workflows` or other CI configuration is tracked. | Owner must choose whether CI is required. If required, add a macOS workflow that runs the commands under Technical checks and require it on `main`; record the passing run URL and commit SHA. If deliberately manual, record that decision here. |
| Automated tests | BLOCKED | `swift test` exited 1 on 2026-08-15 with `error: no tests found`; `Package.swift` defines only executable target `Whisper`. The design document calls for clipboard and audio-conversion unit tests. | Add a test target and record passing test count/output, or document an explicit owner-approved manual-only exception. |
| Lint / format / static analysis | BLOCKED | SwiftLint, SwiftFormat, and ShellCheck were unavailable and no equivalent gate is configured. `swift build -c release` passed with zero warning/error lines, and `bash -n scripts/*.sh` passed. | Owner must select tooling or explicitly approve compiler plus shell-syntax checks as the release gate. |
| Dependency lock | PASS | `swift package dump-package`, `swift package resolve`, the manifest/lockfile diff check, and `swift package show-dependencies` passed without changing tracked files. WhisperKit is declared from `0.9.0` and resolves to `0.18.0`; `1.8.2` is the resolved swift-argument-parser version. | Repeat on the immutable candidate and require a clean manifest/lockfile diff. |
| Release build | PASS | `swift build -c release` and `./scripts/build-app.sh` exited 0 on arm64 macOS 26.6.1 with Swift 6.3.3/Xcode 26.6. The compiler log contained zero warning/error lines; the installed arm64 bundle passed plist and strict deep-signature validation. | Repeat after release-preparation changes are committed because this run included intentional uncommitted documentation/notice changes. The script replaces `/Applications/Whisper.app`. |
| Packaging | PASS | A fresh ignored `dist/Whisper.zip` was produced from the rebuilt app, tested, extracted, and revalidated. Final test artifact: 2,307,984 bytes, SHA-256 `48c9461366ff7f0ca72f5b4797c6667b1097a2ea8aafa347fc3ea8ec9265ee6d`; extracted executable is arm64 and both license resources are present. | This proves artifact production only. Do not publish this unapproved, ignored test artifact; rebuild from an immutable approved candidate. |
| Signing / Gatekeeper / notarization | BLOCKED | Local self-signed identity `Whisper Local Signing` passed `codesign --verify --deep --strict` before and after zip extraction. `spctl` rejected it (exit 3), and `stapler validate` found no ticket (exit 65). | Owner must choose source-only distribution or provide an approved Developer ID signing/notarization path for a public binary. |
| Publication destination | BLOCKED | Public GitHub repository exists, but no destination, naming convention, upload procedure, or release approval owner is documented. | Owner must name the destination (for example GitHub Releases), artifact names, checksum policy, and approver. A later authorized release task should record the final release URL; this task must not create it. |
| License | PASS | Root `LICENSE` is MIT; GitHub recognizes it. `THIRD_PARTY_NOTICES.md` records all eight resolved Swift dependencies, their exact versions/revisions, MIT and Apache-2.0 terms, and upstream NOTICE text. `scripts/build-app.sh` copies both project and third-party notices into the app bundle. | Recheck the notices whenever `Package.resolved` changes and confirm the candidate bundle contains both files. |
| Public documentation | PASS | README covers requirements, usage, source build, transfer, permissions, troubleshooting, architecture, support, contributing, security-reporting limitations, and licensing. `CONTRIBUTING.md` and `CHANGELOG.md` now provide contributor and change guidance. Both public URLs returned HTTP 200 during the 2026-08-15 audit. | Repeat the clean-checkout command audit and link check on the immutable candidate. |
| Secrets / private data | BLOCKED | Gitleaks 8.30.1 found no leaks in seven commits or in the tracked working-tree snapshot. Manual credential-pattern scans also found none. Commit metadata contains a personal Gmail address; whether to accept it or rewrite history is an owner privacy decision. | Owner must decide whether the published commit email is intentional. If not, replace it with a GitHub noreply address and follow an explicitly approved history-cleanup plan. Repeat both gitleaks scans over the final candidate and never paste discovered values into this file. |
| Manual app smoke test | PENDING | Design doc requires build, launch, permissions, and dictation into TextEdit; no candidate evidence is recorded. | Run the Manual smoke checks below on macOS 14+ Apple Silicon and record OS/hardware, candidate SHA, result, and any logs/screenshots. |
| Source TODOs | PASS | Search found no `TODO`, `FIXME`, `HACK`, or `XXX` in app source. `fatalError` occurs only in the icon-generation helper's render-failure path. | `git grep -nE 'TODO|FIXME|HACK|XXX' -- ':!RELEASE_STATUS.md'` |

## Technical checks

Run from a fresh checkout of the exact candidate commit. Record command, exit status, relevant tool versions, and the commit SHA in this file. A warning is not a pass until reviewed.

1. Baseline and toolchain
   - `git fetch origin`
   - `git status --short --branch`
   - `git rev-parse HEAD && git rev-parse origin/main`
   - `swift --version && xcodebuild -version`
2. Manifest and dependency consistency
   - `swift package dump-package >/tmp/whisper-package.json`
   - `swift package resolve`
   - `git diff --exit-code -- Package.swift Package.resolved`
   - `swift package show-dependencies`
3. Metadata
   - `plutil -lint Support/Info.plist`
   - `/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' Support/Info.plist`
   - `/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist`
   - `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Support/Info.plist`
   - Confirm the bundle identifier, marketing version, build number, minimum macOS version, copyright, icon, and microphone usage text.
4. Tests and compiler checks
   - `swift test`
   - `swift build -c release`
   - Treat absent tests and unresolved compiler warnings as failures unless an owner-approved exception is recorded.
5. App assembly
   - `./scripts/build-app.sh`
   - This installs/replaces `/Applications/Whisper.app`; do not run it on a machine where that side effect is unacceptable.
   - `test -x /Applications/Whisper.app/Contents/MacOS/Whisper`
   - `plutil -lint /Applications/Whisper.app/Contents/Info.plist`
   - `file /Applications/Whisper.app/Contents/MacOS/Whisper`
   - `codesign --verify --deep --strict --verbose=2 /Applications/Whisper.app`
   - `codesign -dv --verbose=4 /Applications/Whisper.app 2>&1`
6. Fresh artifact
   - `rm -f dist/Whisper.zip && mkdir -p dist`
   - `ditto -c -k --keepParent /Applications/Whisper.app dist/Whisper.zip`
   - `unzip -t dist/Whisper.zip`
   - `shasum -a 256 dist/Whisper.zip`
   - Extract to a temporary directory and repeat `plutil`, `file`, and `codesign --verify` against the extracted bundle.
   - `spctl -a -vv -t exec <extracted>/Whisper.app` (a self-signed/ad-hoc build is expected not to qualify as a public notarized binary; record the result honestly).
7. Repository cleanliness
   - `git status --short --branch`
   - Generated `.build/`, `build/`, and `dist/` content is ignored. Any tracked diff must be intentional and documented.

## Manual smoke checks

Record pass/fail and evidence for each item; do not reset permissions on the user's daily-use install without approval.

- Launch on Apple Silicon with the minimum supported macOS (14) or record the oldest tested version.
- First-run model download and Neural Engine compilation complete with understandable status.
- Microphone-denied and Accessibility-denied states show correct guidance.
- Hold-mode Right Option recording stops on release and inserts text into TextEdit.
- Toggle mode starts/stops correctly and cannot become stuck.
- Clipboard-only fallback preserves a usable transcript when Accessibility is absent.
- Settings persist for hotkey, mode, language, and model.
- Launch-at-login toggle works.
- Sleep/wake recovery restores the hotkey; capture `wake:` logs using the README command.
- Quit/relaunch and an ordinary reboot do not strand recording state or permissions.
- Fresh extracted artifact behaves the same as the locally built app, subject to the documented signing limitation.

## Public-readiness checks

- Read every tracked file from a public user's perspective; verify README clone URL and all links.
- Confirm `LICENSE`, copyright holder/year, and dependency license obligations.
- Decide whether `NOTICE`, `CONTRIBUTING.md`, `SECURITY.md`, support/contact guidance, a code of conduct, and issue templates are required; record explicit N/A decisions rather than silently omitting them.
- Add versioned release notes with features, requirements, known limitations, upgrade/install steps, checksum, and signing/notarization status.
- Confirm no internal paths, hosts, credentials, personal/private data, generated models, or unavailable resources are tracked.
- Scan tracked content: `git grep -nEI '(api[_-]?key|secret|token|password|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' -- . ':!RELEASE_STATUS.md'` and manually review every hit.
- Scan history with an available secret scanner (for example `gitleaks git --redact`); record scanner/version and result, never discovered values.
- Check oversized or accidental files: `git ls-files -z | xargs -0 du -h | sort -h` and inspect binaries deliberately tracked.
- Verify source-only instructions in a clean checkout. If a binary will be offered, test the exact downloaded artifact on a separate clean Mac and make the Gatekeeper/notarization limitation prominent.

### Public-readiness audit — 2026-08-15

This table records every nontechnical public-readiness item reviewed at
`e108fcb` plus the documentation changes in the working tree. **FAIL** means an
applicable item still needs an owner decision or release-candidate evidence; it
must not be read as release approval.

| Item | Result | Evidence / disposition |
|---|---|---|
| Project license and copyright | PASS | Root `LICENSE` is a complete MIT license for John Rue, 2026; GitHub recognizes it as MIT; README and bundle metadata agree. |
| Dependency licenses and notices | PASS | All eight `Package.resolved` dependencies were matched to licenses in their resolved checkouts: six Apache-2.0 and two MIT. `THIRD_PARTY_NOTICES.md` contains the license and required NOTICE text, and the build script copies it plus the project license into the bundle. |
| README requirements, installation, permissions, usage, and troubleshooting | PASS | README covers Apple Silicon/macOS requirements, source build, local signing, first-run model download, permissions, dictation usage, transfer, quarantine, and known signing behavior. |
| README links and clone URL | PASS | WhisperKit, repository, issue tracker, Keep a Changelog, and SemVer URLs returned HTTP 200 during the audit; relative repository links resolve to tracked or newly added files. |
| Changelog / release notes | FAIL | `CHANGELOG.md` now records Unreleased features and limitations, but a dated/versioned entry, checksum, and final signing/publication status depend on the release-version and artifact decisions. |
| Contribution guidance | PASS | `CONTRIBUTING.md` documents issue hygiene, local build/verification commands, manual-test expectations, pull-request scope, generated-file exclusions, and contribution licensing. |
| Support guidance | PASS | README directs reproducible bugs, questions, and feature requests to enabled GitHub Issues and warns against posting private data. |
| Security reporting | FAIL | Public reporting is explicitly discouraged, but GitHub private vulnerability reporting is disabled and no secure maintainer contact is documented. Owner must enable/name a private channel before release. |
| Code of conduct | N/A | The repository currently has one maintainer and no documented community program. Revisit when active external participation makes behavior/enforcement guidance necessary. |
| Issue / pull-request templates | N/A | GitHub Issues are enabled, but the repository is small and has no established triage workflow to encode yet. Revisit after recurring report requirements emerge. |
| Package and bundle metadata | PASS | `Package.swift` declares Swift tools 5.9, macOS 14, executable target, and dependency source; `Info.plist` lint passes and declares bundle ID, version/build, minimum OS, icon, microphone purpose, and copyright. Version approval remains a separate release blocker. |
| Credential exposure in current files | PASS | Gitleaks 8.30.1 scanned an isolated snapshot containing HEAD plus all modified/untracked public-readiness files: no leaks found (about 850 KB). Manual high-signal credential-pattern search also returned no findings. |
| Credential exposure in Git history | PASS | `gitleaks git --redact` scanned all seven commits (about 53 KB): no leaks found. |
| Personal/private data | FAIL | Commit author metadata exposes a personal Gmail address on every commit. No private transcripts, user home paths, model files, credentials, or host/IP details are tracked. Owner must confirm the email is intentional or approve a history rewrite. |
| Internal or unavailable resources | PASS | Tracked URLs are public. No internal hosts, private repositories, absolute user paths, or unavailable build resources were found. The design document's target hardware description is generic release context, not access-controlled infrastructure. |
| Oversized or accidental tracked files | PASS | The only tracked binary is the intentional 761,532-byte app icon. Models, app builds, and zips are ignored; the existing ignored zip is stale and remains disqualified as a release artifact. |
| Privacy/product claims | PASS | README's no-cloud claim matches the reviewed app architecture: microphone audio is passed to local WhisperKit inference; the first-run model download is disclosed. No telemetry or account integration is present. |

## Blocking owner decisions

A release should not proceed until these are resolved explicitly:

1. Confirm release version/build numbering and versioning policy.
2. Choose source-only versus downloadable binary distribution. A broadly downloadable binary needs a deliberate Developer ID/notarization decision; the current self-signed workflow is for local/personal builds.
3. Name the publication destination, artifact naming/checksum convention, and release approver.
4. Decide whether CI and automated tests are mandatory; the repository currently has neither.
5. Decide the lint/static-analysis quality gate.
6. Turn the Unreleased changelog entry into approved, versioned release notes.
7. Enable or document a private security-reporting channel.
8. Confirm whether the personal email in Git commit metadata is intentional; approve a history-rewrite plan if it is not.
9. Complete technical, manual, and public-readiness checks on one immutable candidate SHA.

## Candidate evidence log

### 2026-08-15 13:37 CDT — technical validation

- **Candidate basis:** `main` and `origin/main` matched at `e108fcb6203e83dcd967c80bf33451fa8798d0e1`; declared version/build `1.0.0` / `1`. The shared working directory also contained intentional, uncommitted release-documentation and notice changes, so this is not an immutable publishable candidate.
- **Environment:** Apple Silicon (`arm64`), macOS 26.6.1 (25G76), Xcode 26.6 (17F113), Apple Swift 6.3.3.
- **PASS — baseline/toolchain:** `git fetch origin`; branch/SHA equality checks; `swift --version`; `xcodebuild -version`.
- **PASS — manifest/dependencies:** `swift package dump-package`; JSON parse; `swift package resolve`; `git diff --exit-code -- Package.swift Package.resolved`; `swift package show-dependencies`. WhisperKit resolved to 0.18.0 with no lockfile mutation.
- **PASS — metadata:** `plutil -lint Support/Info.plist`; PlistBuddy checks for bundle id, version/build, minimum OS, icon, microphone usage text, and copyright; icon file check. Values were `com.john.whisper`, `1.0.0`, `1`, and macOS `14.0`; the executable's `LC_BUILD_VERSION` also reports minimum 14.0.
- **FAIL — automated tests:** `swift test` exited 1 because no tests were found. No owner-approved exception is recorded.
- **BLOCKED — configured lint/CI:** no CI, SwiftLint, SwiftFormat, ShellCheck, or repository-defined lint command exists. As partial compiler/static evidence, `swift build -c release` exited 0 with zero warning/error lines and `bash -n scripts/*.sh` passed.
- **PASS — assembly/local integrity:** `./scripts/build-app.sh` exited 0; the arm64 executable, bundle plist, bundled project license/notices, and strict deep code signature all validated. Signing authority is the machine-local self-signed `Whisper Local Signing`; no Team Identifier is present.
- **PASS — package mechanics:** rebuilt `dist/Whisper.zip`, `unzip -t`, temporary extraction, plist/file/resource checks, and extracted `codesign --verify --deep --strict` all passed. Test artifact size is 2,307,984 bytes; SHA-256 is `48c9461366ff7f0ca72f5b4797c6667b1097a2ea8aafa347fc3ea8ec9265ee6d`.
- **FAIL — public binary acceptance:** `spctl -a -vv -t exec` rejected the extracted app with origin `Whisper Local Signing` (exit 3); `xcrun stapler validate` reported no ticket (exit 65). This is expected for the current local-signing workflow but blocks an ordinary public binary.
- **N/A in this technical run:** no CI-equivalent command exists; manual app behavior, minimum-macOS hardware coverage, and clean-machine/downloader testing belong to later manual/public-readiness checks and remain pending.
- **Repository state:** generated `.build/`, `build/`, and `dist/` files are ignored. Intentional release-preparation changes in `README.md`, `scripts/build-app.sh`, `CHANGELOG.md`, `CONTRIBUTING.md`, `RELEASE_STATUS.md`, and `THIRD_PARTY_NOTICES.md` remain uncommitted and must be reviewed/committed or removed by the downstream disposition task.
- **Unresolved owner decisions:** release version/build policy and tag; source-only versus Developer ID/notarized binary; publication destination/naming/checksum/approver; CI/test requirement; lint gate; security reporting channel and commit-email privacy decision; final manual smoke coverage.
