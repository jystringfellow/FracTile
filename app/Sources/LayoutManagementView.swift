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
        .onChange(of: editingLayout) { newLayout in
            if let layout = newLayout {
                // Use the overlay editor for consistency
                if let screen = NSScreen.main {
                    GridEditorOverlayController.shared.showEditor(on: screen, with: layout)
                }
                // Reset the state
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
                showCreateSheet = false
                
                // Open in overlay editor
                if let screen = NSScreen.main {
                    GridEditorOverlayController.shared.showEditor(on: screen, with: newLayout)
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

struct CreateLayoutView: View {
    var onCreate: (ZoneSetLayoutType, String) -> Void
    @State private var name = "New Layout"
    @State private var type: ZoneSetLayoutType = .grid
    @Environment(\.presentationMode) var presentationMode
    
    private var nameError: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Name cannot be empty"
        }
        if LayoutManager.shared.layouts.contains(where: { $0.name == name }) {
            return "A layout with this name already exists"
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Layout").font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Name", text: $name)
                
                if let error = nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
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
                    if nameError == nil {
                        onCreate(type, name)
                    }
                }
                .disabled(nameError != nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
