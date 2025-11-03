//
//  LayoutModel.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/3/25.
//

import Foundation
import CoreGraphics

// LayoutModel.swift
// Shared data model for layouts used by ZoneEngine, editor, overlay, and persistence.

// Keep the multiplier constant documented for parity with the original implementation.
public let cMultiplier: Int = 10000

public enum ZoneSetLayoutType: String, Codable {
    case grid
    case priorityGrid
    case rows
    case columns
    case focus
    case canvas // custom freeform
}

public struct GridLayoutInfo: Codable, Equatable {
    public var rows: Int
    public var columns: Int
    // percent values that sum to C_MULTIPLIER (10000). We keep them as Ints for parity with FancyZones.
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

    // convenience initializer preserving previous helper name semantics
    public init(minimalRows rows: Int, minimalColumns columns: Int) {
        self.init(rows: rows, columns: columns)
    }
}

public struct CanvasZone: Codable, Equatable {
    // stored in "layout" coordinate space (integers). We'll scale to current monitor size on apply.
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int
    public var id: Int
}

public struct CanvasLayoutInfo: Codable, Equatable {
    public var zones: [CanvasZone]
    // The reference work area size used when the canvas layout was created/saved,
    // so we can scale it to a different monitor size later.
    public var lastWorkAreaWidth: Int
    public var lastWorkAreaHeight: Int
}

public struct ZoneSet: Codable, Equatable {
    public var id: String            // uuid or stable id
    public var name: String
    public var type: ZoneSetLayoutType
    // Either one of gridInfo or canvasInfo will be present depending on type.
    public var gridInfo: GridLayoutInfo?
    public var canvasInfo: CanvasLayoutInfo?
    // spacing in points between zones (used when generating rectangles)
    public var spacing: Int

    public init(id: String = UUID().uuidString, name: String, gridInfo: GridLayoutInfo, spacing: Int = 12) {
        self.id = id
        self.name = name
        self.type = .grid
        self.gridInfo = gridInfo
        self.canvasInfo = nil
        self.spacing = spacing
    }

    public init(id: String = UUID().uuidString, name: String, canvasInfo: CanvasLayoutInfo, spacing: Int = 12) {
        self.id = id
        self.name = name
        self.type = .canvas
        self.gridInfo = nil
        self.canvasInfo = canvasInfo
        self.spacing = spacing
    }
}
