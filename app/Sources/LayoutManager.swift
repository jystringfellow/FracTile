//
//  LayoutManager.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/3/25.
//

import Foundation
import Cocoa
import CoreGraphics

// LayoutManager.swift
// Responsible for persisting per-display layout choices and producing preview zone rects.
// Uses DefaultLayouts and ZoneEngine to generate zones, and calls OverlayController to render previews.

public final class LayoutManager {
    public static let shared = LayoutManager()

    private let userDefaults = UserDefaults.standard
    // Key prefix; full key will be "FracTile.SelectedLayout.<displayID>"
    private let defaultsPrefix = "FracTile.SelectedLayout"

    private init() {}

    public func availableDisplays() -> [(id: Int, name: String, screen: NSScreen)] {
        var results: [(Int, String, NSScreen)] = []
        for screen in NSScreen.screens {
            if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                let displayID = number.intValue
                let name = displayName(for: screen)
                results.append((displayID, name, screen))
            } else {
                // fallback: use index-based id
                let idx = NSScreen.screens.firstIndex(of: screen) ?? 0
                results.append((idx, "Display \(idx + 1)", screen))
            }
        }
        return results
    }

    private func displayName(for screen: NSScreen) -> String {
        let size = screen.frame.size
        let name = screen.localizedName
        return "\(name) (\(Int(size.width))×\(Int(size.height)))"
    }

    // Persist selected ZoneSet id for a display
    public func setSelectedLayout(_ layoutId: String, forDisplayID displayID: Int) {
        let key = userDefaultsKey(for: displayID)
        userDefaults.set(layoutId, forKey: key)
        userDefaults.synchronize()
        // Post notification so UI and runtime can react
        NotificationCenter.default.post(name: .selectedLayoutDidChange, object: nil, userInfo: ["displayID": displayID, "layoutId": layoutId])
    }

    // Load selected ZoneSet id for a display; if none, return nil
    public func selectedLayoutId(forDisplayID displayID: Int) -> String? {
        let key = userDefaultsKey(for: displayID)
        return userDefaults.string(forKey: key)
    }

    // Convenience: return the ZoneSet (from DefaultLayouts or saved custom sets) for a display
    // For now, we only ship DefaultLayouts; later extend to user-saved layouts
    public func selectedZoneSet(forDisplayID displayID: Int) -> ZoneSet {
        if let layoutId = selectedLayoutId(forDisplayID: displayID),
           let zoneSet = DefaultLayouts.all.first(where: { $0.id == layoutId || $0.name == layoutId }) {
            return zoneSet
        }
        // fallback default: 2x2
        return DefaultLayouts.zoneSet(named: "Grid 2×2") ?? DefaultLayouts.all.first!
    }

    private func userDefaultsKey(for displayID: Int) -> String {
        return "\(defaultsPrefix).\(displayID)"
    }

    // Preview a layout on a specific NSScreen by generating zones and calling overlay
    // This uses ZoneEngine.calculateGridZones and OverlayController.shared.updateZones(...)
    public func preview(zoneSet: ZoneSet, on screen: NSScreen) {
        // Extract workArea: prefer visibleFrame (excludes dock/menu bar).
        let workArea = screen.visibleFrame
        switch zoneSet.type {
        case .grid, .priorityGrid, .rows, .columns, .focus:
            guard let grid = zoneSet.gridInfo else { return }
            let zones = ZoneEngine.calculateGridZones(workArea: workArea, on: screen, gridInfo: grid, spacing: zoneSet.spacing)
            // Extract InternalRect array from zones
            let internalRects = zones.map { $0.rect }
            DispatchQueue.main.async {
                OverlayController.shared.updateZones(internalRects, screen: screen)
                OverlayController.shared.showOverlay()
            }
        case .canvas:
            // For canvas layouts scale saved canvas zones to current screen size
            if let canvas = zoneSet.canvasInfo {
                // Convert bottom-left workArea to internal coordinates for canvas layout
                let internalWorkArea = InternalRect(fromBottomLeft: workArea, screen: screen)
                let internalRects = canvas.zones.map { canvasZone -> InternalRect in
                    let scaleX = internalWorkArea.width / CGFloat(max(1, canvas.lastWorkAreaWidth))
                    let scaleY = internalWorkArea.height / CGFloat(max(1, canvas.lastWorkAreaHeight))
                    let zoneX = internalWorkArea.x + CGFloat(canvasZone.x) * scaleX
                    let zoneY = internalWorkArea.y + CGFloat(canvasZone.y) * scaleY
                    let zoneWidth = CGFloat(canvasZone.width) * scaleX
                    let zoneHeight = CGFloat(canvasZone.height) * scaleY
                    return InternalRect(x: zoneX, y: zoneY, width: zoneWidth, height: zoneHeight)
                }
                DispatchQueue.main.async {
                    OverlayController.shared.updateZones(internalRects, screen: screen)
                    OverlayController.shared.showOverlay()
                }
            }
        }
    }
}

// Notification name when a selection changes (so UI or runtime can react)
extension Notification.Name {
    static let selectedLayoutDidChange = Notification.Name("FracTile.SelectedLayoutDidChange")
}
