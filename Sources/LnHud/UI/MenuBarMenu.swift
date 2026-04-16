import SwiftUI

struct MenuBarMenu: View {
    @ObservedObject var appState: AppState

    var body: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Preferences…")
            }
            .keyboardShortcut(",", modifiers: .command)
        } else {
            Button("Preferences…") {
                URLSchemeHandler.requestOpenPreferences()
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        Button("Test HUD") {
            testHUD()
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func testHUD() {
        let name = appState.inputSourceMonitor.currentSourceName() ?? "Korean"
        Task { @MainActor in
            appState.hudController.show(text: name)
        }
    }
}
