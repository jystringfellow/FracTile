//
//  ZoneEngine.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Foundation
import CoreGraphics

// Constants matching the C++ implementation
private let percentageMultiplier: Int = 10000

// Simple Zone model
public struct Zone: Codable, Equatable {
    public let id: Int
    public let rect: CGRect

    public init(id: Int, rect: CGRect) {
        self.id = id
        self.rect = rect
    }

    public var isValid: Bool {
        return rect.width > 0 && rect.height > 0
    }
}

// Grid layout info (minimal info -> rows, columns, percents, and cell map)
public struct GridLayoutInfo: Codable {
    public var rows: Int
    public var columns: Int
    // Each percent list uses values summing to percentageMultiplier
    public var rowsPercents: [Int]
    public var columnsPercents: [Int]
    // cellChildMap[row][col] -> zone index
    public var cellChildMap: [[Int]]

    public init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        self.rowsPercents = Array(repeating: 0, count: rows)
        self.columnsPercents = Array(repeating: 0, count: columns)
        self.cellChildMap = Array(repeating: Array(repeating: 0, count: columns), count: rows)
    }
}

public enum LayoutError: Error {
    case invalidZoneId
    case invalidZone
}

// Helper that mirrors LayoutConfigurator::CalculateGridZones
// workArea uses CoreGraphics coordinates (origin at lower-left on macOS by default in some contexts,
// but we'll treat given workArea consistently; callers must pass a screen-relative rect)
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
    // spacing is expected to be in the same coordinate system as workArea (points)
    public static func calculateGridZones(workArea: CGRect, gridInfo: GridLayoutInfo, spacing: Int) -> [Zone] {
        var zones: [Zone] = []

        guard gridInfo.rows > 0 && gridInfo.columns > 0 else {
            return zones
        }

        let totalWidth = Int(workArea.width)
        let totalHeight = Int(workArea.height)

        // Compute row and column info using helper
        let rowTuples = computeDimensionInfo(count: gridInfo.rows, percents: gridInfo.rowsPercents, totalSize: totalHeight)
        let columnTuples = computeDimensionInfo(count: gridInfo.columns, percents: gridInfo.columnsPercents, totalSize: totalWidth)

        for rowIndex in 0..<gridInfo.rows {
            for colIndex in 0..<gridInfo.columns {
                let zoneId = gridInfo.cellChildMap[rowIndex][colIndex]
                let aboveDiffers = (rowIndex == 0) || (gridInfo.cellChildMap[rowIndex - 1][colIndex] != zoneId)
                let leftDiffers = (colIndex == 0) || (gridInfo.cellChildMap[rowIndex][colIndex - 1] != zoneId)
                if aboveDiffers && leftDiffers {
                    let left = columnTuples[colIndex].start
                    let top = rowTuples[rowIndex].start

                    // find max row span
                    var maxRow = rowIndex
                    while (maxRow + 1) < gridInfo.rows && gridInfo.cellChildMap[maxRow + 1][colIndex] == zoneId {
                        maxRow += 1
                    }
                    // find max col span
                    var maxCol = colIndex
                    while (maxCol + 1) < gridInfo.columns && gridInfo.cellChildMap[rowIndex][maxCol + 1] == zoneId {
                        maxCol += 1
                    }

                    let right = columnTuples[maxCol].end
                    let bottom = rowTuples[maxRow].end

                    var topAdj = top
                    var bottomAdj = bottom
                    var leftAdj = left
                    var rightAdj = right
                    // spacing adjustments follow the C++ logic:
                    topAdj += (rowIndex == 0) ? spacing : spacing / 2
                    bottomAdj -= (maxRow == gridInfo.rows - 1) ? spacing : spacing / 2
                    leftAdj += (colIndex == 0) ? spacing : spacing / 2
                    rightAdj -= (maxCol == gridInfo.columns - 1) ? spacing : spacing / 2

                    let rect = CGRect(
                        x: CGFloat(leftAdj) + workArea.origin.x,
                        y: CGFloat(topAdj) + workArea.origin.y,
                        width: CGFloat(max(0, rightAdj - leftAdj)),
                        height: CGFloat(max(0, bottomAdj - topAdj))
                    )
                    let zone = Zone(id: zoneId, rect: rect)
                    if zone.isValid {
                        // ensure unique id insertion (zones can be non-unique if layout is weird)
                        if zones.contains(where: { $0.id == zone.id }) {
                            // this corresponds to AddZone failing in the C++ code
                            // return empty to indicate failure (mirror C++ behavior)
                            return []
                        }
                        zones.append(zone)
                    } else {
                        return []
                    }
                }
            }
        }

        return zones
    }
}
