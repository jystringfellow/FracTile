//
//  FractileApp.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import SwiftUI
import AppKit

@main
struct FracTileApp: App {
    @StateObject private var overlayController = OverlayController.shared

    init() {
        startupSequence()
    }

    /// Run lightweight startup tasks in order: avoid duplicates, load defaults, then check accessibility.
    private func startupSequence() {
        checkIfRunning()
        loadLayouts()
        checkAccessibilityOnStartup()
    }

    /// Check for an existing running instance of this app and exit if another instance is active.
    private func checkIfRunning() {
        let notificationName = "FracTile.CheckIfRunning"
        _ = Notification.Name(notificationName)

        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == Bundle.main.bundleIdentifier && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }

        if isRunning {
            let alert = NSAlert()
            alert.window.level = .screenSaver
            alert.window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            alert.alertStyle = .critical
            alert.messageText = "FracTile is already running"
            alert.informativeText = "Another instance of FracTile is already running. This instance will exit."
            alert.addButton(withTitle: "OK")

            alert.window.center()
            alert.window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)

            alert.runModal()

            NSApp.terminate(nil)
            return
        }
    }

    /// Load  layouts (lightweight) so the app has defaults ready. We don't show overlays here.
    private func loadLayouts() {
        let displays = LayoutManager.shared.availableDisplays()
        for display in displays {
            _ = LayoutManager.shared.selectedZoneSet(forDisplayID: display.id)
        }
    }

    var body: some Scene {
        MenuBarExtra("FracTile", image: .init("MenuBarIcon")) {
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
        let zones = overlayController.currentZones
 
        guard !zones.isEmpty else {
            showNoZonesAlert()
            return
        }
 
        let success = SnapController.shared.snapFocusedWindow(to: zones)
 
        if !success {
            showSnapFailedAlert()
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

    /// Check accessibility permission once at app startup and prompt/show instructions if needed.
    private func checkAccessibilityOnStartup() {
        DispatchQueue.main.async {
            AccessibilityHelper.shared.checkAndPromptIfNeeded()
        }
    }
}
