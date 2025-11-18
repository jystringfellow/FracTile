//
//  InternalRect.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/16/25.
//

import Foundation
import CoreGraphics
import AppKit

/// InternalRect represents a rectangle in the application's internal coordinate system.
/// Internal coordinates use a TOP-LEFT origin, which matches AppKit's NSView coordinate system.
/// This abstracts away the bottom-left origin used by NSScreen and Accessibility APIs.
public struct InternalRect: Codable, Equatable, Hashable {
    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
    public let height: CGFloat
    
    /// Create an InternalRect from top-left origin coordinates
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    /// Convert from a bottom-left origin CGRect (like NSScreen.visibleFrame) to internal top-left coordinates
    /// - Parameters:
    ///   - rect: A rectangle in bottom-left origin coordinates
    ///   - screen: The screen containing this rectangle (used for coordinate conversion)
    public init(fromBottomLeft rect: CGRect, screen: NSScreen) {
        self.x = rect.origin.x - screen.frame.origin.x
        self.y = screen.frame.maxY - rect.maxY
        self.width = rect.width
        self.height = rect.height
    }
    
    /// Convert to a bottom-left origin CGRect for use with NSScreen or Accessibility APIs
    /// - Parameter screen: The screen for coordinate conversion
    /// - Returns: A CGRect in bottom-left origin coordinates
    public func cgRect(for screen: NSScreen) -> CGRect {
        return CGRect(
            x: self.x + screen.frame.origin.x,
            y: screen.frame.maxY - self.y - self.height,
            width: self.width,
            height: self.height
        )
    }
    
    /// Convert to a top-left origin CGRect for use with NSView drawing
    /// No screen parameter needed since both use top-left origin
    public var cgRect: CGRect {
        return CGRect(x: self.x, y: self.y, width: self.width, height: self.height)
    }
    
    /// Check if this rectangle contains a point
    public func contains(_ point: InternalPoint) -> Bool {
        return point.x >= self.x &&
               point.x <= self.x + self.width &&
               point.y >= self.y &&
               point.y <= self.y + self.height
    }
    
    /// The center point of this rectangle
    public var center: InternalPoint {
        return InternalPoint(x: self.x + self.width / 2, y: self.y + self.height / 2)
    }
    
    /// Computed properties for convenience
    public var minX: CGFloat { return x }
    public var minY: CGFloat { return y }
    public var maxX: CGFloat { return x + width }
    public var maxY: CGFloat { return y + height }
    public var midX: CGFloat { return x + width / 2 }
    public var midY: CGFloat { return y + height / 2 }
}
