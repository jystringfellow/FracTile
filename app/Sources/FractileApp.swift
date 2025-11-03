//
//  FractileApp.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import SwiftUI
import AppKit

@main
struct MenuBarExampleApp: App {
    @StateObject private var overlayController = OverlayController.shared

    var body: some Scene {
        MenuBarExtra("FracTile", systemImage: "square.grid.2x2") {
            VStack(spacing: 12) {
                Text("FracTile")
                    .font(.headline)

                HStack {
                    Button(action: {
                        overlayController.toggleOverlay()
                    }, label: {
                        Text(overlayController.isVisible ? "Hide Overlay" : "Show Overlay")
                    })
                    .keyboardShortcut("o", modifiers: [.command])
                }

                Button("Open Editor") {
                    EditorWindowController.shared.showEditor()
                }
                .keyboardShortcut("e", modifiers: [.command])

                Button("Preferences…") {
                    PreferencesWindowController.shared.showPreferences()
                }
                .keyboardShortcut(",", modifiers: [.command])
                
                Divider()
                
                Button("Snap Focused Window") {
                    snapFocusedWindow()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("Quit FracTile") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
            .frame(width: 320)
            .padding()
        }
        .menuBarExtraStyle(.window)
    }
    
    /// Snap the focused window to a zone in the current overlay
    private func snapFocusedWindow() {
        // Check for Accessibility permission first
        guard WindowControllerAX.hasAccessibilityPermission() else {
            showAccessibilityAlert()
            return
        }
        
        // Get current zones from the overlay
        let zones = overlayController.currentZones
        
        guard !zones.isEmpty else {
            showNoZonesAlert()
            return
        }
        
        // Attempt to snap the focused window
        let success = SnapController.shared.snapFocusedWindow(to: zones)
        
        if !success {
            showSnapFailedAlert()
        }
    }
    
    /// Show an alert when Accessibility permission is not granted
    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            FracTile needs Accessibility permission to move and resize windows.
            
            Please grant permission in:
            System Settings → Privacy & Security → Accessibility
            
            Add FracTile to the list and enable it.
            """
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    /// Show an alert when no zones are available
    private func showNoZonesAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "No Zones Available"
            alert.informativeText = """
            Please preview a layout first using:
            Preferences → Select a display → Choose a layout → Preview
            """
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    /// Show an alert when snapping fails
    private func showSnapFailedAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Snap Failed"
            alert.informativeText = """
            Could not snap the focused window. Please ensure:
            - A window is currently focused
            - The window can be moved and resized
            """
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
