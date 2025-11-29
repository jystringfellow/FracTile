import SwiftUI

struct GridEditorToolbar: View {
    @Binding var layout: ZoneSet
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Layout Name", text: $layout.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .textFieldStyle(PlainTextFieldStyle())
            
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
}
