import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var controller: AppController

    @AppStorage(SettingsKey.model) private var model = ModelOption.defaultID
    @AppStorage(SettingsKey.language) private var language = "auto"
    @AppStorage(SettingsKey.hotkeyKey) private var hotkeyKey = HotkeyKey.rightOption.rawValue
    @AppStorage(SettingsKey.hotkeyMode) private var hotkeyMode = HotkeyMode.hold.rawValue
    @AppStorage(SettingsKey.playSounds) private var playSounds = true

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Section("Dictation") {
                Picker("Hotkey", selection: $hotkeyKey) {
                    ForEach(HotkeyKey.allCases) { key in
                        Text(key.label).tag(key.rawValue)
                    }
                }
                Picker("Behavior", selection: $hotkeyMode) {
                    ForEach(HotkeyMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                Picker("Language", selection: $language) {
                    ForEach(LanguageOption.all) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                Toggle("Play sound when recording starts and stops", isOn: $playSounds)
            }

            Section("Model") {
                Picker("Whisper model", selection: $model) {
                    ForEach(ModelOption.all) { option in
                        Text("\(option.label) — \(option.detail)").tag(option.id)
                    }
                }
                Text("Changing the model downloads it on first use.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: model) { controller.settingsChanged() }
        .onChange(of: language) { controller.settingsChanged() }
        .onChange(of: hotkeyKey) { controller.settingsChanged() }
        .onChange(of: hotkeyMode) { controller.settingsChanged() }
        .onChange(of: playSounds) { controller.settingsChanged() }
        .onChange(of: launchAtLogin) { toggleLaunchAtLogin() }
    }

    private func toggleLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = "Could not update login item: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
