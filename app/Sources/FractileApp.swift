//
//  FractileApp.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import SwiftUI
import AppKit

// SwiftUI MenuBarExtra-based menu bar app (macOS 13+).
// This is an alternative to the AppDelegate / NSStatusItem approach.
// Use this if you want a SwiftUI entrypoint and a built-in menu-bar popover.
// Note: MenuBarExtra requires macOS 13+. If you need earlier macOS support, keep the AppKit AppDelegate approach.

@main
struct MenuBarExampleApp: App {
    // Keep a reference to the shared overlay controller (AppKit)
    @StateObject private var overlayController = OverlayController.shared

    var body: some Scene {
        // MenuBarExtra is the SwiftUI menu-bar API equivalent to NSStatusItem
        MenuBarExtra("FracTile", systemImage: "square.grid.3x3") {
            // Content shown inside the popover
            VStack(spacing: 12) {
                Text("FracTile")
                    .font(.headline)

                HStack {
                    Button(action: {
                        // Toggle overlay (uses AppKit controller under the hood)
                        overlayController.toggleOverlay()
                    }) {
                        Text(overlayController.isVisible ? "Hide Overlay" : "Show Overlay")
                    }
                    .keyboardShortcut("o", modifiers: [.command])
                }

                Button("Open Editor") {
                    // Open the editor popover/window (we can present a NSWindow or a SwiftUI sheet)
                    EditorWindowController.shared.showEditor()
                }
                .keyboardShortcut("e", modifiers: [.command])

                Button("Preferences…") {
                    PreferencesWindowController.shared.showPreferences()
                }
                .keyboardShortcut(",", modifiers: [.command])

                Divider()

                Button("Quit FracTile") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
            .frame(width: 320)
            .padding()
        }
        // Use the .window style so the popover behaves as a small window-like popover
        .menuBarExtraStyle(.window)
    }
}
