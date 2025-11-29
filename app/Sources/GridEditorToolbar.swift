import SwiftUI

struct GridEditorToolbar: View {
    @Binding var layout: ZoneSet
    @Binding var selection: Set<GridIndex>
    @Binding var selectedZoneID: Int?
    var onSave: () -> Void
    var onCancel: () -> Void
    
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
                
                Button("Distribute Evenly") {
                    distributeEvenly()
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
        .shadow(radius: 5)
        .frame(width: 250)
    }
    
    private func updateGridDimensions(rows: Int, cols: Int) {
        layout.gridInfo = ZoneEngine.distributeEvenly(rows: rows, columns: cols)
    }
    
    private func distributeEvenly() {
        guard let gridInfo = layout.gridInfo else { return }
        layout.gridInfo = ZoneEngine.distributeEvenly(rows: gridInfo.rows, columns: gridInfo.columns)
    }
    
    private func splitSelection(vertical: Bool) {
        guard var gridInfo = layout.gridInfo else { return }
        // For simplicity, only split if 1 cell is selected, or handle first selected
        guard let cell = selection.first else { return }
        
        if vertical {
            // Split column c
            let c = cell.col
            let oldPercent = gridInfo.columnsPercents[c]
            let newPercent1 = oldPercent / 2
            let newPercent2 = oldPercent - newPercent1
            
            gridInfo.columnsPercents[c] = newPercent1
            gridInfo.columnsPercents.insert(newPercent2, at: c + 1)
            gridInfo.columns += 1
            
            for r in 0..<gridInfo.rows {
                let existingIndex = gridInfo.cellChildMap[r][c]
                gridInfo.cellChildMap[r].insert(existingIndex, at: c + 1)
            }
            
            // New index for the split part
            let maxIndex = gridInfo.cellChildMap.flatMap{$0}.max() ?? 0
            gridInfo.cellChildMap[cell.row][c+1] = maxIndex + 1
            
        } else {
            // Split row r
            let r = cell.row
            let oldPercent = gridInfo.rowsPercents[r]
            let newPercent1 = oldPercent / 2
            let newPercent2 = oldPercent - newPercent1
            
            gridInfo.rowsPercents[r] = newPercent1
            gridInfo.rowsPercents.insert(newPercent2, at: r + 1)
            gridInfo.rows += 1
            
            var newRow: [Int] = []
            for c in 0..<gridInfo.columns {
                newRow.append(gridInfo.cellChildMap[r][c])
            }
            gridInfo.cellChildMap.insert(newRow, at: r + 1)
            
            let maxIndex = gridInfo.cellChildMap.flatMap{$0}.max() ?? 0
            gridInfo.cellChildMap[r+1][cell.col] = maxIndex + 1
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
