//
//  EditorWindowController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import AppKit

final class EditorWindowController {
    static let shared = EditorWindowController()

    private lazy var editorWindow: NSWindow = {
        let viewController = EditorViewController()
        let window = NSWindow(contentViewController: viewController)
        window.title = "FracTile Editor"
        window.setContentSize(NSSize(width: 480, height: 320))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        return window
    }()

    private init() {}

    func showEditor() {
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
