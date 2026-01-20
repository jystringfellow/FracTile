//
//  FractileApp.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import SwiftUI
import AppKit
import ServiceManagement

var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

@main
struct FracTileApp: App {
    @StateObject private var overlayController = OverlayController.shared

    @State private var displays: [(id: Int, name: String, screen: NSScreen)] = []
    @State private var activeDisplayID: Int? = nil
    @State private var activeLayoutId: String? = nil
    @State private var layouts: [ZoneSet] = []

    @State private var snapKey: String = UserDefaults.standard.string(forKey: "FracTile.SnapKey") ?? "Shift"
    @State private var multiZoneKey: String = UserDefaults.standard.string(forKey: "FracTile.MultiZoneKey") ?? "Command"
    @State private var openAtLogin: Bool = {
        switch SMAppService.mainApp.status {
        case .enabled: return true
        default: return false
        }
    }()

    private let modifierChoices = ["Command", "Shift", "Option", "Control"]

    init() {
        if !isPreview {
            startupSequence()
            DispatchQueue.main.async {
                DragSnapController.shared.start()
            }
        }
    }

    private func startupSequence() {
        checkIfRunning()
        checkAccessibilityOnStartup()
    }

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

    private func loadLayouts() {
        var currentLayouts = LayoutManager.shared.layouts
        
        let hasSeeded = UserDefaults.standard.bool(forKey: "FracTile.HasSeededDefaults")
        
        if !hasSeeded {
            if currentLayouts.isEmpty {
                currentLayouts = DefaultLayouts.all
                for layout in currentLayouts {
                    LayoutManager.shared.saveLayout(layout)
                }
            }
            UserDefaults.standard.set(true, forKey: "FracTile.HasSeededDefaults")
        }
        
        self.layouts = currentLayouts

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
                layouts: layouts,
                snapKey: $snapKey,
                multiZoneKey: $multiZoneKey,
                openAtLogin: $openAtLogin,
                modifierChoices: modifierChoices,
                onEdit: {
                    if let layoutId = activeLayoutId, let layout = layouts.first(where: { $0.id == layoutId }) {
                        if let screen = displays.first(where: { $0.id == activeDisplayID })?.screen ?? NSScreen.main {
                            GridEditorOverlayController.shared.showEditor(on: screen, with: layout)
                        }
                    }
                },
                onAdd: {
                    let alert = NSAlert()
                    alert.messageText = "Create New Layout"
                    alert.informativeText = "Choose the type of layout you want to create:"
                    alert.addButton(withTitle: "Grid Layout")
                    alert.addButton(withTitle: "Canvas Layout")
                    alert.addButton(withTitle: "Cancel")
                    
                    let response = alert.runModal()
                    
                    let newLayout: ZoneSet?
                    let uniqueName = LayoutManager.shared.generateUniqueLayoutName()
                    switch response {
                    case .alertFirstButtonReturn:
                        newLayout = LayoutFactory.createGridTemplate(name: uniqueName)
                    case .alertSecondButtonReturn:
                        newLayout = LayoutFactory.createCanvasTemplate(name: uniqueName)
                    default:
                        newLayout = nil
                    }
                    
                    if let layout = newLayout {
                        if let screen = displays.first(where: { $0.id == activeDisplayID })?.screen ?? NSScreen.main {
                            GridEditorOverlayController.shared.showEditor(on: screen, with: layout)
                        }
                    }
                },
                onDelete: {
                    if let layoutId = activeLayoutId {
                        let alert = NSAlert()
                        alert.messageText = "Delete Layout?"
                        alert.informativeText = "Are you sure you want to delete this layout? This cannot be undone."
                        alert.addButton(withTitle: "Delete")
                        alert.addButton(withTitle: "Cancel")
                        
                        let response = alert.runModal()
                        if response == .alertFirstButtonReturn {
                            LayoutManager.shared.deleteLayout(withId: layoutId)
                        }
                    }
                },
                onToggleOpenAtLogin: {
                    do {
                        if openAtLogin {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        openAtLogin.toggle()
                        print("Failed to toggle login item: \(error)")
                    }
                },
                onFactoryReset: {
                    let alert = NSAlert()
                    alert.messageText = "Factory Reset?"
                    alert.informativeText = "This will delete all saved layouts and settings, and restore FracTile to its default state. This cannot be undone."
                    alert.addButton(withTitle: "Reset")
                    alert.addButton(withTitle: "Cancel")
                    alert.alertStyle = .warning
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        LayoutManager.shared.factoryReset()
                        
                        snapKey = "Shift"
                        multiZoneKey = "Command"
                        
                        loadLayouts()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let confirmAlert = NSAlert()
                            confirmAlert.messageText = "Factory Reset Complete"
                            confirmAlert.informativeText = "FracTile has been reset to factory defaults."
                            confirmAlert.addButton(withTitle: "OK")
                            confirmAlert.alertStyle = .informational
                            confirmAlert.runModal()
                        }
                    }
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
            .onReceive(NotificationCenter.default.publisher(for: .layoutListDidChange)) { _ in
                loadLayouts()
                if let active = activeLayoutId, !layouts.contains(where: { $0.id == active }) {
                     if let defaultLayout = layouts.first(where: { $0.name == "Grid 2×2" }) ?? layouts.first {
                         activeLayoutId = defaultLayout.id
                         if let displayID = activeDisplayID {
                             LayoutManager.shared.setSelectedLayout(defaultLayout.id, forDisplayID: displayID)
                         }
                     }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .selectedLayoutDidChange)) { notification in
                if let userInfo = notification.userInfo,
                   let displayID = userInfo["displayID"] as? Int,
                   let layoutId = userInfo["layoutId"] as? String,
                   displayID == activeDisplayID {
                    activeLayoutId = layoutId
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func refreshDisplaysAndSelection() {
        if layouts.isEmpty {
            loadLayouts()
        }

        displays = LayoutManager.shared.availableDisplays()
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
            
            var targetLayoutId: String?

            if let persisted = LayoutManager.shared.selectedLayoutId(forDisplayID: display.id),
               layouts.contains(where: { $0.id == persisted }) {
                targetLayoutId = persisted
            }

            if targetLayoutId == nil {
                if let defaultLayout = layouts.first(where: { $0.name == "Grid 2×2" }) ?? layouts.first {
                    targetLayoutId = defaultLayout.id
                    LayoutManager.shared.setSelectedLayout(defaultLayout.id, forDisplayID: display.id)
                }
            }
            
            activeLayoutId = targetLayoutId

            snapKey = UserDefaults.standard.string(forKey: "FracTile.SnapKey") ?? snapKey
            multiZoneKey = UserDefaults.standard.string(forKey: "FracTile.MultiZoneKey") ?? multiZoneKey
        }
    }

    private func snapFocusedWindow() {
        let zones = overlayController.currentZones
 
        guard !zones.isEmpty else {
            showNoZonesAlert()
            return
        }
        
        guard let screen = overlayController.currentScreen ?? NSScreen.main else {
            showSnapFailedAlert()
            return
        }
 
        let success = SnapController.shared.snapFocusedWindow(to: zones, screen: screen)
 
        if !success {
            showSnapFailedAlert()
        }
    }

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
    var layouts: [ZoneSet]
    @Binding var snapKey: String
    @Binding var multiZoneKey: String
    @Binding var openAtLogin: Bool
    let modifierChoices: [String]
    private let formLabelWidth: CGFloat = 110

    var onEdit: () -> Void = {}
    var onAdd: () -> Void = {}
    var onDelete: () -> Void = {}
    var onToggleOpenAtLogin: () -> Void = {}
    var onFactoryReset: () -> Void = {}
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

            Group {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Layout for \(activeDisplayName()):")
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker(selection: Binding(get: {
                        return activeLayoutId ?? ""
                    }, set: { newVal in
                        let newLayoutId = newVal.isEmpty ? nil : newVal
                        activeLayoutId = newLayoutId
                        
                        if let layout = newLayoutId, let disp = activeDisplayID {
                            LayoutManager.shared.setSelectedLayout(layout, forDisplayID: disp)
                        }
                    }), label: Text("Layout")) {
                        ForEach(layouts, id: \.id) { zoneSet in
                            Text(zoneSet.name).tag(zoneSet.id)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onAppear {
                    onRefreshDisplays()
                }

                HStack(spacing: 8) {
                    Button(action: { onAdd() }, label: {
                        Image(systemName: "plus")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.green)
                        Text("Add")
                    })
                    
                    Button(action: {
                        onEdit()
                    }, label: {
                        Image(systemName: "pencil")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.yellow)
                        Text("Edit")                    })

                    Button(action: { onDelete() }, label: {
                        Image(systemName: "trash")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.red)
                        Text("Delete")
                    })
 
                     Spacer()
                 }
             }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("Snap Key:")
                        .font(.callout)
                        .frame(width: formLabelWidth, alignment: .leading)

                    Picker("Snap Key", selection: Binding(get: { snapKey }, set: { newVal in
                        snapKey = newVal
                        UserDefaults.standard.set(newVal, forKey: "FracTile.SnapKey")
                    })) {
                        ForEach(modifierChoices, id: \.self) { modifierChoice in
                            Text(modifierChoice).tag(modifierChoice)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    Text("Multi-zone Key:")
                        .font(.callout)
                        .frame(width: formLabelWidth, alignment: .leading)

                    Picker("Multi-zone Key", selection: Binding(get: { multiZoneKey }, set: { newVal in
                        multiZoneKey = newVal
                        UserDefaults.standard.set(newVal, forKey: "FracTile.MultiZoneKey")
                    })) {
                        ForEach(modifierChoices, id: \.self) { modifierChoice in
                            Text(modifierChoice).tag(modifierChoice)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(spacing: 8) {
                    Text("Open at Login:")
                        .font(.callout)
                        .frame(width: formLabelWidth, alignment: .leading)

                    Toggle("", isOn: Binding(get: { openAtLogin }, set: { newVal in
                        openAtLogin = newVal
                        onToggleOpenAtLogin()
                    }))
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
            }

            Divider()

            HStack {
                Spacer()
                Button(action: { onFactoryReset() }, label: {
                    Image(systemName: "arrow.counterclockwise")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.orange)
                    Text("Factory Reset")
                })
                Spacer()
            }

            HStack {
                Spacer()
                Button(action: { onQuit() }, label: {
                    Image(systemName: "power")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.red)
                    Text("Quit FracTile")
                })
                .keyboardShortcut("q", modifiers: [.command])
                Spacer()
            }

            Divider()

            HStack {
                Spacer()
                Text(versionString())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

        }
    }

    private func versionString() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        
        return "Version \(version)"
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
        layouts: [],
        snapKey: .constant("Shift"),
        multiZoneKey: .constant("Command"),
        openAtLogin: .constant(false),
        modifierChoices: ["Command", "Shift", "Option", "Control"],
        onEdit: {},
        onAdd: {},
        onDelete: {},
        onToggleOpenAtLogin: {},
        onFactoryReset: {},
        onQuit: {}
    )
    .frame(width: 360)
    .padding()
}
