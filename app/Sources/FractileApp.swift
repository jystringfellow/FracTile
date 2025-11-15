//
//  FractileApp.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import SwiftUI
import AppKit

var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

@main
struct FracTileApp: App {
    @StateObject private var overlayController = OverlayController.shared

    // Track displays and selection state for the menu
    @State private var displays: [(id: Int, name: String, screen: NSScreen)] = []
    @State private var activeDisplayID: Int? = nil
    @State private var activeLayoutId: String? = nil

    // Snap / multi-zone key choices (persisted)
    @State private var snapKey: String = UserDefaults.standard.string(forKey: "FracTile.SnapKey") ?? "Shift"
    @State private var multiZoneKey: String = UserDefaults.standard.string(forKey: "FracTile.MultiZoneKey") ?? "Command"

    // Allowed modifier choices
    private let modifierChoices = ["Command", "Shift", "Option", "Control"]

    init() {
        if !isPreview {
            startupSequence()
        }
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
            MenuBarContent(
                displays: $displays,
                activeDisplayID: $activeDisplayID,
                activeLayoutId: $activeLayoutId,
                snapKey: $snapKey,
                multiZoneKey: $multiZoneKey,
                modifierChoices: modifierChoices,
                onEdit: {
                    EditorWindowController.shared.showEditor()
                },
                onAdd: {
                    // Placeholder: add flow
                    EditorWindowController.shared.showEditor()
                },
                onImport: {
                    // Import will open the editor where the import UI lives
                    EditorWindowController.shared.showEditor()
                },
                onDelete: {
                    // Delete placeholder
                    let alert = NSAlert()
                    alert.messageText = "Delete Layout"
                    alert.informativeText = "Deleting custom layouts is not implemented yet."
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                },
                onQuit: {
                    NSApp.terminate(nil)
                },
                onRefreshDisplays: {
                    refreshDisplaysAndSelection()
                }
            )
            .frame(width: 360)
            .padding()
        }
        .menuBarExtraStyle(.window)
    }

    // Helper: determine which display the user most likely wants to configure (screen under mouse, or main)
    private func refreshDisplaysAndSelection() {
        displays = LayoutManager.shared.availableDisplays()
        // find screen under mouse
        let mouseLoc = NSEvent.mouseLocation
        var found: (id: Int, name: String, screen: NSScreen)? = nil
        for display in displays {
            if display.screen.frame.contains(mouseLoc) {
                found = display
                break
            }
        }
        if found == nil {
            found = displays.first(where: { $0.screen == NSScreen.main }) ?? displays.first
        }
        if let display = found {
            activeDisplayID = display.id
            if let persisted = LayoutManager.shared.selectedLayoutId(forDisplayID: display.id) {
                activeLayoutId = persisted
            } else {
                // Default to 2x2 and persist for this display
                if let defaultId = DefaultLayouts.zoneSet(named: "Grid 2×2")?.id ?? DefaultLayouts.all.first?.id {
                    activeLayoutId = defaultId
                    LayoutManager.shared.setSelectedLayout(defaultId, forDisplayID: display.id)
                }
            }

            // load persisted keys as well (keep state in sync if changed externally)
            snapKey = UserDefaults.standard.string(forKey: "FracTile.SnapKey") ?? snapKey
            multiZoneKey = UserDefaults.standard.string(forKey: "FracTile.MultiZoneKey") ?? multiZoneKey
        }
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

struct MenuBarContent: View {
    @Binding var displays: [(id: Int, name: String, screen: NSScreen)]
    @Binding var activeDisplayID: Int?
    @Binding var activeLayoutId: String?
    @Binding var snapKey: String
    @Binding var multiZoneKey: String
    let modifierChoices: [String]

    var onEdit: () -> Void = {}
    var onAdd: () -> Void = {}
    var onImport: () -> Void = {}
    var onDelete: () -> Void = {}
    var onQuit: () -> Void = {}
    var onRefreshDisplays: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 32, height: 32)
                Text("FracTile")
                    .font(.headline)
                Spacer()
            }

            // Display + Layout picker + Edit/Add/Import/Delete row
            Group {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Layout for \(activeDisplayName()):")
                            .font(.callout)

                        HStack {
                            Picker(selection: Binding(get: {
                                return activeLayoutId ?? ""
                            }, set: { newVal in
                                activeLayoutId = newVal.isEmpty ? nil : newVal
                                if let layout = activeLayoutId, let disp = activeDisplayID {
                                    LayoutManager.shared.setSelectedLayout(layout, forDisplayID: disp)
                                }
                            }), label: Text("Layout")) {
                                ForEach(DefaultLayouts.all, id: \.id) { zoneSet in
                                    Text(zoneSet.name).tag(zoneSet.id)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: 260)
                        }
                    }
                    Spacer()
                }
                .onAppear {
                    onRefreshDisplays()
                }

                HStack(spacing: 8) {
                    Button(action: { onAdd() }, label: { Image(systemName: "plus")
                        Text("Add") })
                    
                    Button(action: {
                        onEdit()
                    }, label: {
                        Image(systemName: "pencil")
                        Text("Edit")                    })

                    Button(action: { onImport() }, label: {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import") })

                    Button(action: { onDelete() }, label: {
                        Image(systemName: "trash")
                        Text("Delete") })

                    Spacer()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text("Snap Key:")
                        .font(.callout)
                        .frame(width: 57, alignment: .leading)

                    Picker("Snap Key", selection: Binding(get: { snapKey }, set: { newVal in
                        snapKey = newVal
                        UserDefaults.standard.set(newVal, forKey: "FracTile.SnapKey")
                    })) {
                        ForEach(modifierChoices, id: \.self) { modifierChoice in
                            Text(modifierChoice).tag(modifierChoice)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200)

                    Spacer()
                }

                HStack(alignment: .center, spacing: 8) {
                    Text("Multi-zone Key:")
                        .font(.callout)
                        .frame(width: 89, alignment: .leading)

                    Picker("Multi-zone Key", selection: Binding(get: { multiZoneKey }, set: { newVal in
                        multiZoneKey = newVal
                        UserDefaults.standard.set(newVal, forKey: "FracTile.MultiZoneKey")
                    })) {
                        ForEach(modifierChoices, id: \.self) { modifierChoice in
                            Text(modifierChoice).tag(modifierChoice)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200)

                    Spacer()
                }
            }

            Divider()

            // Center the Quit button
            HStack {
                Spacer()
                Button(action: { onQuit() }, label: {
                    Image(systemName: "power")
                    Text("Quit FracTile")
                })
                .keyboardShortcut("q", modifiers: [.command])
                Spacer()
            }

        }
    }

    private func activeDisplayName() -> String {
        if let id = activeDisplayID, let display = displays.first(where: { $0.id == id }) {
            return display.name
        }
        return "Display"
    }
}

#Preview {
    MenuBarContent(
        displays: .constant([]),
        activeDisplayID: .constant(nil),
        activeLayoutId: .constant(nil),
        snapKey: .constant("Shift"),
        multiZoneKey: .constant("Command"),
        modifierChoices: ["Command", "Shift", "Option", "Control"],
        onEdit: {},
        onAdd: {},
        onImport: {},
        onDelete: {},
        onQuit: {}
    )
    .frame(width: 360)
    .padding()
}
