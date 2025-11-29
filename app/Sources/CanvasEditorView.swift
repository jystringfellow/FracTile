import SwiftUI

struct CanvasEditorView: View {
    @Binding var layout: ZoneSet
    
    @State private var selectedZoneID: Int?
    @State private var dragStart: CGPoint?
    @State private var initialZone: CanvasZone?
    @State private var dragMode: DragMode = .none
    
    enum DragMode {
        case none
        case move
        case resize(Edge)
    }
    
    enum Edge {
        case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
    }

    var body: some View {
        VStack {
            if layout.type == .canvas, let canvasInfo = layout.canvasInfo {
                GeometryReader { geometry in
                    ZStack {
                        // Background
                        Color.black.opacity(0.8)
                            .onTapGesture {
                                selectedZoneID = nil
                            }
                        
                        // Zones
                        ForEach(canvasInfo.zones, id: \.id) { zone in
                            let rect = rectFor(zone: zone, canvasInfo: canvasInfo, size: geometry.size)
                            let isSelected = selectedZoneID == zone.id
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.green.opacity(0.4) : Color.green.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Color.green : Color.green.opacity(0.8), lineWidth: isSelected ? 3 : 2)
                                    )
                                
                                Text("\(zone.id)")
                                    .foregroundColor(.white)
                            }
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                        }
                        
                        // Resize Handles for Selected Zone
                        if let selectedID = selectedZoneID, let zone = canvasInfo.zones.first(where: { $0.id == selectedID }) {
                            let rect = rectFor(zone: zone, canvasInfo: canvasInfo, size: geometry.size)
                            resizeHandles(rect: rect)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDrag(value: value, size: geometry.size, canvasInfo: canvasInfo)
                            }
                            .onEnded { value in
                                handleDragEnd(value: value, size: geometry.size, canvasInfo: canvasInfo)
                            }
                    )
                }
            } else {
                Text("Not a canvas layout")
            }
            
            HStack {
                Button("Add Zone") {
                    addZone()
                }
                
                Button("Remove Zone") {
                    removeZone()
                }
                .disabled(selectedZoneID == nil)
                
                Spacer()
                
                Button("Bring to Front") {
                    bringToFront()
                }
                .disabled(selectedZoneID == nil)
            }
            .padding()
        }
    }
    
    // MARK: - Geometry Helpers
    
    func rectFor(zone: CanvasZone, canvasInfo: CanvasLayoutInfo, size: CGSize) -> CGRect {
        let scaleX = size.width / CGFloat(canvasInfo.lastWorkAreaWidth)
        let scaleY = size.height / CGFloat(canvasInfo.lastWorkAreaHeight)
        
        return CGRect(
            x: CGFloat(zone.x) * scaleX,
            y: CGFloat(zone.y) * scaleY,
            width: CGFloat(zone.width) * scaleX,
            height: CGFloat(zone.height) * scaleY
        )
    }
    
    func resizeHandles(rect: CGRect) -> some View {
        ZStack {
            // Corners
            handle(at: CGPoint(x: rect.minX, y: rect.minY), edge: .topLeft)
            handle(at: CGPoint(x: rect.maxX, y: rect.minY), edge: .topRight)
            handle(at: CGPoint(x: rect.maxX, y: rect.maxY), edge: .bottomRight)
            handle(at: CGPoint(x: rect.minX, y: rect.maxY), edge: .bottomLeft)
            
            // Sides
            handle(at: CGPoint(x: rect.midX, y: rect.minY), edge: .top)
            handle(at: CGPoint(x: rect.maxX, y: rect.midY), edge: .right)
            handle(at: CGPoint(x: rect.midX, y: rect.maxY), edge: .bottom)
            handle(at: CGPoint(x: rect.minX, y: rect.midY), edge: .left)
        }
    }
    
    func handle(at point: CGPoint, edge: Edge) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 10, height: 10)
            .position(point)
    }
    
    // MARK: - Interaction Logic
    
    func handleDrag(value: DragGesture.Value, size: CGSize, canvasInfo: CanvasLayoutInfo) {
        if dragStart == nil {
            dragStart = value.startLocation
            
            // Determine drag mode
            if let selectedID = selectedZoneID, let zone = canvasInfo.zones.first(where: { $0.id == selectedID }) {
                let rect = rectFor(zone: zone, canvasInfo: canvasInfo, size: size)
                if let edge = hitTestHandles(point: value.startLocation, rect: rect) {
                    dragMode = .resize(edge)
                    initialZone = zone
                } else if rect.contains(value.startLocation) {
                    dragMode = .move
                    initialZone = zone
                } else {
                    // Check if we clicked another zone
                    if let hitZone = hitTestZones(point: value.startLocation, canvasInfo: canvasInfo, size: size) {
                        selectedZoneID = hitZone.id
                        dragMode = .move
                        initialZone = hitZone
                    } else {
                        dragMode = .none
                        selectedZoneID = nil
                    }
                }
            } else {
                // No selection, check hit test
                if let hitZone = hitTestZones(point: value.startLocation, canvasInfo: canvasInfo, size: size) {
                    selectedZoneID = hitZone.id
                    dragMode = .move
                    initialZone = hitZone
                } else {
                    dragMode = .none
                }
            }
        }
        
        guard let initial = initialZone, let start = dragStart else { return }
        guard var newCanvasInfo = layout.canvasInfo else { return }
        guard let index = newCanvasInfo.zones.firstIndex(where: { $0.id == initial.id }) else { return }
        
        let scaleX = CGFloat(canvasInfo.lastWorkAreaWidth) / size.width
        let scaleY = CGFloat(canvasInfo.lastWorkAreaHeight) / size.height
        
        let deltaX = Int((value.location.x - start.x) * scaleX)
        let deltaY = Int((value.location.y - start.y) * scaleY)
        
        var zone = initial
        
        switch dragMode {
        case .move:
            zone.x += deltaX
            zone.y += deltaY
        case .resize(let edge):
            switch edge {
            case .left:
                zone.x += deltaX; zone.width -= deltaX
            case .right:
                zone.width += deltaX
            case .top:
                zone.y += deltaY; zone.height -= deltaY
            case .bottom:
                zone.height += deltaY
            case .topLeft:
                zone.x += deltaX; zone.width -= deltaX; zone.y += deltaY; zone.height -= deltaY
            case .topRight:
                zone.width += deltaX; zone.y += deltaY; zone.height -= deltaY
            case .bottomLeft:
                zone.x += deltaX; zone.width -= deltaX; zone.height += deltaY
            case .bottomRight:
                zone.width += deltaX; zone.height += deltaY
            }
        case .none:
            break
        }
        
        // Constraints (min size)
        if zone.width < 50 { zone.width = 50 }
        if zone.height < 50 { zone.height = 50 }
        
        newCanvasInfo.zones[index] = zone
        layout.canvasInfo = newCanvasInfo
    }
    
    func handleDragEnd(value: DragGesture.Value, size: CGSize, canvasInfo: CanvasLayoutInfo) {
        dragStart = nil
        initialZone = nil
        dragMode = .none
    }
    
    func hitTestHandles(point: CGPoint, rect: CGRect) -> Edge? {
        let threshold: CGFloat = 15
        
        if abs(point.x - rect.minX) < threshold && abs(point.y - rect.minY) < threshold { return .topLeft }
        if abs(point.x - rect.maxX) < threshold && abs(point.y - rect.minY) < threshold { return .topRight }
        if abs(point.x - rect.maxX) < threshold && abs(point.y - rect.maxY) < threshold { return .bottomRight }
        if abs(point.x - rect.minX) < threshold && abs(point.y - rect.maxY) < threshold { return .bottomLeft }
        
        if abs(point.x - rect.midX) < threshold && abs(point.y - rect.minY) < threshold { return .top }
        if abs(point.x - rect.maxX) < threshold && abs(point.y - rect.midY) < threshold { return .right }
        if abs(point.x - rect.midX) < threshold && abs(point.y - rect.maxY) < threshold { return .bottom }
        if abs(point.x - rect.minX) < threshold && abs(point.y - rect.midY) < threshold { return .left }
        
        return nil
    }
    
    func hitTestZones(point: CGPoint, canvasInfo: CanvasLayoutInfo, size: CGSize) -> CanvasZone? {
        // Check in reverse order (topmost first)
        for zone in canvasInfo.zones.reversed() {
            let rect = rectFor(zone: zone, canvasInfo: canvasInfo, size: size)
            if rect.contains(point) {
                return zone
            }
        }
        return nil
    }
    
    // MARK: - Actions
    
    func addZone() {
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
    
    func removeZone() {
        guard var canvasInfo = layout.canvasInfo, let id = selectedZoneID else { return }
        canvasInfo.zones.removeAll(where: { $0.id == id })
        layout.canvasInfo = canvasInfo
        selectedZoneID = nil
    }
    
    func bringToFront() {
        guard var canvasInfo = layout.canvasInfo, let id = selectedZoneID else { return }
        if let index = canvasInfo.zones.firstIndex(where: { $0.id == id }) {
            let zone = canvasInfo.zones.remove(at: index)
            canvasInfo.zones.append(zone)
            layout.canvasInfo = canvasInfo
        }
    }
}
