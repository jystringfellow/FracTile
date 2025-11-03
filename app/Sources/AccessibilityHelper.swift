//
//  AccessibilityHelper.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Cocoa
import ApplicationServices

struct AccessibilityHelper {
    static func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }

    static func checkAndPromptIfNeeded() {
        if !isAccessibilityEnabled() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let alert = NSAlert()
                alert.messageText = "Accessibility permission required"
                alert.informativeText = """
                To allow FracTile to move and resize other app windows, please grant Accessibility permission:
                1) Open System Settings → Privacy & Security → Accessibility
                2) Add this app and enable it.
                After granting permission, restart the app.
                """
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Continue without permission")
                let resp = alert.runModal()
                if resp == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
