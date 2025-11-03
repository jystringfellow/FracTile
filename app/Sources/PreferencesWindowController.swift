//
//  PreferencesWindowController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import AppKit

// Minimal bridge to present the existing PreferencesViewController (AppKit) from SwiftUI MenuBarExtra.
// PreferencesViewController should remain defined in PreferencesWindowController.swift (AppKit).
final class PreferencesWindowController {
    static let shared = PreferencesWindowController()

    private lazy var prefsWindow: NSWindow = {
        let viewController = PreferencesViewController()
        let window = NSWindow(contentViewController: viewController)
        window.title = "FracTile Preferences"
        window.setContentSize(NSSize(width: 420, height: 180))
        window.styleMask = [.titled, .closable]
        window.center()
        return window
    }()

    private init() {}

    func showPreferences() {
        prefsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
