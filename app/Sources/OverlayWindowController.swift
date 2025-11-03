import Cocoa

final class OverlayWindowController: NSWindowController {

    private lazy var overlayWindow: NSWindow = {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let style: NSWindow.StyleMask = [.borderless]
        let window = NSWindow(contentRect: screenFrame, styleMask: style, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.level = .statusBar
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return window
    }()

    private var contentView: OverlayContentView?

    var isVisible: Bool {
        return window?.isVisible ?? false
    }

    init() {
        super.init(window: nil)
        self.window = overlayWindow
        let overlayContentView = OverlayContentView(frame: overlayWindow.contentView!.bounds)
        overlayContentView.autoresizingMask = [.width, .height]
        overlayWindow.contentView = overlayContentView
        contentView = overlayContentView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showOverlay() {
        guard let window = window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            if let main = NSScreen.main {
                window.setFrame(main.frame, display: true)
            }
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideOverlay() {
        window?.orderOut(nil)
    }

    func updateZones(_ zones: [CGRect]) {
        contentView?.zones = zones
        contentView?.needsDisplay = true
    }
}

final class OverlayContentView: NSView {
    var zones: [CGRect] = []

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.clear.setFill()
        dirtyRect.fill()

        NSColor.black.withAlphaComponent(0.06).setFill()
        dirtyRect.fill()

        if zones.isEmpty {
            drawPlaceholderGrid(in: dirtyRect)
        } else {
            drawZones(in: dirtyRect)
        }
    }

    private func drawPlaceholderGrid(in rect: NSRect) {
        let path = NSBezierPath()
        let columns = 4
        let rows = 3
        let width = bounds.width
        let height = bounds.height
        NSColor.white.withAlphaComponent(0.08).setStroke()
        path.lineWidth = 1.0

        for column in 1..<columns {
            let x = CGFloat(column) * width / CGFloat(columns)
            path.move(to: NSPoint(x: x, y: 0))
            path.line(to: NSPoint(x: x, y: height))
        }
        for row in 1..<rows {
            let y = CGFloat(row) * height / CGFloat(rows)
            path.move(to: NSPoint(x: 0, y: y))
            path.line(to: NSPoint(x: width, y: y))
        }
        path.stroke()
    }

    private func drawZones(in rect: NSRect) {
        for zone in zones {
            let localRect = convertFromScreenRect(zone)
            let rounded = NSBezierPath(roundedRect: localRect, xRadius: 6, yRadius: 6)
            NSColor.systemBlue.withAlphaComponent(0.18).setFill()
            rounded.fill()
            NSColor.systemBlue.withAlphaComponent(0.9).setStroke()
            rounded.lineWidth = 2.0
            rounded.stroke()
        }
    }

    private func convertFromScreenRect(_ screenRect: CGRect) -> CGRect {
        let windowOrigin = window?.frame.origin ?? .zero
        let localX = screenRect.origin.x - windowOrigin.x
        let localY = screenRect.origin.y - windowOrigin.y
        return CGRect(x: localX, y: localY, width: screenRect.width, height: screenRect.height)
    }
}
