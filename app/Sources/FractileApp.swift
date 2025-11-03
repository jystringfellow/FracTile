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
}
