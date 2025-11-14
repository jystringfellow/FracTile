//
//  EventMonitor.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/3/25.
//

import Cocoa

/// EventMonitor provides helper methods to check modifier key states
public final class EventMonitor {
    
    /// Check if the Command key is currently pressed
    public static func isCommandKeyPressed() -> Bool {
        return NSEvent.modifierFlags.contains(.command)
    }
    
    /// Check if the Shift key is currently pressed
    public static func isShiftKeyPressed() -> Bool {
        return NSEvent.modifierFlags.contains(.shift)
    }
    
    /// Check if the Option key is currently pressed
    public static func isOptionKeyPressed() -> Bool {
        return NSEvent.modifierFlags.contains(.option)
    }
    
    /// Check if the Control key is currently pressed
    public static func isControlKeyPressed() -> Bool {
        return NSEvent.modifierFlags.contains(.control)
    }
    
    /// Get current modifier flags
    public static func currentModifierFlags() -> NSEvent.ModifierFlags {
        return NSEvent.modifierFlags
    }
}
