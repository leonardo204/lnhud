import Foundation

@MainActor
final class InputSourceMonitor {
    private let reader: InputSourceReading
    private let hudController: HUDController
    private var observer: Any?
    private var lastSourceID: String?

    init(reader: InputSourceReading, hudController: HUDController) {
        self.reader = reader
        self.hudController = hudController
    }

    func start() {
        guard observer == nil else { return }
        // Record current source so we don't show HUD on app launch
        lastSourceID = reader.currentInputSourceID()
        let notificationName = Notification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged")
        observer = DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleInputSourceChanged()
            }
        }
    }

    func stop() {
        if let observer = observer {
            DistributedNotificationCenter.default().removeObserver(observer)
            self.observer = nil
        }
    }

    func currentSourceName() -> String? {
        return reader.currentInputSourceName()
    }

    private func handleInputSourceChanged() {
        let currentID = reader.currentInputSourceID()

        // Only show HUD when the input source actually changed
        guard currentID != lastSourceID else { return }

        lastSourceID = currentID

        guard let name = reader.currentInputSourceName() else { return }
        hudController.show(text: name, sourceID: currentID)
    }
}
