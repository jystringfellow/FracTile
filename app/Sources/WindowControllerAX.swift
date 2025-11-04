//
//  WindowControllerAX.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/3/25.
//

import Cocoa
import ApplicationServices

/// WindowControllerAX provides Accessibility API helpers for window manipulation.
/// Responsibilities:
/// - Check if Accessibility permission is granted
/// - Get the currently focused window
/// - Read and set window position and size
public final class WindowControllerAX {
    
    /// Check if the app has Accessibility permission
    public static func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Get the AXUIElement for the currently focused window
    /// Returns nil if no window is focused or if permission is denied
    public static func getFocusedWindow() -> AXUIElement? {
        guard hasAccessibilityPermission() else {
            return nil
        }
        
        // Get the frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let pid = frontmostApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        // Get focused window from the application
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        if result == .success, let window = focusedWindow {
            return (window as AXUIElement)
        }
        
        return nil
    }
    
    /// Get the frame (position and size) of a window
    /// Returns nil if the window doesn't have position/size attributes
    public static func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        guard posResult == .success, sizeResult == .success,
              let positionValue = positionValue as? AXValue,
              let sizeValue = sizeValue as? AXValue else {
            return nil
        }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(positionValue, .cgPoint, &position)
        AXValueGetValue(sizeValue, .cgSize, &size)
        
        return CGRect(origin: position, size: size)
    }
    
    /// Set the frame (position and size) of a window
    /// Returns true if successful, false otherwise
    @discardableResult
    public static func setWindowFrame(_ window: AXUIElement, frame: CGRect) -> Bool {
        var newPosition = frame.origin
        var newSize = frame.size
        
        // Create AXValue objects for position and size
        guard let positionValue = AXValueCreate(.cgPoint, &newPosition),
              let sizeValue = AXValueCreate(.cgSize, &newSize) else {
            return false
        }
        
        // Set position
        let posResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        // Set size
        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        
        return posResult == .success && sizeResult == .success
    }
}
