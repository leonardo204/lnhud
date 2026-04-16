import AppKit

extension Notification.Name {
    static let openPreferences = Notification.Name("LnHud.openPreferences")
}

@MainActor
final class URLSchemeHandler {
    static func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "lnhud" else { return }

        if url.host?.lowercased() == "preferences" {
            requestOpenPreferences()
        }
    }

    static func requestOpenPreferences() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        NotificationCenter.default.post(name: .openPreferences, object: nil)
    }
}
