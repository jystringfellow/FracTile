import Cocoa
import Foundation

/// DragSnapController
/// Watches global mouse events. When the user presses the configured snap key and begins a left-mouse drag,
/// the controller computes the zones for the display under the cursor, shows the overlay on that screen,
/// highlights zones while dragging (supports multi-zone selection via Multi-zone key), and snaps the window on mouse-up.
final class DragSnapController {
    static let shared = DragSnapController()

    private var mouseDownMonitor: Any?
    private var mouseDraggedMonitor: Any?
    private var mouseUpMonitor: Any?
    private var flagsChangedMonitor: Any?

    private var isDragging = false
    private var activeZones: [InternalRect] = []
    private var highlightedZoneIndices: Set<Int> = []
    private var overlayScreen: NSScreen?

    private init() {}

    func start() {
        stop()
        
        // Monitor all mouse events
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.handleMouseDown(event)
        }
        
        mouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            self?.handleMouseDragged(event)
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            self?.handleMouseUp(event)
        }
        
        // Monitor modifier key changes
        flagsChangedMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
    }

    func stop() {
        if let monitor = mouseDownMonitor { NSEvent.removeMonitor(monitor); mouseDownMonitor = nil }
        if let monitor = mouseDraggedMonitor { NSEvent.removeMonitor(monitor); mouseDraggedMonitor = nil }
        if let monitor = mouseUpMonitor { NSEvent.removeMonitor(monitor); mouseUpMonitor = nil }
        if let monitor = flagsChangedMonitor { NSEvent.removeMonitor(monitor); flagsChangedMonitor = nil }
        isDragging = false
        highlightedZoneIndices.removeAll()
        activeZones.removeAll()
        overlayScreen = nil
        DispatchQueue.main.async {
            OverlayController.shared.hideOverlay()
        }
    }

    private func handleMouseDown(_ event: NSEvent) {
        // Start tracking drag
        isDragging = true
        highlightedZoneIndices.removeAll()
        
        // Check if we should show overlay
        updateOverlayVisibility()
    }
    
    private func handleMouseDragged(_ event: NSEvent) {
        guard isDragging, let screen = overlayScreen else { return }
        
        // Convert mouse location from bottom-left origin to internal top-left coordinates
        let mouseLocationBottomLeft = NSEvent.mouseLocation
        let internalPoint = InternalPoint(fromBottomLeft: mouseLocationBottomLeft, screen: screen)

        var newHighlightedIndices: Set<Int> = []
        for (index, zoneRect) in activeZones.enumerated() {
            if zoneRect.contains(internalPoint) {
                newHighlightedIndices.insert(index)
            }
        }

        // Respect multi-zone modifier: if it's not held, reduce to a single zone
        let multiZoneFlags = flagsForPersistedKey(UserDefaults.standard.string(forKey: "FracTile.MultiZoneKey") ?? "Command")
        let multiZoneActive = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(multiZoneFlags)
        if !multiZoneActive, let singleIndex = newHighlightedIndices.first {
            newHighlightedIndices = [singleIndex]
        }

        if newHighlightedIndices != highlightedZoneIndices {
            highlightedZoneIndices = newHighlightedIndices
            let sortedIndices = highlightedZoneIndices.sorted()
            DispatchQueue.main.async {
                OverlayController.shared.highlightZones(sortedIndices)
            }
        }
    }

    private func handleMouseUp(_ event: NSEvent) {
        guard isDragging else { return }
        
        // Check if we should snap based on current state
        let shouldSnap = isSnapKeyHeld() && !highlightedZoneIndices.isEmpty
        
        if shouldSnap {
            // Determine final zones
            let finalIndices = highlightedZoneIndices.sorted()
            
            // Find the window to snap
            let releasePoint = NSEvent.mouseLocation
            var targetWindow: AXUIElement? = WindowControllerAX.getFocusedWindow()
            if targetWindow == nil {
                targetWindow = WindowControllerAX.getWindowUnderPoint(releasePoint)
            }

            if let windowElement = targetWindow, !finalIndices.isEmpty, let screen = overlayScreen {
                // Convert InternalRect to bottom-left CGRect for Accessibility API
                let targetInternalRect = activeZones[finalIndices[0]]
                let targetRect = targetInternalRect.cgRect(for: screen)
                _ = WindowControllerAX.setWindowFrame(windowElement, frame: targetRect)
            }
        }
        
        // Cleanup
        isDragging = false
        highlightedZoneIndices.removeAll()
        activeZones.removeAll()
        overlayScreen = nil
        
        DispatchQueue.main.async {
            OverlayController.shared.hideOverlay()
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        // Only care about flags changes during drag
        guard isDragging else { return }
        updateOverlayVisibility()
    }
    
    private func updateOverlayVisibility() {
        let shouldShow = isDragging && isSnapKeyHeld()
        
        if shouldShow && !OverlayController.shared.isVisible {
            // Need to show overlay - compute zones if not already done
            if activeZones.isEmpty {
                let globalPoint = NSEvent.mouseLocation
                guard let screenForPoint = NSScreen.screens.first(where: { $0.frame.contains(globalPoint) }) else { return }
                overlayScreen = screenForPoint
                
                if let displayId = LayoutManager.shared.availableDisplays().first(where: { $0.screen == screenForPoint })?.id {
                    let zoneSet = LayoutManager.shared.selectedZoneSet(forDisplayID: displayId)
                    if let gridInfo = zoneSet.gridInfo {
                        let workArea = screenForPoint.visibleFrame
                        let computedZones = ZoneEngine.calculateGridZones(workArea: workArea, on: screenForPoint, gridInfo: gridInfo, spacing: zoneSet.spacing)
                        activeZones = computedZones.map { $0.rect }
                    }
                }
            }
            
            if !activeZones.isEmpty, let screen = overlayScreen {
                DispatchQueue.main.async {
                    OverlayController.shared.updateZones(self.activeZones, screen: screen)
                    OverlayController.shared.showOverlay(on: screen)
                }
            }
        } else if !shouldShow && OverlayController.shared.isVisible {
            // Hide overlay
            DispatchQueue.main.async {
                OverlayController.shared.hideOverlay()
            }
            highlightedZoneIndices.removeAll()
        }
    }
    
    private func isSnapKeyHeld() -> Bool {
        let requiredFlags = flagsForPersistedKey(UserDefaults.standard.string(forKey: "FracTile.SnapKey") ?? "Shift")
        let currentFlags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return currentFlags.contains(requiredFlags)
    }

    private func nearestZone(to point: InternalPoint) -> InternalRect? {
        var nearestRect: InternalRect?
        var minDistance: CGFloat = .infinity
        for zoneRect in activeZones {
            let center = zoneRect.center
            let distance = point.distance(to: center)
            if distance < minDistance {
                minDistance = distance
                nearestRect = zoneRect
            }
        }
        return nearestRect
    }

    private func flagsForPersistedKey(_ name: String) -> NSEvent.ModifierFlags {
        switch name.lowercased() {
        case "command": return .command
        case "shift": return .shift
        case "option": return .option
        case "control": return .control
        default: return .shift
        }
    }
}
