import SwiftUI
import AppKit

// View extension to handle cursor changes
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onContinuousHover { phase in
            switch phase {
            case .active:
                cursor.push()
            case .ended:
                NSCursor.pop()
            }
        }
    }
}

struct GridEditorToolbar: View {
    @Binding var layout: ZoneSet
    @Binding var selection: Set<GridIndex>
    @Binding var selectedZoneID: Int?
    @Binding var toolbarOffset: CGSize
    var onSave: () -> Void
    var onCancel: () -> Void
    
    @State private var isDragging = false
    
    private var nameError: String? {
        if layout.name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Name cannot be empty"
        }
        // Check if another layout with different ID has the same name
        if LayoutManager.shared.layouts.contains(where: { $0.name == layout.name && $0.id != layout.id }) {
            return "A layout with this name already exists"
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Drag handle area
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Spacer()
                Text("Drag to move")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        toolbarOffset = CGSize(
                            width: toolbarOffset.width + value.translation.width,
                            height: toolbarOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .cursor(isDragging ? .closedHand : .openHand)
            
            Divider()
            
            VStack(spacing: 4) {
                TextField("Layout Name", text: $layout.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if let error = nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if layout.type == .grid, let gridInfo = layout.gridInfo {
                HStack {
                    Text("Rows:")
                    Stepper("\(gridInfo.rows)", value: Binding(
                        get: { gridInfo.rows },
                        set: { newValue in
                            updateGridDimensions(rows: newValue, cols: gridInfo.columns)
                        }
                    ), in: 1...20)
                }
                
                HStack {
                    Text("Columns:")
                    Stepper("\(gridInfo.columns)", value: Binding(
                        get: { gridInfo.columns },
                        set: { newValue in
                            updateGridDimensions(rows: gridInfo.rows, cols: newValue)
                        }
                    ), in: 1...20)
                }
                
                HStack {
                    Text("Spacing:")
                    Stepper("\(layout.spacing)", value: $layout.spacing, in: 0...100)
                }
                
                VStack(spacing: 8) {
                    Button("Distribute All Evenly") {
                        distributeEvenly()
                    }
                    
                    HStack(spacing: 8) {
                        Button("Even Rows") {
                            distributeRowsEvenly()
                        }
                        
                        Button("Even Columns") {
                            distributeColumnsEvenly()
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Button("Split Vertical") {
                        splitSelection(vertical: true)
                    }
                    .disabled(selection.isEmpty)
                    
                    Button("Split Horizontal") {
                        splitSelection(vertical: false)
                    }
                    .disabled(selection.isEmpty)
                }
            } else if layout.type == .canvas {
                HStack {
                    Button("Add Zone") {
                        addZone()
                    }
                    
                    Button("Remove Zone") {
                        removeZone()
                    }
                    .disabled(selectedZoneID == nil)
                }
                
                Button("Bring to Front") {
                    bringToFront()
                }
                .disabled(selectedZoneID == nil)
            }
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave()
                }
                .disabled(nameError != nil)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(12)
        .shadow(radius: isDragging ? 10 : 5)
        .frame(width: 250)
        .offset(toolbarOffset)
    }
    
    private func updateGridDimensions(rows: Int, cols: Int) {
        layout.gridInfo = ZoneEngine.distributeEvenly(rows: rows, columns: cols)
    }
    
    private func distributeEvenly() {
        guard let gridInfo = layout.gridInfo else { return }
        layout.gridInfo = ZoneEngine.distributeEvenly(rows: gridInfo.rows, columns: gridInfo.columns)
    }
    
    private func distributeRowsEvenly() {
        guard let gridInfo = layout.gridInfo else { return }
        layout.gridInfo = ZoneEngine.distributeRowsEvenly(gridInfo: gridInfo)
    }
    
    private func distributeColumnsEvenly() {
        guard let gridInfo = layout.gridInfo else { return }
        layout.gridInfo = ZoneEngine.distributeColumnsEvenly(gridInfo: gridInfo)
    }
    
    private func splitSelection(vertical: Bool) {
        guard var gridInfo = layout.gridInfo else { return }
        guard let cell = selection.first else { return }
        
        // Get the current max zone index to generate new zone indices
        var maxIndex = gridInfo.cellChildMap.flatMap{$0}.max() ?? 0
        
        if vertical {
            // Split column c - this splits ALL zones in this column
            let c = cell.col
            let oldPercent = gridInfo.columnsPercents[c]
            let newPercent1 = oldPercent / 2
            let newPercent2 = oldPercent - newPercent1
            
            gridInfo.columnsPercents[c] = newPercent1
            gridInfo.columnsPercents.insert(newPercent2, at: c + 1)
            gridInfo.columns += 1
            
            // For each row, duplicate the column and create a new zone for the right half
            for r in 0..<gridInfo.rows {
                // Create a new zone index for the right half
                maxIndex += 1
                gridInfo.cellChildMap[r].insert(maxIndex, at: c + 1)
            }
            
        } else {
            // Split row r - this splits ALL zones in this row
            let r = cell.row
            let oldPercent = gridInfo.rowsPercents[r]
            let newPercent1 = oldPercent / 2
            let newPercent2 = oldPercent - newPercent1
            
            gridInfo.rowsPercents[r] = newPercent1
            gridInfo.rowsPercents.insert(newPercent2, at: r + 1)
            gridInfo.rows += 1
            
            // Create new row with new zone indices for each cell
            var newRow: [Int] = []
            for c in 0..<gridInfo.columns {
                maxIndex += 1
                newRow.append(maxIndex)
            }
            gridInfo.cellChildMap.insert(newRow, at: r + 1)
        }
        
        layout.gridInfo = gridInfo
        selection.removeAll()
    }
    
    private func addZone() {
        guard var canvasInfo = layout.canvasInfo else { return }
        
        let width = canvasInfo.lastWorkAreaWidth / 4
        let height = canvasInfo.lastWorkAreaHeight / 4
        let x = (canvasInfo.lastWorkAreaWidth - width) / 2
        let y = (canvasInfo.lastWorkAreaHeight - height) / 2
        
        let maxID = canvasInfo.zones.map { $0.id }.max() ?? 0
        let newZone = CanvasZone(x: x, y: y, width: width, height: height, id: maxID + 1)
        
        canvasInfo.zones.append(newZone)
        layout.canvasInfo = canvasInfo
        selectedZoneID = newZone.id
    }
    
    private func removeZone() {
        guard var canvasInfo = layout.canvasInfo, let id = selectedZoneID else { return }
        canvasInfo.zones.removeAll(where: { $0.id == id })
        layout.canvasInfo = canvasInfo
        selectedZoneID = nil
    }
    
    private func bringToFront() {
        guard var canvasInfo = layout.canvasInfo, let id = selectedZoneID else { return }
        if let index = canvasInfo.zones.firstIndex(where: { $0.id == id }) {
            let zone = canvasInfo.zones.remove(at: index)
            canvasInfo.zones.append(zone)
            layout.canvasInfo = canvasInfo
        }
    }
}
