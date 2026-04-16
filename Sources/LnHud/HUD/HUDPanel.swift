import AppKit

final class HUDPanel: NSPanel {

    private let backgroundView = NSVisualEffectView()
    private let colorOverlayView = NSView()
    private let label = NSTextField(labelWithString: "")

    private var cornerRadius: CGFloat = 24
    private let horizontalPadding: CGFloat = 32
    private let verticalPadding: CGFloat = 20

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        configureWindow()
        setupContent()
    }

    // MARK: - Window configuration

    private func configureWindow() {
        level = .screenSaver
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary
        ]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }

    // MARK: - Content setup (pure AppKit, no Auto Layout)

    private func setupContent() {
        backgroundView.material = .hudWindow
        backgroundView.state = .active
        backgroundView.blendingMode = .behindWindow
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = cornerRadius
        backgroundView.layer?.masksToBounds = true

        label.font = .systemFont(ofSize: 64, weight: .bold)
        label.textColor = .labelColor
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.lineBreakMode = .byTruncatingTail
        label.setAccessibilityHidden(true)

        colorOverlayView.wantsLayer = true
        colorOverlayView.layer?.masksToBounds = true
        colorOverlayView.alphaValue = 0 // hidden by default (system mode)

        // Frame-based layout only — no Auto Layout
        backgroundView.autoresizingMask = [.width, .height]
        colorOverlayView.autoresizingMask = [.width, .height]
        label.translatesAutoresizingMaskIntoConstraints = true

        let contentBox = NSView(frame: .zero)
        contentBox.wantsLayer = true
        contentBox.addSubview(backgroundView)
        contentBox.addSubview(colorOverlayView)
        contentBox.addSubview(label)
        contentView = contentBox
    }

    // MARK: - Public API

    func updateText(_ text: String, fontSize: CGFloat, cornerRadius newRadius: CGFloat, opacity: Double = 0.9, backgroundColor: NSColor? = nil) {
        cornerRadius = newRadius
        backgroundView.layer?.cornerRadius = cornerRadius
        colorOverlayView.layer?.cornerRadius = cornerRadius

        if let bgColor = backgroundColor {
            // Custom/preset color mode: show color overlay, keep blur underneath
            colorOverlayView.layer?.backgroundColor = bgColor.withAlphaComponent(CGFloat(opacity)).cgColor
            colorOverlayView.alphaValue = 1
            backgroundView.alphaValue = 0.3 // subtle blur underneath
            label.textColor = .white
        } else {
            // System mode: vibrancy only
            colorOverlayView.alphaValue = 0
            backgroundView.alphaValue = CGFloat(opacity)
            label.textColor = .labelColor
        }

        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.stringValue = text
        label.sizeToFit()

        let labelSize = label.frame.size
        let panelWidth = labelSize.width + horizontalPadding * 2
        let panelHeight = labelSize.height + verticalPadding * 2

        let panelSize = CGSize(width: panelWidth, height: panelHeight)

        // Layout subviews by frame
        contentView?.setFrameSize(panelSize)
        backgroundView.frame = CGRect(origin: .zero, size: panelSize)
        colorOverlayView.frame = CGRect(origin: .zero, size: panelSize)
        label.frame = CGRect(
            x: (panelWidth - labelSize.width) / 2,
            y: (panelHeight - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    /// Returns the natural size after the last `updateText` call
    var contentPanelSize: CGSize {
        contentView?.frame.size ?? .zero
    }

    func centerOn(screen: NSScreen) {
        let size = contentPanelSize
        let panelSize = size.width > 0 && size.height > 0 ? size : CGSize(width: 400, height: 160)
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.midY - panelSize.height / 2
        setFrame(CGRect(origin: CGPoint(x: x, y: y), size: panelSize), display: false)
    }
}
