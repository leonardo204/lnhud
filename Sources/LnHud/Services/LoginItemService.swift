import ServiceManagement
import AppKit

final class LoginItemService {
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration failed — guide user to System Settings
            if enabled {
                openLoginItemsSettings()
            }
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private static func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
