import AppKit
import SwiftUI

class GridEditorOverlayController: NSObject, NSWindowDelegate {
    static let shared = GridEditorOverlayController()
    
    private var overlayWindow: EditorWindow?
    private var currentLayout: ZoneSet?
    private var currentScreen: NSScreen?
    
    override init() {
        super.init()
    }
    
    func showEditor(on screen: NSScreen, with layout: ZoneSet) {
        // Close existing if any
        closeEditor()
        
        // Set these AFTER closing the previous editor
        self.currentScreen = screen
        self.currentLayout = layout
        
        let window = EditorWindow(
            contentRect: screen.visibleFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isReleasedWhenClosed = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = NSColor.black.withAlphaComponent(0.5)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false // We want interaction
        window.delegate = self
        
        // Create the SwiftUI view container
        let editorView = GridEditorContainer(layout: layout, onClose: { [weak self] in
            self?.closeEditor()
        }, onSave: { [weak self] updatedLayout in
            self?.saveAndClose(updatedLayout)
        })
        
        let hostingController = NSHostingController(rootView: editorView)
        window.contentViewController = hostingController
        window.setFrame(screen.visibleFrame, display: true)
        
        self.overlayWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeEditor() {
        overlayWindow?.close()
        overlayWindow = nil
        currentLayout = nil
        currentScreen = nil
    }
    
    private func saveAndClose(_ layout: ZoneSet) {
        // Save the layout
        LayoutManager.shared.saveLayout(layout)
        
        // Set it as the active layout for the current screen
        if let screen = currentScreen {
            if let displayID = getDisplayID(for: screen) {
                LayoutManager.shared.setSelectedLayout(layout.id, forDisplayID: displayID)
            }
        }
        
        closeEditor()
    }
    
    // Helper to extract display ID from NSScreen
    private func getDisplayID(for screen: NSScreen) -> Int? {
        if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return number.intValue
        }
        // fallback: use index
        if let idx = NSScreen.screens.firstIndex(of: screen) {
            return idx
        }
        return nil
    }
}

class EditorWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

// Container view to manage state for the editor
struct GridEditorContainer: View {
    @State var layout: ZoneSet
    @State private var selection: Set<GridIndex> = []
    @State private var selectedZoneID: Int? = nil
    @State private var toolbarOffset: CGSize = .zero
    var onClose: () -> Void
    var onSave: (ZoneSet) -> Void
    
    var body: some View {
        ZStack {
            // The editor view
            if layout.type == .grid {
                GridEditorView(layout: $layout, selection: $selection)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if layout.type == .canvas {
                CanvasEditorView(layout: $layout, selectedZoneID: $selectedZoneID)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // The toolbar
            GridEditorToolbar(
                layout: $layout,
                selection: $selection,
                selectedZoneID: $selectedZoneID,
                toolbarOffset: $toolbarOffset,
                onSave: {
                    onSave(layout)
                }, 
                onCancel: {
                    onClose()
                }
            )
        }
    }
}
