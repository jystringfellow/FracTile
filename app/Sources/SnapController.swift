//
//  SnapController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/3/25.
//

import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

/// SnapController handles snapping focused windows into zones.
/// Uses overlap >50% or nearest-center heuristic to choose the best zone.
public final class SnapController {
    public static let shared = SnapController()
    
    private init() {}
    
    /// Snap the currently focused window to the best matching zone
    /// - Parameters:
    ///   - zones: Array of zone rectangles in internal (top-left) coordinates
    ///   - screen: The screen containing these zones
    /// - Returns: true if successful, false if no window or permission denied
    @discardableResult
    public func snapFocusedWindow(to zones: [InternalRect], screen: NSScreen) -> Bool {
        guard !zones.isEmpty else {
            return false
        }
        
        guard WindowControllerAX.hasAccessibilityPermission() else {
            return false
        }
        
        guard let focusedWindow = WindowControllerAX.getFocusedWindow() else {
            return false
        }
        
        guard let currentFrameAXTopLeft = WindowControllerAX.getWindowFrame(focusedWindow) else {
            return false
        }
        
        // Convert window frame from AX global top-left to internal coordinates
        let currentFrame = InternalRect(fromAccessibility: currentFrameAXTopLeft, screen: screen)
        
        // Find the best zone for this window
        guard let bestZone = findBestZone(for: currentFrame, in: zones) else {
            return false
        }
        
        // Convert best zone to AX global top-left coordinates for Accessibility API
        let bestZoneAXFrame = bestZone.accessibilityFrame(for: screen)
        
        // Move the window to the best zone
        return WindowControllerAX.setWindowFrame(focusedWindow, frame: bestZoneAXFrame)
    }
    
    /// Find the best zone for a window using overlap >50% or nearest-center heuristic
    /// - Parameters:
    ///   - windowFrame: The current window frame in internal coordinates
    ///   - zones: Array of available zones in internal coordinates
    /// - Returns: The best matching zone, or nil if none found
    private func findBestZone(for windowFrame: InternalRect, in zones: [InternalRect]) -> InternalRect? {
        guard !zones.isEmpty else {
            return nil
        }
        
        // First, try to find a zone with >50% overlap
        var bestOverlapZone: InternalRect?
        var maxOverlapArea: CGFloat = 0
        
        for zone in zones {
            // Calculate intersection in internal coordinate space
            let intersectionX = max(windowFrame.minX, zone.minX)
            let intersectionY = max(windowFrame.minY, zone.minY)
            let intersectionMaxX = min(windowFrame.maxX, zone.maxX)
            let intersectionMaxY = min(windowFrame.maxY, zone.maxY)
            
            if intersectionX < intersectionMaxX && intersectionY < intersectionMaxY {
                let overlapArea = (intersectionMaxX - intersectionX) * (intersectionMaxY - intersectionY)
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
        let windowCenter = windowFrame.center
        
        var nearestZone: InternalRect?
        var minDistance: CGFloat = .infinity
        
        for zone in zones {
            let distance = windowCenter.distance(to: zone.center)
            
            if distance < minDistance {
                minDistance = distance
                nearestZone = zone
            }
        }
        
        return nearestZone
    }
}
