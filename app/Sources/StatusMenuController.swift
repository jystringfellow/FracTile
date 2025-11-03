//
//  StatusMenuController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Cocoa

final class StatusMenuController: NSObject {
    // The NSStatusItem that appears in the system status bar
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()

    override init() {
        super.init()
    }

    /// Create and configure the status bar item and its menu
    func setupStatusItem() {
        print("StatusMenuController.setupStatusItem()")

        // Create a status item with variable length so it can show an icon and text if desired
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use a simple SF Symbol-based image if available, otherwise fall back to text
            if #available(macOS 11.0, *) {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                if let image = NSImage(systemSymbolName: "rectangle.split.3x1", accessibilityDescription: "FracTile")?.withSymbolConfiguration(config) {
                    image.isTemplate = true // support dark mode
                    button.image = image
                } else {
                    button.title = "FracTile"
                }
            } else {
                button.title = "FracTile"
            }
            button.target = self
            button.action = #selector(toggleMenu(_:))
        }

        buildMenu()
        statusItem?.menu = menu
    }

    private func buildMenu() {
        menu.removeAllItems()

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences(_:)), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit FracTile", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func toggleMenu(_ sender: Any?) {
        // If the menu is attached to the status item, clicking the button will automatically show it.
        // This method exists so the button has an action; we don't need to implement anything else here.
    }

    @objc private func openPreferences(_ sender: Any?) {
        // Try to locate and show the Preferences window controller if it exists in the app.
        // Use NSApp to activate the app first.
        NSApp.activate(ignoringOtherApps: true)

        // PreferencesWindowController exists in the project; attempt to open its window.
        if NSApp.delegate is NSObject {
            // If there's a shared Preferences window controller in the app, the app can expose a method to show it.
            // As a safe fallback show the app's main menu or do nothing.
            // Implementors can expand this to present the actual preferences UI.
            print("openPreferences: Preferences requested")
        }
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
