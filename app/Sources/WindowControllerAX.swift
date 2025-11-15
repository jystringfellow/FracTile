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
    /// - Parameter prompt: When true, will request the system prompt that suggests enabling Accessibility for this app.
    public static func hasAccessibilityPermission(prompt: Bool = false) -> Bool {
        if prompt {
            return AccessibilityHelper.shared.requestSystemPrompt()
        } else {
            return AccessibilityHelper.shared.hasAccessibilityPermission()
        }
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
            return unsafeBitCast(window, to: AXUIElement.self)
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
              let positionValue = unsafeBitCast(positionValue, to: AXValue?.self),
              let sizeValue = unsafeBitCast(sizeValue, to: AXValue?.self) else {
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
    
    /// Get the AXUIElement for the window under a screen point (global coordinates)
    public static func getWindowUnderPoint(_ point: CGPoint) -> AXUIElement? {
        guard hasAccessibilityPermission() else { return nil }

        let system = AXUIElementCreateSystemWide()
        var element: AXUIElement? = nil
        let result = AXUIElementCopyElementAtPosition(system, Float(point.x), Float(point.y), &element)
        if result != AXError.success || element == nil { return nil }

        let elementRef = element!

        // Try to get the window attribute for the element
        var windowValue: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(elementRef, kAXWindowAttribute as CFString, &windowValue)
        if windowResult == AXError.success, let windowValue = windowValue {
            return unsafeBitCast(windowValue, to: AXUIElement.self)
        }

        // If there's no explicit window attribute, return the element itself
        return elementRef
    }
}
