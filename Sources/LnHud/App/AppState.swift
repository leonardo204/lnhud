import Foundation

@MainActor
final class AppState: ObservableObject {
    let settings: AppSettings
    let hudController: HUDController
    let inputSourceMonitor: InputSourceMonitor

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings

        let reader = InputSourceReader()
        let hudController = HUDController(settings: settings)
        self.hudController = hudController

        self.inputSourceMonitor = InputSourceMonitor(
            reader: reader,
            hudController: hudController
        )
        // Defer start to avoid publishing changes during SwiftUI view evaluation
        DispatchQueue.main.async { [weak self] in
            self?.inputSourceMonitor.start()
        }
    }

    func startMonitoring() {
        inputSourceMonitor.start()
    }

    func stopMonitoring() {
        inputSourceMonitor.stop()
    }
}
