import SwiftUI

struct PreferencesView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings: AppSettings
    @State private var showMenuBarWarning = false

    init(appState: AppState) {
        self.appState = appState
        self.settings = appState.settings
    }

    var body: some View {
        Form {
            // MARK: - HUD Section
            Section("HUD") {
                LabeledContent("Duration: \(String(format: "%.1f", settings.hudDuration))s") {
                    Slider(value: $settings.hudDuration, in: 0.5...3.0, step: 0.1)
                        .frame(width: 200)
                }

                LabeledContent("Font Size: \(Int(settings.hudFontSize))pt") {
                    Slider(
                        value: Binding(
                            get: { Double(settings.hudFontSize) },
                            set: { newValue in
                                DispatchQueue.main.async {
                                    settings.hudFontSize = CGFloat(newValue)
                                }
                            }
                        ),
                        in: 32...96,
                        step: 2
                    )
                    .frame(width: 200)
                }

                LabeledContent("Opacity: \(Int(settings.hudOpacity * 100))%") {
                    Slider(value: $settings.hudOpacity, in: 0.3...1.0, step: 0.05)
                        .frame(width: 200)
                }

                LabeledContent("Corner Radius: \(Int(settings.hudCornerRadius))") {
                    Slider(
                        value: Binding(
                            get: { Double(settings.hudCornerRadius) },
                            set: { newValue in
                                DispatchQueue.main.async {
                                    settings.hudCornerRadius = CGFloat(newValue)
                                }
                            }
                        ),
                        in: 8...48,
                        step: 2
                    )
                    .frame(width: 200)
                }
            }

            // MARK: - Color Section
            Section("Color") {
                Picker("Mode", selection: $settings.hudColorMode) {
                    Text("System").tag(HUDColorMode.system)
                    Text("Preset").tag(HUDColorMode.preset)
                    Text("Custom").tag(HUDColorMode.custom)
                }
                .pickerStyle(.segmented)

                if settings.hudColorMode == .preset {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                        ForEach(HUDPresetColor.allCases, id: \.self) { preset in
                            Button {
                                DispatchQueue.main.async {
                                    settings.hudPresetColor = preset
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(preset.swiftUIColor)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(
                                                settings.hudPresetColor == preset ? Color.accentColor : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(preset.label)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if settings.hudColorMode == .custom {
                    ColorPicker("HUD Color", selection: Binding(
                        get: {
                            if let nsColor = NSColor.fromHex(settings.hudCustomColorHex) {
                                return Color(nsColor: nsColor)
                            }
                            return Color(nsColor: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
                        },
                        set: { newColor in
                            DispatchQueue.main.async {
                                settings.hudCustomColorHex = NSColor(newColor).hexString
                            }
                        }
                    ), supportsOpacity: false)
                }
            }

            // MARK: - Display Section
            Section("Display") {
                Toggle(isOn: Binding(
                    get: { settings.showMenuBarIcon },
                    set: { newValue in
                        if !newValue {
                            showMenuBarWarning = true
                        } else {
                            DispatchQueue.main.async {
                                settings.showMenuBarIcon = true
                            }
                        }
                    }
                )) {
                    Text("Show Menu Bar Icon")
                }
                .alert("Hide Menu Bar Icon?", isPresented: $showMenuBarWarning) {
                    Button("Hide", role: .destructive) {
                        settings.showMenuBarIcon = false
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("If you hide the menu bar icon, you can only access settings by relaunching the app or running 'open lnhud://preferences' in Terminal.")
                }

                Picker("HUD Screen", selection: $settings.screenMode) {
                    ForEach(HUDScreenMode.allCases, id: \.self) { mode in
                        Text(mode.localizedLabel).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            // MARK: - Startup Section
            Section("Startup") {
                Toggle(isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        DispatchQueue.main.async {
                            settings.launchAtLogin = newValue
                            LoginItemService.setEnabled(newValue)
                        }
                    }
                )) {
                    Text("Launch at Login")
                }
            }

            // MARK: - Actions
            Section {
                Button("Test HUD") {
                    let name = appState.inputSourceMonitor.currentSourceName() ?? "Korean"
                    appState.hudController.show(text: name)
                }
            }

            // MARK: - About
            Section {
                HStack {
                    Text("LnHud")
                        .fontWeight(.medium)
                    Spacer()
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }
}
