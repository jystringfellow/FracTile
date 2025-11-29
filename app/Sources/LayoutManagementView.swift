import SwiftUI

struct LayoutManagementView: View {
    @State private var layouts: [ZoneSet] = []
    @State private var editingLayout: ZoneSet?
    @State private var showCreateSheet = false
    
    var body: some View {
        VStack {
            List {
                ForEach(layouts, id: \.id) { layout in
                    HStack {
                        Text(layout.name)
                        Spacer()
                        Button("Edit") {
                            editingLayout = layout
                        }
                        Button("Duplicate") {
                            LayoutManager.shared.duplicateLayout(withId: layout.id)
                        }
                        Button("Delete") {
                            LayoutManager.shared.deleteLayout(withId: layout.id)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            HStack {
                Button(action: { showCreateSheet = true }) {
                    Label("Add Layout", systemImage: "plus")
                }
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
        .sheet(item: $editingLayout) { layout in
            LayoutEditorContainer(layout: layout) { updatedLayout in
                LayoutManager.shared.saveLayout(updatedLayout)
                editingLayout = nil
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateLayoutView { type, name in
                let newLayout: ZoneSet
                if type == .grid {
                    newLayout = LayoutFactory.createGridTemplate(name: name)
                } else {
                    newLayout = LayoutFactory.createCanvasTemplate(name: name)
                }
                LayoutManager.shared.saveLayout(newLayout)
                showCreateSheet = false
                
                // Small delay to allow sheet to dismiss before presenting another?
                // Or just set editingLayout.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    editingLayout = newLayout
                }
            }
        }
        .onAppear {
            refreshLayouts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .layoutListDidChange)) { _ in
            refreshLayouts()
        }
    }
    
    func refreshLayouts() {
        layouts = LayoutManager.shared.layouts
    }
}

// Extension to make ZoneSet Identifiable for sheet(item:)
extension ZoneSet: Identifiable {}

struct LayoutEditorContainer: View {
    @State var layout: ZoneSet
    var onSave: (ZoneSet) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selection: Set<GridIndex> = []
    @State private var selectedZoneID: Int? = nil
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Text("Edit \(layout.name)")
                    .font(.headline)
                Spacer()
                Button("Save") {
                    var finalLayout = layout
                    // Normalize canvas layout to current screen resolution
                    if finalLayout.type == .canvas, var canvasInfo = finalLayout.canvasInfo {
                        if let screen = NSScreen.main {
                            let newWidth = Int(screen.visibleFrame.width)
                            let newHeight = Int(screen.visibleFrame.height)
                            
                            if canvasInfo.lastWorkAreaWidth != newWidth || canvasInfo.lastWorkAreaHeight != newHeight {
                                let scaleX = CGFloat(newWidth) / CGFloat(max(1, canvasInfo.lastWorkAreaWidth))
                                let scaleY = CGFloat(newHeight) / CGFloat(max(1, canvasInfo.lastWorkAreaHeight))
                                
                                for i in 0..<canvasInfo.zones.count {
                                    canvasInfo.zones[i].x = Int(CGFloat(canvasInfo.zones[i].x) * scaleX)
                                    canvasInfo.zones[i].y = Int(CGFloat(canvasInfo.zones[i].y) * scaleY)
                                    canvasInfo.zones[i].width = Int(CGFloat(canvasInfo.zones[i].width) * scaleX)
                                    canvasInfo.zones[i].height = Int(CGFloat(canvasInfo.zones[i].height) * scaleY)
                                }
                                canvasInfo.lastWorkAreaWidth = newWidth
                                canvasInfo.lastWorkAreaHeight = newHeight
                                finalLayout.canvasInfo = canvasInfo
                            }
                        }
                    }
                    
                    onSave(finalLayout)
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if layout.type == .grid {
                GridEditorView(layout: $layout, selection: $selection)
            } else if layout.type == .canvas {
                CanvasEditorView(layout: $layout, selectedZoneID: $selectedZoneID)
            } else {
                Text("Unsupported layout type for editing")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct CreateLayoutView: View {
    var onCreate: (ZoneSetLayoutType, String) -> Void
    @State private var name = "New Layout"
    @State private var type: ZoneSetLayoutType = .grid
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Layout").font(.headline)
            
            TextField("Name", text: $name)
            
            Picker("Type", selection: $type) {
                Text("Grid").tag(ZoneSetLayoutType.grid)
                Text("Canvas").tag(ZoneSetLayoutType.canvas)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Create") {
                    if !LayoutManager.shared.layouts.contains(where: { $0.name == name }) {
                        onCreate(type, name)
                    }
                }
                .disabled(name.isEmpty || LayoutManager.shared.layouts.contains(where: { $0.name == name }))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
