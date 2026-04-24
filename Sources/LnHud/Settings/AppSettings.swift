import SwiftUI

import AppKit

extension NSColor {
    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "1A1A1A" }
        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }

    static func fromHex(_ hex: String) -> NSColor? {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6 else { return nil }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        return NSColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum HUDColorMode: String, CaseIterable {
    case system = "system"
    case preset = "preset"
    case custom = "custom"
}

enum HUDPresetColor: String, CaseIterable {
    case dark = "dark"
    case graphite = "graphite"
    case navy = "navy"
    case indigo = "indigo"
    case teal = "teal"
    case forest = "forest"
    case berry = "berry"
    case brown = "brown"

    var label: String {
        switch self {
        case .dark: return "Dark"
        case .graphite: return "Graphite"
        case .navy: return "Navy"
        case .indigo: return "Indigo"
        case .teal: return "Teal"
        case .forest: return "Forest"
        case .berry: return "Berry"
        case .brown: return "Brown"
        }
    }

    var color: NSColor {
        switch self {
        case .dark:     return NSColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
        case .graphite: return NSColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1)
        case .navy:     return NSColor(red: 0.10, green: 0.15, blue: 0.35, alpha: 1)
        case .indigo:   return NSColor(red: 0.20, green: 0.15, blue: 0.40, alpha: 1)
        case .teal:     return NSColor(red: 0.10, green: 0.28, blue: 0.32, alpha: 1)
        case .forest:   return NSColor(red: 0.10, green: 0.25, blue: 0.12, alpha: 1)
        case .berry:    return NSColor(red: 0.35, green: 0.10, blue: 0.18, alpha: 1)
        case .brown:    return NSColor(red: 0.30, green: 0.22, blue: 0.12, alpha: 1)
        }
    }

    var swiftUIColor: Color {
        Color(nsColor: color)
    }
}

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

enum HUDPosition: String, CaseIterable {
    case topLeft, topCenter, topRight
    case middleLeft, center, middleRight
    case bottomLeft, bottomCenter, bottomRight
}

final class AppSettings: ObservableObject {
    private enum Keys {
        static let hudDuration = "hudDuration"
        static let hudFontSize = "hudFontSize"
        static let hudCornerRadius = "hudCornerRadius"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let launchAtLogin = "launchAtLogin"
        static let hudOpacity = "hudOpacity"
        static let hudColorMode = "hudColorMode"
        static let hudPresetColor = "hudPresetColor"
        static let hudCustomColorHex = "hudCustomColorHex"
        static let screenMode = "screenMode"
        static let hudPosition = "hudPosition"
        static let hudOffsetX = "hudOffsetX"
        static let hudOffsetY = "hudOffsetY"
        static let colorSyncEnabled = "colorSyncEnabled"
        static let perSourceColors = "perSourceColors"
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

    @Published var hudColorMode: HUDColorMode {
        didSet { defaults.set(hudColorMode.rawValue, forKey: Keys.hudColorMode) }
    }

    @Published var hudPresetColor: HUDPresetColor {
        didSet { defaults.set(hudPresetColor.rawValue, forKey: Keys.hudPresetColor) }
    }

    @Published var hudCustomColorHex: String {
        didSet { defaults.set(hudCustomColorHex, forKey: Keys.hudCustomColorHex) }
    }

    /// Resolved NSColor based on current color mode
    var resolvedHUDColor: NSColor? {
        switch hudColorMode {
        case .system: return nil
        case .preset: return hudPresetColor.color
        case .custom: return NSColor.fromHex(hudCustomColorHex)
        }
    }

    /// sourceID에 대응하는 색상 반환 (Sync OFF 시 언어별 색상, ON 시 공통 색상)
    func resolvedColorForSource(_ sourceID: String?) -> NSColor? {
        if colorSyncEnabled {
            return resolvedHUDColor
        }
        guard let sourceID = sourceID,
              let hex = perSourceColors[sourceID] else {
            return NSColor.fromHex("1A1A1A")
        }
        return NSColor.fromHex(hex)
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

    @Published var hudPosition: HUDPosition {
        didSet { defaults.set(hudPosition.rawValue, forKey: Keys.hudPosition) }
    }

    @Published var hudOffsetX: CGFloat {
        didSet { defaults.set(hudOffsetX, forKey: Keys.hudOffsetX) }
    }

    @Published var hudOffsetY: CGFloat {
        didSet { defaults.set(hudOffsetY, forKey: Keys.hudOffsetY) }
    }

    @Published var colorSyncEnabled: Bool {
        didSet { defaults.set(colorSyncEnabled, forKey: Keys.colorSyncEnabled) }
    }

    @Published var perSourceColors: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(perSourceColors) {
                defaults.set(data, forKey: Keys.perSourceColors)
            }
        }
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

        if let rawValue = defaults.string(forKey: Keys.hudColorMode),
           let mode = HUDColorMode(rawValue: rawValue) {
            hudColorMode = mode
        } else {
            hudColorMode = .system
        }

        if let rawValue = defaults.string(forKey: Keys.hudPresetColor),
           let preset = HUDPresetColor(rawValue: rawValue) {
            hudPresetColor = preset
        } else {
            hudPresetColor = .dark
        }

        hudCustomColorHex = defaults.string(forKey: Keys.hudCustomColorHex) ?? "1A1A1A"

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

        if let rawValue = defaults.string(forKey: Keys.hudPosition),
           let position = HUDPosition(rawValue: rawValue) {
            hudPosition = position
        } else {
            hudPosition = .center
        }

        if defaults.object(forKey: Keys.hudOffsetX) != nil {
            hudOffsetX = CGFloat(defaults.double(forKey: Keys.hudOffsetX))
        } else {
            hudOffsetX = 0
        }

        if defaults.object(forKey: Keys.hudOffsetY) != nil {
            hudOffsetY = CGFloat(defaults.double(forKey: Keys.hudOffsetY))
        } else {
            hudOffsetY = 0
        }

        if defaults.object(forKey: Keys.colorSyncEnabled) != nil {
            colorSyncEnabled = defaults.bool(forKey: Keys.colorSyncEnabled)
        } else {
            colorSyncEnabled = true
        }

        if let data = defaults.data(forKey: Keys.perSourceColors),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            perSourceColors = dict
        } else {
            perSourceColors = [:]
        }
    }
}
