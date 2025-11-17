//
//  SnapController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/3/25.
//

import Foundation
import CoreGraphics
import ApplicationServices

/// SnapController handles snapping focused windows into zones.
/// Uses overlap >50% or nearest-center heuristic to choose the best zone.
public final class SnapController {
    public static let shared = SnapController()
    
    private init() {}
    
    /// Snap the currently focused window to the best matching zone
    /// - Parameter zones: Array of zone rectangles to snap to
    /// - Returns: true if successful, false if no window or permission denied
    @discardableResult
    public func snapFocusedWindow(to zones: [CGRect]) -> Bool {
        guard !zones.isEmpty else {
            return false
        }
        
        guard WindowControllerAX.hasAccessibilityPermission() else {
            return false
        }
        
        guard let focusedWindow = WindowControllerAX.getFocusedWindow() else {
            return false
        }
        
        guard let currentFrame = WindowControllerAX.getWindowFrame(focusedWindow) else {
            return false
        }
        
        // Find the best zone for this window
        guard let bestZone = findBestZone(for: currentFrame, in: zones) else {
            return false
        }
        
        // Move the window to the best zone
        return WindowControllerAX.setWindowFrame(focusedWindow, frame: bestZone)
    }
    
    /// Find the best zone for a window using overlap >50% or nearest-center heuristic
    /// - Parameters:
    ///   - windowFrame: The current window frame
    ///   - zones: Array of available zones
    /// - Returns: The best matching zone, or nil if none found
    private func findBestZone(for windowFrame: CGRect, in zones: [CGRect]) -> CGRect? {
        guard !zones.isEmpty else {
            return nil
        }
        
        // First, try to find a zone with >50% overlap
        var bestOverlapZone: CGRect?
        var maxOverlapArea: CGFloat = 0
        
        for zone in zones {
            let intersection = windowFrame.intersection(zone)
            if !intersection.isNull {
                let overlapArea = intersection.width * intersection.height
                let windowArea = windowFrame.width * windowFrame.height
                let overlapRatio = overlapArea / windowArea
                
                if overlapRatio > 0.5 && overlapArea > maxOverlapArea {
                    maxOverlapArea = overlapArea
                    bestOverlapZone = zone
                }
            }
        }
        
        if let overlapZone = bestOverlapZone {
            return overlapZone
        }
        
        // If no zone has >50% overlap, find the zone with the nearest center
        let windowCenter = CGPoint(
            x: windowFrame.origin.x + windowFrame.width / 2,
            y: windowFrame.origin.y + windowFrame.height / 2
        )
        
        var nearestZone: CGRect?
        var minDistance: CGFloat = .infinity
        
        for zone in zones {
            let zoneCenter = CGPoint(
                x: zone.origin.x + zone.width / 2,
                y: zone.origin.y + zone.height / 2
            )
            
            let deltaX = windowCenter.x - zoneCenter.x
            let deltaY = windowCenter.y - zoneCenter.y
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
            
            if distance < minDistance {
                minDistance = distance
                nearestZone = zone
            }
        }
        
        return nearestZone
    }
}
