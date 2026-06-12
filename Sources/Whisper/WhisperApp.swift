import SwiftUI

@main
struct WhisperApp: App {
    @StateObject private var controller = AppController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(controller)
        } label: {
            Image(systemName: controller.status.menuBarSymbol)
        }

        Settings {
            SettingsView()
                .environmentObject(controller)
        }
    }
}
