import AppKit
import Combine

// MARK: - HUDTimer Protocol

protocol HUDTimerProtocol {
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> any Cancellable
}

// MARK: - DispatchQueue-based HUDTimer

private final class DispatchWorkItemCancellable: Cancellable {
    private let workItem: DispatchWorkItem

    init(_ workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    func cancel() {
        workItem.cancel()
    }
}

final class DispatchHUDTimer: HUDTimerProtocol {
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> any Cancellable {
        let workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return DispatchWorkItemCancellable(workItem)
    }
}

// MARK: - HUDController

@MainActor
final class HUDController {
    enum State: Equatable {
        case idle
        case fadeIn
        case visible
        case fadeOut
    }

    private let settings: AppSettings
    private let timer: HUDTimerProtocol
    private var panel: HUDPanel?

    private(set) var state: State = .idle
    private(set) var displayText: String? = nil
    private(set) var currentSourceID: String? = nil

    private var pendingCancellable: (any Cancellable)?
    nonisolated(unsafe) private var screenObserver: Any?

    init(settings: AppSettings = AppSettings(), timer: HUDTimerProtocol = DispatchHUDTimer()) {
        self.settings = settings
        self.timer = timer
        setupScreenObserver()
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupScreenObserver() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.repositionPanel()
            }
        }
    }

    private func targetScreen() -> NSScreen? {
        switch settings.screenMode {
        case .builtIn:
            return Self.builtInScreen() ?? NSScreen.main ?? NSScreen.screens.first
        case .mainScreen:
            return NSScreen.main ?? NSScreen.screens.first
        case .mouseCursor:
            let mouseLocation = NSEvent.mouseLocation
            return NSScreen.screens.first(where: {
                NSMouseInRect(mouseLocation, $0.frame, false)
            }) ?? NSScreen.main ?? NSScreen.screens.first
        }
    }

    private static func builtInScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            let description = screen.deviceDescription
            // CGDirectDisplayID for built-in display
            if let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                return CGDisplayIsBuiltin(screenNumber) != 0
            }
            return false
        }
    }

    private func repositionPanel() {
        guard let panel = panel, panel.isVisible else { return }
        guard let screen = targetScreen() else { return }
        panel.positionOn(screen: screen, position: settings.hudPosition, offsetX: settings.hudOffsetX, offsetY: settings.hudOffsetY)
    }

    func show(text: String, sourceID: String? = nil) {
        pendingCancellable?.cancel()
        pendingCancellable = nil
        displayText = text
        currentSourceID = sourceID
        state = .fadeIn

        pendingCancellable = timer.schedule(after: 0.15) { [weak self] in
            self?.onFadeInComplete()
        }

        if NSScreen.main != nil {
            showPanel(text: text)
        }
    }

    private func onFadeInComplete() {
        guard state == .fadeIn else { return }
        state = .visible
        scheduleHide()
    }

    private func scheduleHide() {
        pendingCancellable = timer.schedule(after: settings.hudDuration) { [weak self] in
            self?.beginFadeOut()
        }
    }

    private func beginFadeOut() {
        guard state == .visible else { return }
        state = .fadeOut
        scheduleFadeOutComplete()

        // Animate fade out
        if let panel = panel {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                panel.animator().alphaValue = 0
            }
        }
    }

    private func scheduleFadeOutComplete() {
        pendingCancellable = timer.schedule(after: 0.3) { [weak self] in
            self?.onFadeOutComplete()
        }
    }

    private func onFadeOutComplete() {
        guard state == .fadeOut else { return }
        state = .idle
        panel?.orderOut(nil)
    }

    // MARK: - Panel management

    private func showPanel(text: String) {
        if panel == nil {
            panel = HUDPanel()
        }

        guard let panel = panel else { return }

        panel.updateText(
            text,
            fontSize: settings.hudFontSize,
            cornerRadius: settings.hudCornerRadius,
            opacity: settings.hudOpacity,
            backgroundColor: settings.resolvedColorForSource(currentSourceID)
        )

        guard let screen = targetScreen() else { return }
        panel.positionOn(screen: screen, position: settings.hudPosition, offsetX: settings.hudOffsetX, offsetY: settings.hudOffsetY)
        panel.alphaValue = 0
        panel.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1.0
        }
    }
}
