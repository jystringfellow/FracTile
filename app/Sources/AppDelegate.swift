//
//  AppDelegate.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Cocoa

//@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItemController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusMenuController()
        statusItemController?.setupStatusItem()
        AccessibilityHelper.checkAndPromptIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up if needed
    }

    // Keep the app running even without windows
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
