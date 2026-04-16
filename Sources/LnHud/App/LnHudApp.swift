import SwiftUI

@main
struct LnHudApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("LnHud", systemImage: "keyboard", isInserted: Binding(
            get: { appState.settings.showMenuBarIcon },
            set: { newValue in
                DispatchQueue.main.async {
                    appState.settings.showMenuBarIcon = newValue
                }
            }
        )) {
            MenuBarMenu(appState: appState)
        }

        Settings {
            PreferencesView(appState: appState)
                .onOpenURL { url in
                    URLSchemeHandler.handle(url)
                }
                .modifier(OpenPreferencesModifier())
        }
    }

    init() {
        // If menu bar icon is hidden, auto-open preferences on launch
        let settings = AppSettings()
        if !settings.showMenuBarIcon {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                URLSchemeHandler.requestOpenPreferences()
            }
        }
    }
}

/// Listens for .openPreferences notification and opens Settings via the appropriate API
private struct OpenPreferencesModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.modifier(OpenPreferencesModifier14())
        } else {
            content.onReceive(NotificationCenter.default.publisher(for: .openPreferences)) { _ in
                // macOS 13: use the standard preferences action
                NSApp.sendAction(Selector(("orderFrontPreferencesPanel:")), to: nil, from: nil)
            }
        }
    }
}

@available(macOS 14.0, *)
private struct OpenPreferencesModifier14: ViewModifier {
    @Environment(\.openSettings) private var openSettings

    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: .openPreferences)) { _ in
            openSettings()
        }
    }
}
