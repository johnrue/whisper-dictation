import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var controller: AppController
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(controller.status.label)

        if !controller.microphoneGranted {
            Button("⚠️ Grant Microphone Access…") {
                Permissions.openMicrophoneSettings()
            }
        }
        if !controller.accessibilityGranted {
            Button("⚠️ Grant Accessibility Access…") {
                Permissions.openAccessibilitySettings()
            }
        }

        Divider()

        Text(hotkeyHint)

        if case .error = controller.status {
            Button("Retry Loading Model") {
                controller.loadModel()
            }
        }

        Divider()

        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Button("Quit Whisper") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private var hotkeyHint: String {
        let key = controller.settings.hotkeyKey.label
        switch controller.settings.hotkeyMode {
        case .hold: return "Hold \(key) to dictate"
        case .toggle: return "Press \(key) to start/stop"
        }
    }
}
