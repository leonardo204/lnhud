import SwiftUI

enum HUDScreenMode: String, CaseIterable {
    case builtIn = "builtIn"
    case mainScreen = "mainScreen"
    case mouseCursor = "mouseCursor"

    var localizedLabel: String {
        switch self {
        case .builtIn: return "Built-in Display"
        case .mainScreen: return "Main Screen"
        case .mouseCursor: return "Mouse Cursor Screen"
        }
    }
}

final class AppSettings: ObservableObject {
    private enum Keys {
        static let hudDuration = "hudDuration"
        static let hudFontSize = "hudFontSize"
        static let hudCornerRadius = "hudCornerRadius"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let launchAtLogin = "launchAtLogin"
        static let hudOpacity = "hudOpacity"
        static let screenMode = "screenMode"
    }

    private let defaults: UserDefaults

    @Published var hudDuration: Double {
        didSet { defaults.set(hudDuration, forKey: Keys.hudDuration) }
    }

    @Published var hudFontSize: CGFloat {
        didSet { defaults.set(hudFontSize, forKey: Keys.hudFontSize) }
    }

    @Published var hudCornerRadius: CGFloat {
        didSet { defaults.set(hudCornerRadius, forKey: Keys.hudCornerRadius) }
    }

    @Published var hudOpacity: Double {
        didSet { defaults.set(hudOpacity, forKey: Keys.hudOpacity) }
    }

    @Published var showMenuBarIcon: Bool {
        didSet { defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon) }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var screenMode: HUDScreenMode {
        didSet { defaults.set(screenMode.rawValue, forKey: Keys.screenMode) }
    }

    convenience init() {
        self.init(defaults: .standard)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults

        if defaults.object(forKey: Keys.hudDuration) != nil {
            hudDuration = defaults.double(forKey: Keys.hudDuration)
        } else {
            hudDuration = 1.0
        }

        if defaults.object(forKey: Keys.hudFontSize) != nil {
            hudFontSize = CGFloat(defaults.double(forKey: Keys.hudFontSize))
        } else {
            hudFontSize = 64
        }

        if defaults.object(forKey: Keys.hudCornerRadius) != nil {
            hudCornerRadius = CGFloat(defaults.double(forKey: Keys.hudCornerRadius))
        } else {
            hudCornerRadius = 24
        }

        if defaults.object(forKey: Keys.hudOpacity) != nil {
            hudOpacity = defaults.double(forKey: Keys.hudOpacity)
        } else {
            hudOpacity = 0.9
        }

        if defaults.object(forKey: Keys.showMenuBarIcon) != nil {
            showMenuBarIcon = defaults.bool(forKey: Keys.showMenuBarIcon)
        } else {
            showMenuBarIcon = true
        }

        if defaults.object(forKey: Keys.launchAtLogin) != nil {
            launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        } else {
            launchAtLogin = false
        }

        if let rawValue = defaults.string(forKey: Keys.screenMode),
           let mode = HUDScreenMode(rawValue: rawValue) {
            screenMode = mode
        } else {
            screenMode = .builtIn
        }
    }
}
