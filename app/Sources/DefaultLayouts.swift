//
//  DefaultLayouts.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/3/25.
//

import Foundation
import CoreGraphics

// DefaultLayouts.swift
// Predefined grid/priority/rows/columns/focus layouts for FracTile MVP.
// These produce GridLayoutInfo instances matching the logic in FancyZones' LayoutConfigurator.
// Use ZoneEngine.calculateGridZones(workArea:gridInfo:spacing:) to obtain CGRects for a given screen.

public struct DefaultLayouts {
    // Public array of built-in ZoneSet
    public static let all: [ZoneSet] = {
        var sets: [ZoneSet] = []

        // Helper to create GridLayoutInfo similar to LayoutConfigurator::generateGridLayoutInfo
        func makeGridInfo(rows: Int, columns: Int) -> GridLayoutInfo {
            var info = GridLayoutInfo(minimalRows: rows, minimalColumns: columns)

            // C_MULTIPLIER parity uses 10000 in the original; keep sums exact
            let multiplier = 10000

            for row in 0..<rows {
                info.rowsPercents[row] = multiplier * (row + 1) / rows - multiplier * row / rows
            }
            for column in 0..<columns {
                info.columnsPercents[column] = multiplier * (column + 1) / columns - multiplier * column / columns
            }

            // cellChildMap: enumerate zones row-major until exhausted; keep last index repeated
            var index = 0
            let zoneCount = rows * columns
            for row in 0..<rows {
                for column in 0..<columns {
                    info.cellChildMap[row][column] = index
                    if index < zoneCount - 1 {
                        index += 1
                    } else {
                        index = zoneCount - 1
                    }
                }
            }
            return info
        }

        // 2x2 grid (classic)
        let grid2x2 = ZoneSet(name: "Grid 2×2", gridInfo: makeGridInfo(rows: 2, columns: 2), spacing: 12)
        sets.append(grid2x2)

        // 3x3 grid
        let grid3x3 = ZoneSet(name: "Grid 3×3", gridInfo: makeGridInfo(rows: 3, columns: 3), spacing: 12)
        sets.append(grid3x3)

        // 1x2 columns
        let columns1x2 = ZoneSet(name: "Columns (2)", gridInfo: makeGridInfo(rows: 1, columns: 2), spacing: 12)
        sets.append(columns1x2)

        // Rows (2)
        let rows2 = ZoneSet(name: "Rows (2)", gridInfo: makeGridInfo(rows: 2, columns: 1), spacing: 12)
        sets.append(rows2)

        // Focus layout (mimic LayoutConfigurator::Focus — we approximate with a single large center zone and stacked smaller ones)
        // For simplicity here create a 1x1 "focus" grid -- editor will later create better Focus layouts
        let focus = ZoneSet(name: "Focus (stack)", gridInfo: makeGridInfo(rows: 1, columns: 1), spacing: 12)
        sets.append(focus)

        // Priority grids and some common asymmetric grids:
        // PriorityGrid (2..5) are often predefined; we add a couple of useful variants:
        let wideLeft = ZoneSet(name: "Left Priority (2)", gridInfo: {
            var info = GridLayoutInfo(minimalRows: 1, minimalColumns: 2)
            // wider left column: 66% left, 33% right -> scale to C_MULTIPLIER
            info.rowsPercents[0] = 10000
            info.columnsPercents = [6667, 3333]
            info.cellChildMap = [[0,1]]
            return info
        }(), spacing: 12)
        sets.append(wideLeft)

        // 4-column grid
        let grid4x4approx = ZoneSet(name: "Grid 4×4", gridInfo: makeGridInfo(rows: 4, columns: 4), spacing: 12)
        sets.append(grid4x4approx)

        // Some long thin columns useful for vertical stacks
        let narrowCols = ZoneSet(name: "Columns (4)", gridInfo: makeGridInfo(rows: 1, columns: 4), spacing: 8)
        sets.append(narrowCols)

        return sets
    }()

    // Convenience lookup by name
    public static func zoneSet(named name: String) -> ZoneSet? {
        return all.first(where: { $0.name == name })
    }

    // Convenience: default spacing per layout can be adjusted here if desired
    public static let defaultSpacing = 12
}
