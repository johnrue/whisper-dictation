import AppKit
import Combine
import SwiftUI

/// Central coordinator: wires the hotkey to the recorder, transcriber, text
/// inserter, and HUD, and exposes observable state to the UI.
@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    @Published var status: AppStatus = .startingUp {
        didSet { NSLog("status: \(status.label)") }
    }
    @Published var audioLevel: Float = 0
    /// Transient message shown in the HUD (e.g. "Didn't catch that").
    @Published var hudMessage: String?
    @Published var microphoneGranted = false
    @Published var accessibilityGranted = false

    private(set) var settings = AppSettings.load()

    private let hotkey = HotkeyMonitor()
    private let recorder = AudioRecorder()
    private let transcriber = Transcriber()
    private let hud = HUDController()
    private var permissionPollTimer: Timer?
    private var hudMessageTask: Task<Void, Never>?

    /// Held for the app's lifetime. As an LSUIElement background app with no
    /// visible window, the process is otherwise put into App Nap after a few
    /// minutes of inactivity, which throttles the run loop and stops our global
    /// hotkey monitor from receiving events — the app appears loaded but the
    /// hotkey silently stops working.
    private let activityToken: NSObjectProtocol

    /// Minimum recording length worth transcribing (~0.3 s).
    private let minimumSampleCount = Int(AudioRecorder.sampleRate * 0.3)

    private init() {
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep],
            reason: "Listening for the global dictation hotkey"
        )

        hud.controller = self

        hotkey.onKeyDown = { [weak self] in self?.beginRecording() }
        hotkey.onKeyUp = { [weak self] in self?.endRecordingAndTranscribe() }
        hotkey.configure(key: settings.hotkeyKey, mode: settings.hotkeyMode)

        recorder.levelHandler = { [weak self] level in
            Task { @MainActor in self?.audioLevel = level }
        }

        refreshPermissions()
        requestPermissionsIfNeeded()
        startPermissionPolling()
        observeSystemWake()
        loadModel()
    }

    // MARK: - Sleep / wake recovery

    /// Global NSEvent monitors silently stop delivering events across a system
    /// sleep/wake cycle (the app is otherwise fine — main thread idle, model
    /// loaded — the hotkey just goes dead). Re-install them on wake, and clear
    /// any state that got wedged mid-dictation when the machine slept.
    private func observeSystemWake() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.recoverAfterWake() }
        }
    }

    private func recoverAfterWake() {
        NSLog("wake: re-installing hotkey monitor and recovering state")
        hotkey.install()
        if isRecording { _ = recorder.stop() }
        audioLevel = 0
        // Return to a usable state. Anything that was in flight (recording,
        // transcribing) or a transient error is now stale and would wedge the
        // hotkey, since beginRecording only fires from .idle.
        if transcriber.isLoaded {
            status = .idle
        } else {
            loadModel()
        }
    }

    private var isRecording: Bool {
        if case .recording = status { return true }
        return false
    }

    // MARK: - Model lifecycle

    func loadModel() {
        status = .startingUp
        let model = settings.model
        let transcriber = self.transcriber
        Task {
            do {
                try await transcriber.load(model: model)
                self.status = .idle
            } catch {
                self.status = .error("Model load failed: \(error.localizedDescription)")
            }
        }
    }

    /// Called by the settings UI after any setting changes.
    func settingsChanged() {
        let previousModel = settings.model
        settings = AppSettings.load()
        hotkey.configure(key: settings.hotkeyKey, mode: settings.hotkeyMode)
        if settings.model != previousModel {
            loadModel()
        }
    }

    // MARK: - Dictation flow

    private func beginRecording() {
        guard case .idle = status else {
            if case .startingUp = status {
                showHUDMessage("Model is still loading…")
            }
            return
        }
        guard microphoneGranted else {
            showHUDMessage("Microphone access needed — see menu")
            return
        }
        do {
            try recorder.start()
            status = .recording
            hud.show()
        } catch {
            status = .error(error.localizedDescription)
            showHUDMessage(error.localizedDescription)
        }
    }

    private func endRecordingAndTranscribe() {
        guard case .recording = status else { return }
        let samples = recorder.stop()
        audioLevel = 0

        guard samples.count >= minimumSampleCount else {
            status = .idle
            showHUDMessage("Didn't catch that")
            return
        }

        status = .transcribing
        let language = settings.whisperLanguage
        let transcriber = self.transcriber
        Task {
            do {
                let text = try await transcriber.transcribe(samples: samples, language: language)
                self.handleTranscript(text)
            } catch {
                self.status = .idle
                self.showHUDMessage("Transcription failed")
            }
        }
    }

    private func handleTranscript(_ text: String) {
        status = .idle
        guard !text.isEmpty else {
            showHUDMessage("Didn't catch that")
            return
        }
        switch TextInserter.insert(text) {
        case .pasted:
            hud.hide(after: 0.3)
        case .copiedOnly:
            showHUDMessage("Copied — press ⌘V to paste")
        }
    }

    // MARK: - HUD

    func showHUDMessage(_ message: String, duration: TimeInterval = 1.8) {
        hudMessage = message
        hud.show()
        hudMessageTask?.cancel()
        hudMessageTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.hudMessage = nil
            if case .idle = self.status { self.hud.hide(after: 0) }
        }
    }

    // MARK: - Permissions

    func refreshPermissions() {
        microphoneGranted = Permissions.microphoneGranted
        accessibilityGranted = Permissions.accessibilityGranted
    }

    private func requestPermissionsIfNeeded() {
        if !microphoneGranted {
            Task {
                self.microphoneGranted = await Permissions.requestMicrophone()
            }
        }
        if !accessibilityGranted {
            Permissions.promptAccessibility()
        }
    }

    /// Global event monitors silently do nothing until Accessibility is
    /// granted; poll until it is, then re-install them.
    private func startPermissionPolling() {
        guard !accessibilityGranted else { return }
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.refreshPermissions()
                if self.accessibilityGranted {
                    self.hotkey.install()
                    self.permissionPollTimer?.invalidate()
                    self.permissionPollTimer = nil
                }
            }
        }
    }
}
