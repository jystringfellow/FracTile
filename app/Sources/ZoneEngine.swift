//  ZoneEngine.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Foundation
import CoreGraphics
import AppKit

// Constants matching the C++ implementation
private let percentageMultiplier: Int = cMultiplier

// Simple Zone model (kept here since it's a runtime/engine concept)
public struct Zone: Codable, Equatable {
    public let id: Int
    public let rect: InternalRect

    public init(id: Int, rect: InternalRect) {
        self.id = id
        self.rect = rect
    }

    public var isValid: Bool {
        return rect.width > 0 && rect.height > 0
    }
}

public enum LayoutError: Error {
    case invalidZoneId
    case invalidZone
}

// ZoneEngine: algorithms that operate on GridLayoutInfo from LayoutModel.swift
public final class ZoneEngine {
    // Generate a grid layout info for a given zone count using the same rows/columns heuristic
    public static func generateGridLayoutInfo(zoneCount: Int) -> GridLayoutInfo {
        var rows = 1
        var columns = 1

        if zoneCount <= 0 {
            return GridLayoutInfo(rows: 1, columns: 1)
        }

        while zoneCount / rows >= rows {
            rows += 1
        }
        rows -= 1
        columns = zoneCount / rows
        if zoneCount % rows != 0 {
            columns += 1
        }

        var info = GridLayoutInfo(rows: rows, columns: columns)

        // rows percents and columns percents: distribute so sum exactly equals percentageMultiplier
        for rowIndex in 0..<rows {
            let percent = percentageMultiplier * (rowIndex + 1) / rows - percentageMultiplier * rowIndex / rows
            info.rowsPercents[rowIndex] = percent
        }
        for colIndex in 0..<columns {
            let percent = percentageMultiplier * (colIndex + 1) / columns - percentageMultiplier * colIndex / columns
            info.columnsPercents[colIndex] = percent
        }

        // fill cellChildMap similar to C++ (index increments until zoneCount, then repeatedly use last index)
        var index = 0
        for rowIndex in 0..<rows {
            for colIndex in 0..<columns {
                info.cellChildMap[rowIndex][colIndex] = index
                if index < zoneCount - 1 {
                    index += 1
                } else {
                    // keep index at last zone for remaining cells (matching C++ index-- trick)
                    index = zoneCount - 1
                }
            }
        }

        return info
    }

    // Distribute rows and columns evenly, resetting the grid
    public static func distributeEvenly(rows: Int, columns: Int) -> GridLayoutInfo {
        var info = GridLayoutInfo(rows: rows, columns: columns)
        
        // rows percents
        for rowIndex in 0..<rows {
            let percent = percentageMultiplier * (rowIndex + 1) / rows - percentageMultiplier * rowIndex / rows
            info.rowsPercents[rowIndex] = percent
        }
        
        // columns percents
        for colIndex in 0..<columns {
            let percent = percentageMultiplier * (colIndex + 1) / columns - percentageMultiplier * colIndex / columns
            info.columnsPercents[colIndex] = percent
        }
        
        // Reset cellChildMap to default (one zone per cell)
        var index = 0
        for rowIndex in 0..<rows {
            for colIndex in 0..<columns {
                info.cellChildMap[rowIndex][colIndex] = index
                index += 1
            }
        }
        
        return info
    }

    // Small helper to compute start/end/extent arrays from percents to reduce function length
    private static func computeDimensionInfo(count: Int, percents: [Int], totalSize: Int) -> [(start: Int, end: Int, extent: Int)] {
        struct LocalInfo { var start = 0; var end = 0; var extent = 0 }
        var result = Array(repeating: LocalInfo(), count: count)
        var totalPercents = 0
        for idx in 0..<count {
            result[idx].start = totalPercents * totalSize / percentageMultiplier
            totalPercents += percents[idx]
            result[idx].end = totalPercents * totalSize / percentageMultiplier
            result[idx].extent = result[idx].end - result[idx].start
        }
        return result.map { ($0.start, $0.end, $0.extent) }
    }

    // Calculate grid zones from GridLayoutInfo and a workArea and spacing
    // workArea is expected to be in bottom-left origin (like NSScreen.visibleFrame)
    // spacing is in points
    public static func calculateGridZones(workArea: CGRect, on screen: NSScreen, gridInfo: GridLayoutInfo, spacing: Int) -> [Zone] {
        // Convert workArea from bottom-left origin to internal top-left origin immediately
        let internalWorkArea = InternalRect(fromBottomLeft: workArea, screen: screen)
        
        let rows = gridInfo.rows
        let columns = gridInfo.columns
        
        // Compute dimension info for rows and columns
        let rowTuples = computeDimensionInfo(count: rows, percents: gridInfo.rowsPercents, totalSize: Int(internalWorkArea.height))
        let colTuples = computeDimensionInfo(count: columns, percents: gridInfo.columnsPercents, totalSize: Int(internalWorkArea.width))
        
        var zones: [Zone] = []
        var zoneIdCounter = 0
        
        // Build zones by iterating through grid cells
        for rowIndex in 0..<rows {
            for colIndex in 0..<columns {
                let zoneId = gridInfo.cellChildMap[rowIndex][colIndex]
                
                // Check if we've already created this zone
                if zoneIdCounter <= zoneId {
                    // Calculate zone rectangle in internal (top-left) coordinates
                    let left = colTuples[colIndex].start
                    let top = rowTuples[rowIndex].start
                    let zoneWidth = colTuples[colIndex].extent
                    let zoneHeight = rowTuples[rowIndex].extent
                    
                    // Apply spacing by shrinking the zone
                    let halfSpacing = CGFloat(spacing) / 2.0
                    let zoneFinalX = internalWorkArea.x + CGFloat(left) + halfSpacing
                    let zoneFinalY = internalWorkArea.y + CGFloat(top) + halfSpacing
                    let zoneFinalWidth = CGFloat(zoneWidth) - CGFloat(spacing)
                    let zoneFinalHeight = CGFloat(zoneHeight) - CGFloat(spacing)
                    
                    // Create InternalRect for this zone
                    let zoneRect = InternalRect(
                        x: zoneFinalX,
                        y: zoneFinalY,
                        width: max(0, zoneFinalWidth),
                        height: max(0, zoneFinalHeight)
                    )
                    
                    zones.append(Zone(id: zoneId, rect: zoneRect))
                    zoneIdCounter = zoneId + 1
                }
            }
        }
        
        return zones
    }

    // Calculate canvas zones from CanvasLayoutInfo
    public static func calculateCanvasZones(workArea: CGRect, on screen: NSScreen, canvasInfo: CanvasLayoutInfo, spacing: Int) -> [Zone] {
        let workAreaWidth = workArea.width
        let workAreaHeight = workArea.height
        
        let scaleX = workAreaWidth / CGFloat(canvasInfo.lastWorkAreaWidth)
        let scaleY = workAreaHeight / CGFloat(canvasInfo.lastWorkAreaHeight)
        
        // Convert workArea to InternalRect to get its top-left relative to screen
        let workAreaInternal = InternalRect(fromBottomLeft: workArea, screen: screen)
        
        var zones: [Zone] = []
        
        for canvasZone in canvasInfo.zones {
            let x = workAreaInternal.x + CGFloat(canvasZone.x) * scaleX
            let y = workAreaInternal.y + CGFloat(canvasZone.y) * scaleY
            let w = CGFloat(canvasZone.width) * scaleX
            let h = CGFloat(canvasZone.height) * scaleY
            
            let rect = InternalRect(x: x, y: y, width: w, height: h)
            zones.append(Zone(id: canvasZone.id, rect: rect))
        }
        
        return zones
    }
}
