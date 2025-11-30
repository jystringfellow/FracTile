import SwiftUI
import AppKit

struct GridIndex: Hashable {
    let row: Int
    let col: Int
}

struct GridEditorView: View {
    @Binding var layout: ZoneSet
    @Binding var selection: Set<GridIndex>
    
    @State private var dragStart: CGPoint?
    @State private var currentDrag: CGPoint?
    
    // Resizing state
    @State private var resizingDivider: DividerType?
    @State private var initialPercents: [Int] = [] // Store percents at start of drag
    
    enum DividerType: Hashable {
        case row(Int) // Index of the row BEFORE the divider
        case col(Int) // Index of the col BEFORE the divider
    }

    var body: some View {
        VStack {
            if layout.type == .grid, let gridInfo = layout.gridInfo {
                GeometryReader { geometry in
                    ZStack {
                        // Draw Cells
                        ForEach(0..<gridInfo.rows, id: \.self) { row in
                            ForEach(0..<gridInfo.columns, id: \.self) { col in
                                let rect = self.rectFor(row: row, col: col, gridInfo: gridInfo, size: geometry.size, spacing: layout.spacing)
                                let idx = GridIndex(row: row, col: col)
                                let isSelected = selection.contains(idx)
                                let zoneIndex = gridInfo.cellChildMap[row][col]
                                let zoneNumber = zoneIndex + 1
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? Color.green.opacity(0.3) : Color.green.opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.green.opacity(isSelected ? 1.0 : 0.9), lineWidth: isSelected ? 3 : 2)
                                        )
                                    
                                    Text("\(zoneNumber)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                            }
                        }
                        
                        // Draw Dividers
                        // Vertical Dividers
                        ForEach(0..<gridInfo.columns - 1, id: \.self) { i in
                            let xPerc = gridInfo.columnsPercents.prefix(i + 1).reduce(0, +)
                            let x = (CGFloat(xPerc) / 10000.0) * geometry.size.width
                            
                            ZStack {
                                // Hit target
                                Rectangle()
                                    .fill(Color.white.opacity(0.001))
                                    .frame(width: 16, height: geometry.size.height)
                                // Visual line
                                Rectangle()
                                    .fill(Color.green.opacity(0.5))
                                    .frame(width: 2, height: geometry.size.height)
                            }
                            .position(x: x, y: geometry.size.height / 2)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.resizeLeftRight.set()
                                } else {
                                    NSCursor.arrow.set()
                                }
                            }
                        }
                        
                        // Horizontal Dividers
                        ForEach(0..<gridInfo.rows - 1, id: \.self) { i in
                            let yPerc = gridInfo.rowsPercents.prefix(i + 1).reduce(0, +)
                            let y = (CGFloat(yPerc) / 10000.0) * geometry.size.height
                            
                            ZStack {
                                // Hit target
                                Rectangle()
                                    .fill(Color.white.opacity(0.001))
                                    .frame(width: geometry.size.width, height: 16)
                                // Visual line
                                Rectangle()
                                    .fill(Color.green.opacity(0.5))
                                    .frame(width: geometry.size.width, height: 2)
                            }
                            .position(x: geometry.size.width / 2, y: y)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.resizeUpDown.set()
                                } else {
                                    NSCursor.arrow.set()
                                }
                            }
                        }
                        
                        // Selection Overlay
                        if let start = dragStart, let current = currentDrag, resizingDivider == nil {
                            Path { path in
                                let rect = CGRect(x: min(start.x, current.x),
                                                  y: min(start.y, current.y),
                                                  width: abs(current.x - start.x),
                                                  height: abs(current.y - start.y))
                                path.addRect(rect)
                            }
                            .stroke(Color.green, lineWidth: 2)
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDrag(value: value, size: geometry.size, gridInfo: gridInfo)
                            }
                            .onEnded { value in
                                handleDragEnd(value: value, size: geometry.size, gridInfo: gridInfo)
                            }
                    )
                }
            } else {
                Text("Not a grid layout")
            }
        }
    }
    
    // MARK: - Geometry Helpers
    
    func rectFor(row: Int, col: Int, gridInfo: GridLayoutInfo, size: CGSize, spacing: Int) -> CGRect {
        let totalW = size.width
        let totalH = size.height
        
        let xPerc = gridInfo.columnsPercents.prefix(col).reduce(0, +)
        let wPerc = gridInfo.columnsPercents[col]
        
        let yPerc = gridInfo.rowsPercents.prefix(row).reduce(0, +)
        let hPerc = gridInfo.rowsPercents[row]
        
        let x = (CGFloat(xPerc) / 10000.0) * totalW
        let w = (CGFloat(wPerc) / 10000.0) * totalW
        let y = (CGFloat(yPerc) / 10000.0) * totalH
        let h = (CGFloat(hPerc) / 10000.0) * totalH
        
        let halfSpacing = CGFloat(spacing) / 2.0
        return CGRect(
            x: x + halfSpacing,
            y: y + halfSpacing,
            width: max(0, w - CGFloat(spacing)),
            height: max(0, h - CGFloat(spacing))
        )
    }
    
    // MARK: - Interaction Logic
    
    func handleDrag(value: DragGesture.Value, size: CGSize, gridInfo: GridLayoutInfo) {
        if dragStart == nil {
            // Start of drag
            dragStart = value.startLocation
            
            // Check if we clicked near a divider
            if let divider = hitTestDivider(point: value.startLocation, size: size, gridInfo: gridInfo) {
                resizingDivider = divider
                if case .row = divider {
                    initialPercents = gridInfo.rowsPercents
                } else {
                    initialPercents = gridInfo.columnsPercents
                }
            } else {
                // Start selection
                resizingDivider = nil
                // If not holding shift/cmd, maybe clear selection?
                // For now, let's clear unless we implement multi-select logic later
                selection.removeAll()
            }
        }
        
        currentDrag = value.location
        
        if let divider = resizingDivider {
            // Handle Resizing
            resize(divider: divider, value: value, size: size, gridInfo: gridInfo)
        } else {
            // Handle Selection
            updateSelection(geometrySize: size, gridInfo: gridInfo)
        }
    }
    
    func handleDragEnd(value: DragGesture.Value, size: CGSize, gridInfo: GridLayoutInfo) {
        dragStart = nil
        currentDrag = nil
        resizingDivider = nil
        initialPercents = []
    }
    
    func hitTestDivider(point: CGPoint, size: CGSize, gridInfo: GridLayoutInfo) -> DividerType? {
        let threshold: CGFloat = 10.0
        
        // Check vertical dividers (columns)
        var currentX: CGFloat = 0
        for i in 0..<(gridInfo.columns - 1) {
            let w = (CGFloat(gridInfo.columnsPercents[i]) / 10000.0) * size.width
            currentX += w
            if abs(point.x - currentX) < threshold {
                return .col(i)
            }
        }
        
        // Check horizontal dividers (rows)
        var currentY: CGFloat = 0
        for i in 0..<(gridInfo.rows - 1) {
            let h = (CGFloat(gridInfo.rowsPercents[i]) / 10000.0) * size.height
            currentY += h
            if abs(point.y - currentY) < threshold {
                return .row(i)
            }
        }
        
        return nil
    }
    
    func resize(divider: DividerType, value: DragGesture.Value, size: CGSize, gridInfo: GridLayoutInfo) {
        var newGridInfo = gridInfo
        let delta = value.location - value.startLocation
        
        switch divider {
        case .col(let index):
            let deltaPerc = Int((delta.x / size.width) * 10000)
            let combined = initialPercents[index] + initialPercents[index+1]
            
            var newP1 = initialPercents[index] + deltaPerc
            var newP2 = initialPercents[index+1] - deltaPerc
            
            // Constraints
            if newP1 < 500 { newP1 = 500; newP2 = combined - 500 }
            if newP2 < 500 { newP2 = 500; newP1 = combined - 500 }
            
            newGridInfo.columnsPercents[index] = newP1
            newGridInfo.columnsPercents[index+1] = newP2
            
        case .row(let index):
            let deltaPerc = Int((delta.y / size.height) * 10000)
            let combined = initialPercents[index] + initialPercents[index+1]
            
            var newP1 = initialPercents[index] + deltaPerc
            var newP2 = initialPercents[index+1] - deltaPerc
            
            // Constraints
            if newP1 < 500 { newP1 = 500; newP2 = combined - 500 }
            if newP2 < 500 { newP2 = 500; newP1 = combined - 500 }
            
            newGridInfo.rowsPercents[index] = newP1
            newGridInfo.rowsPercents[index+1] = newP2
        }
        
        layout.gridInfo = newGridInfo
    }
    
    func updateSelection(geometrySize: CGSize, gridInfo: GridLayoutInfo) {
        guard let start = dragStart, let current = currentDrag else { return }
        let selectionRect = CGRect(x: min(start.x, current.x),
                                   y: min(start.y, current.y),
                                   width: abs(current.x - start.x),
                                   height: abs(current.y - start.y))
        
        var newSelection: Set<GridIndex> = []
        
        for r in 0..<gridInfo.rows {
            for c in 0..<gridInfo.columns {
                let cellRect = rectFor(row: r, col: c, gridInfo: gridInfo, size: geometrySize, spacing: layout.spacing)
                if selectionRect.intersects(cellRect) {
                    newSelection.insert(GridIndex(row: r, col: c))
                }
            }
        }
        selection = newSelection
    }
    
    // MARK: - Actions
    
    // mergeSelection removed as requested
    
    // splitSelection moved to GridEditorContainer logic, but we need to expose helper or move logic out.
    // Since GridEditorView is just a view now, the logic should be in the container or controller.
}

// Helper for CGPoint arithmetic
extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
