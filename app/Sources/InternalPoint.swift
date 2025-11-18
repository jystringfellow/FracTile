//
//  InternalPoint.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/16/25.
//

import Foundation
import CoreGraphics
import AppKit

/// InternalPoint represents a point in the application's internal coordinate system.
/// Internal coordinates use a TOP-LEFT origin, which matches AppKit's NSView coordinate system.
/// This abstracts away the bottom-left origin used by NSScreen and NSEvent.
public struct InternalPoint: Codable, Equatable, Hashable {
    public let x: CGFloat
    public let y: CGFloat
    
    /// Create an InternalPoint from top-left origin coordinates
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    /// Convert from a bottom-left origin CGPoint (like NSEvent.mouseLocation) to internal top-left coordinates
    /// - Parameters:
    ///   - point: A point in bottom-left origin coordinates
    ///   - screen: The screen containing this point (used for coordinate conversion)
    public init(fromBottomLeft point: CGPoint, screen: NSScreen) {
        self.x = point.x - screen.frame.origin.x
        self.y = screen.frame.maxY - point.y
    }
    
    /// Convert to a bottom-left origin CGPoint for use with NSEvent, NSScreen, or Accessibility APIs
    /// - Parameter screen: The screen for coordinate conversion
    /// - Returns: A CGPoint in bottom-left origin coordinates
    public func cgPoint(for screen: NSScreen) -> CGPoint {
        return CGPoint(
            x: self.x + screen.frame.origin.x,
            y: screen.frame.maxY - self.y
        )
    }
    
    /// Convert to a top-left origin CGPoint for use with NSView drawing
    /// No screen parameter needed since both use top-left origin
    public var cgPoint: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
    
    /// Calculate distance to another point
    public func distance(to other: InternalPoint) -> CGFloat {
        let dx = self.x - other.x
        let dy = self.y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}
