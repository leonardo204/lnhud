# LnHud

A lightweight macOS menu bar utility that displays a HUD (Heads-Up Display) overlay when you switch keyboard input sources. Built as an Apple Silicon native replacement for [iSHud](https://apps.apple.com/kr/app/ishud/id484757536).

## Features

- **Input Source HUD** — Shows current input source name (e.g., "한국어", "English") as a large overlay in the center of the screen when switching keyboard layouts
- **Customizable** — Adjust HUD duration, font size, corner radius, and opacity
- **Multi-Monitor Support** — Choose where the HUD appears: built-in display, main screen, or mouse cursor screen
- **Menu Bar App** — Runs as a menu bar utility with no Dock icon
- **Launch at Login** — Auto-start via SMAppService
- **App Sandbox** — MAS-ready with minimal permissions

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (arm64) or Intel (Universal Binary)

## Build

```bash
# Install xcodegen if needed
brew install xcodegen

# Generate Xcode project and build
xcodegen generate
xcodebuild -project LnHud.xcodeproj -scheme LnHud -configuration Release build

# Run tests
xcodebuild -project LnHud.xcodeproj -scheme LnHud test
```

## Project Structure

```
Sources/LnHud/
├── App/            # App entry point, AppState, URL scheme handler
├── Settings/       # AppSettings (UserDefaults-backed)
├── HUD/            # HUDPanel (NSPanel), HUDController (state machine)
├── Input/          # InputSourceReader (TIS API), InputSourceMonitor
├── UI/             # MenuBarMenu, PreferencesView
└── Services/       # LoginItemService (SMAppService)
```

## How It Works

1. `InputSourceMonitor` listens for `com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged` via `DistributedNotificationCenter`
2. On input source change, `InputSourceReader` reads the current source name using Carbon TIS API (`TISCopyCurrentKeyboardInputSource`)
3. `HUDController` manages a state machine (idle → fadeIn → visible → fadeOut → idle) and displays the text via `HUDPanel`
4. `HUDPanel` is a borderless `NSPanel` using `NSVisualEffectView` + `NSTextField` (pure AppKit, no Auto Layout)

## License

MIT
