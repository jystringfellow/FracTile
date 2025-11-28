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
        
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.handleMouseDown(event)
        }
        
        mouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            self?.handleMouseDragged(event)
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            self?.handleMouseUp(event)
        }
        
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
        isDragging = true
        highlightedZoneIndices.removeAll()
        
        updateOverlayVisibility()
    }
    
    private func handleMouseDragged(_ event: NSEvent) {
        guard isDragging, let screen = overlayScreen else { return }
        
        let mouseLocationBottomLeft = NSEvent.mouseLocation
        let internalPoint = InternalPoint(fromBottomLeft: mouseLocationBottomLeft, screen: screen)

        let zonesUnderCursor = getZonesUnderCursor(at: internalPoint)

        let multiZoneActive = isMultiZoneKeyHeld()
        
        var newHighlightedIndices: Set<Int>
        
        if multiZoneActive {
            let accumulatedIndices = highlightedZoneIndices.union(zonesUnderCursor)
            
            let unionRect = computeUnionRect(forIndices: accumulatedIndices)
            
            if let bounds = unionRect {
                var filledIndices: Set<Int> = []
                for (index, zone) in activeZones.enumerated() {
                    if bounds.intersects(zone.cgRect) {
                        filledIndices.insert(index)
                    }
                }
                newHighlightedIndices = filledIndices
            } else {
                newHighlightedIndices = accumulatedIndices
            }
        } else {
            if let singleIndex = zonesUnderCursor.first {
                newHighlightedIndices = [singleIndex]
            } else {
                newHighlightedIndices = []
            }
        }

        updateHighlightedZones(newHighlightedIndices)
    }

    private func handleMouseUp(_ event: NSEvent) {
        guard isDragging else { return }
        
        let shouldSnap = isSnapKeyHeld() && !highlightedZoneIndices.isEmpty
        
        if shouldSnap {
            let releasePointBL = NSEvent.mouseLocation
            var targetWindow: AXUIElement? = WindowControllerAX.getFocusedWindow()
            if targetWindow == nil {
                if let screen = overlayScreen {
                    let internalPoint = InternalPoint(fromBottomLeft: releasePointBL, screen: screen)
                    let axPoint = internalPoint.accessibilityPoint(for: screen)
                    targetWindow = WindowControllerAX.getWindowUnderPoint(axPoint)
                } else {
                    targetWindow = WindowControllerAX.getWindowUnderPoint(releasePointBL)
                }
            }

            if let windowElement = targetWindow, !highlightedZoneIndices.isEmpty, let screen = overlayScreen {
                if let unionRect = computeUnionRect(forIndices: highlightedZoneIndices) {
                    let internalZone = InternalRect(x: unionRect.origin.x, y: unionRect.origin.y, width: unionRect.width, height: unionRect.height)
                    let finalRect = internalZone.accessibilityFrame(for: screen)
                    _ = WindowControllerAX.setWindowFrame(windowElement, frame: finalRect)
                }
            }
        }
        
        isDragging = false
        highlightedZoneIndices.removeAll()
        activeZones.removeAll()
        overlayScreen = nil
        
        DispatchQueue.main.async {
            OverlayController.shared.hideOverlay()
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        guard isDragging else { return }
        
        if !isMultiZoneKeyHeld() {
            if let screen = overlayScreen {
                let mouseLocationBottomLeft = NSEvent.mouseLocation
                let internalPoint = InternalPoint(fromBottomLeft: mouseLocationBottomLeft, screen: screen)
                
                let zonesUnderCursor = getZonesUnderCursor(at: internalPoint)
                
                let newIndices: Set<Int>
                if let singleIndex = zonesUnderCursor.first {
                    newIndices = [singleIndex]
                } else {
                    newIndices = []
                }
                
                updateHighlightedZones(newIndices)
            }
        }
        
        updateOverlayVisibility()
    }
    
    private func updateOverlayVisibility() {
        let shouldShow = isDragging && isSnapKeyHeld()
        
        if shouldShow && !OverlayController.shared.isVisible {
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
            DispatchQueue.main.async {
                OverlayController.shared.hideOverlay()
            }
            highlightedZoneIndices.removeAll()
        }
    }
    
    private func updateHighlightedZones(_ newIndices: Set<Int>) {
        if newIndices != highlightedZoneIndices {
            highlightedZoneIndices = newIndices
            let sortedIndices = highlightedZoneIndices.sorted()
            DispatchQueue.main.async {
                OverlayController.shared.highlightZones(sortedIndices)
            }
        }
    }

    private func getZonesUnderCursor(at point: InternalPoint) -> Set<Int> {
        var zonesUnderCursor: Set<Int> = []
        for (index, zoneRect) in activeZones.enumerated() {
            if zoneRect.contains(point) {
                zonesUnderCursor.insert(index)
            }
        }
        return zonesUnderCursor
    }

    private func isSnapKeyHeld() -> Bool {
        let requiredFlags = flagsForPersistedKey(UserDefaults.standard.string(forKey: "FracTile.SnapKey") ?? "Shift")
        let currentFlags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return currentFlags.contains(requiredFlags)
    }

    private func isMultiZoneKeyHeld() -> Bool {
        let multiZoneFlags = flagsForPersistedKey(UserDefaults.standard.string(forKey: "FracTile.MultiZoneKey") ?? "Command")
        let currentFlags = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return currentFlags.contains(multiZoneFlags)
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
    
    private func computeUnionRect(forIndices indices: Set<Int>) -> CGRect? {
        var unionRect: CGRect?
        for index in indices {
            guard index >= 0 && index < activeZones.count else { continue }
            let zone = activeZones[index]
            if unionRect == nil {
                unionRect = zone.cgRect
            } else {
                unionRect = unionRect?.union(zone.cgRect)
            }
        }
        return unionRect
    }
}
