import SwiftUI
import AppKit

class LayoutWindowManager: NSObject {
    static let shared = LayoutWindowManager()
    
    private var editorWindow: NSWindow?
    private var createWindow: NSWindow?
    
    func showEditLayout(_ layout: ZoneSet) {
        // Close existing if open
        editorWindow?.close()
        
        let editorView = LayoutEditorContainer(layout: layout) { updatedLayout in
            LayoutManager.shared.saveLayout(updatedLayout)
            // The view handles dismissal via presentationMode, but we ensure window ref is cleared
            self.editorWindow = nil
        }
        
        let hostingController = NSHostingController(rootView: editorView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Edit Layout: \(layout.name)"
        window.setContentSize(NSSize(width: 900, height: 700))
        window.styleMask = [.titled, .closable, .resizable]
        window.center()
        window.isReleasedWhenClosed = false
        
        // Ensure window is cleaned up when closed
        window.delegate = self
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.editorWindow = window
    }
    
    func showAddLayout() {
        createWindow?.close()
        
        let createView = CreateLayoutView { type, name in
            let newLayout: ZoneSet
            if type == .grid {
                newLayout = LayoutFactory.createGridTemplate(name: name)
            } else {
                newLayout = LayoutFactory.createCanvasTemplate(name: name)
            }
            LayoutManager.shared.saveLayout(newLayout)
            
            // Close create window
            self.createWindow?.close()
            self.createWindow = nil
            
            // Open editor for the new layout
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showEditLayout(newLayout)
            }
        }
        
        let hostingController = NSHostingController(rootView: createView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "New Layout"
        window.setContentSize(NSSize(width: 300, height: 200))
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        
        window.delegate = self
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.createWindow = window
    }
}

extension LayoutWindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window == editorWindow {
                editorWindow = nil
            } else if window == createWindow {
                createWindow = nil
            }
        }
    }
}
