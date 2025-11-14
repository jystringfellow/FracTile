//
//  AccessibilityHelper.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Cocoa
import ApplicationServices

final class AccessibilityHelper {
    static let shared = AccessibilityHelper()

    private init() {}

    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestSystemPrompt() -> Bool {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    enum PermissionPromptState {
        case needsPermission
        case openedSettings
    }

    func checkAndPromptIfNeeded() {
        guard !hasAccessibilityPermission() else { return }

        DispatchQueue.main.async {
            self.presentAlert(state: .needsPermission)
        }
    }

    private func presentAlert(state: PermissionPromptState) {
        let alert = NSAlert()
        alert.icon = NSImage(named: "AppIcon")
        alert.messageText = "Accessibility permission required"

        switch state {

        case .openedSettings:
            alert.informativeText = """
            System Settings was opened.

            After granting Accessibility access to FracTile, click
            Restart FracTile to apply the change, or Quit to exit.
            """
            alert.addButton(withTitle: "Restart FracTile")
            alert.addButton(withTitle: "Quit")

        case .needsPermission:
            alert.informativeText = """
            FracTile needs Accessibility permission to move and resize windows.

            1) Click "Open Accessibility Settings".
            2) Add or enable "FracTile" in Privacy & Security → Accessibility.
            3) Return here and click Restart FracTile when done.
            """
            alert.addButton(withTitle: "Open Accessibility Settings")
            alert.addButton(withTitle: "Quit")
        }

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            handlePrimaryButton(for: state)

        case .alertSecondButtonReturn:
            NSApp.terminate(nil)

        default:
            return
        }
    }

    private func handlePrimaryButton(for state: PermissionPromptState) {
        switch state {
        case .openedSettings:
            self.performRestart()
        case .needsPermission:
            openAccessibilitySettings()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.presentAlert(state: .openedSettings)
            }
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
        }
    }

    private func performRestart() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1; open \"\(Bundle.main.bundlePath)\""]
        do {
            try task.run()
        } catch {
            NSLog("Failed to launch restart helper: \(error)")
        }

        NSApp.terminate(nil)
    }
}
