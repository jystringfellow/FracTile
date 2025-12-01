import XCTest
@testable import FracTile

// MARK: - InternalPoint Tests

class InternalPointTests: XCTestCase {
    
    func testInit() {
        let point = InternalPoint(x: 100, y: 200)
        XCTAssertEqual(point.x, 100)
        XCTAssertEqual(point.y, 200)
    }
    
    func testCGPointConversion() {
        let point = InternalPoint(x: 50, y: 75)
        let cgPoint = point.cgPoint
        XCTAssertEqual(cgPoint.x, 50)
        XCTAssertEqual(cgPoint.y, 75)
    }
    
    func testDistanceToPoint() {
        let point1 = InternalPoint(x: 0, y: 0)
        let point2 = InternalPoint(x: 3, y: 4)
        let distance = point1.distance(to: point2)
        XCTAssertEqual(distance, 5, accuracy: 0.0001)
    }
    
    func testDistanceToSamePoint() {
        let point = InternalPoint(x: 100, y: 200)
        let distance = point.distance(to: point)
        XCTAssertEqual(distance, 0)
    }
    
    func testDistanceIsCommutative() {
        let point1 = InternalPoint(x: 10, y: 20)
        let point2 = InternalPoint(x: 50, y: 80)
        let distance1 = point1.distance(to: point2)
        let distance2 = point2.distance(to: point1)
        XCTAssertEqual(distance1, distance2, accuracy: 0.0001)
    }
    
    func testEquatable() {
        let point1 = InternalPoint(x: 100, y: 200)
        let point2 = InternalPoint(x: 100, y: 200)
        let point3 = InternalPoint(x: 100, y: 201)
        XCTAssertEqual(point1, point2)
        XCTAssertNotEqual(point1, point3)
    }
    
    func testHashable() {
        let point1 = InternalPoint(x: 100, y: 200)
        let point2 = InternalPoint(x: 100, y: 200)
        var set = Set<InternalPoint>()
        set.insert(point1)
        set.insert(point2)
        XCTAssertEqual(set.count, 1)
    }
    
    func testCodable() throws {
        let point = InternalPoint(x: 123.5, y: 456.7)
        let encoder = JSONEncoder()
        let data = try encoder.encode(point)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(InternalPoint.self, from: data)
        XCTAssertEqual(decoded, point)
    }
}

// MARK: - InternalRect Tests

class InternalRectTests: XCTestCase {
    
    func testInit() {
        let rect = InternalRect(x: 10, y: 20, width: 100, height: 200)
        XCTAssertEqual(rect.x, 10)
        XCTAssertEqual(rect.y, 20)
        XCTAssertEqual(rect.width, 100)
        XCTAssertEqual(rect.height, 200)
    }
    
    func testComputedMinMax() {
        let rect = InternalRect(x: 10, y: 20, width: 100, height: 200)
        XCTAssertEqual(rect.minX, 10)
        XCTAssertEqual(rect.minY, 20)
        XCTAssertEqual(rect.maxX, 110)
        XCTAssertEqual(rect.maxY, 220)
    }
    
    func testComputedMid() {
        let rect = InternalRect(x: 10, y: 20, width: 100, height: 200)
        XCTAssertEqual(rect.midX, 60)
        XCTAssertEqual(rect.midY, 120)
    }
    
    func testCenter() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 200)
        let center = rect.center
        XCTAssertEqual(center.x, 50)
        XCTAssertEqual(center.y, 100)
    }
    
    func testCenterWithOffset() {
        let rect = InternalRect(x: 50, y: 100, width: 200, height: 300)
        let center = rect.center
        XCTAssertEqual(center.x, 150)
        XCTAssertEqual(center.y, 250)
    }
    
    func testCGRectConversion() {
        let rect = InternalRect(x: 10, y: 20, width: 100, height: 200)
        let cgRect = rect.cgRect
        XCTAssertEqual(cgRect.origin.x, 10)
        XCTAssertEqual(cgRect.origin.y, 20)
        XCTAssertEqual(cgRect.width, 100)
        XCTAssertEqual(cgRect.height, 200)
    }
    
    func testContainsPointInside() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 100)
        let point = InternalPoint(x: 50, y: 50)
        XCTAssertTrue(rect.contains(point))
    }
    
    func testContainsPointOnEdge() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 100)
        let pointOnLeft = InternalPoint(x: 0, y: 50)
        let pointOnTop = InternalPoint(x: 50, y: 0)
        let pointOnRight = InternalPoint(x: 100, y: 50)
        let pointOnBottom = InternalPoint(x: 50, y: 100)
        XCTAssertTrue(rect.contains(pointOnLeft))
        XCTAssertTrue(rect.contains(pointOnTop))
        XCTAssertTrue(rect.contains(pointOnRight))
        XCTAssertTrue(rect.contains(pointOnBottom))
    }
    
    func testContainsPointOnCorners() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 100)
        let topLeft = InternalPoint(x: 0, y: 0)
        let topRight = InternalPoint(x: 100, y: 0)
        let bottomLeft = InternalPoint(x: 0, y: 100)
        let bottomRight = InternalPoint(x: 100, y: 100)
        XCTAssertTrue(rect.contains(topLeft))
        XCTAssertTrue(rect.contains(topRight))
        XCTAssertTrue(rect.contains(bottomLeft))
        XCTAssertTrue(rect.contains(bottomRight))
    }
    
    func testContainsPointOutside() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 100)
        let pointOutside = InternalPoint(x: 150, y: 150)
        XCTAssertFalse(rect.contains(pointOutside))
    }
    
    func testContainsPointJustOutside() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 100)
        let pointLeft = InternalPoint(x: -1, y: 50)
        let pointRight = InternalPoint(x: 101, y: 50)
        let pointAbove = InternalPoint(x: 50, y: -1)
        let pointBelow = InternalPoint(x: 50, y: 101)
        XCTAssertFalse(rect.contains(pointLeft))
        XCTAssertFalse(rect.contains(pointRight))
        XCTAssertFalse(rect.contains(pointAbove))
        XCTAssertFalse(rect.contains(pointBelow))
    }
    
    func testEquatable() {
        let rect1 = InternalRect(x: 10, y: 20, width: 100, height: 200)
        let rect2 = InternalRect(x: 10, y: 20, width: 100, height: 200)
        let rect3 = InternalRect(x: 10, y: 20, width: 101, height: 200)
        XCTAssertEqual(rect1, rect2)
        XCTAssertNotEqual(rect1, rect3)
    }
    
    func testHashable() {
        let rect1 = InternalRect(x: 10, y: 20, width: 100, height: 200)
        let rect2 = InternalRect(x: 10, y: 20, width: 100, height: 200)
        var set = Set<InternalRect>()
        set.insert(rect1)
        set.insert(rect2)
        XCTAssertEqual(set.count, 1)
    }
    
    func testCodable() throws {
        let rect = InternalRect(x: 10.5, y: 20.5, width: 100.5, height: 200.5)
        let encoder = JSONEncoder()
        let data = try encoder.encode(rect)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(InternalRect.self, from: data)
        XCTAssertEqual(decoded, rect)
    }
}

// MARK: - LayoutModel Tests

class LayoutModelTests: XCTestCase {
    
    // MARK: - GridLayoutInfo Tests
    
    func testGridLayoutInfoInit() {
        let info = GridLayoutInfo(rows: 2, columns: 3)
        XCTAssertEqual(info.rows, 2)
        XCTAssertEqual(info.columns, 3)
        XCTAssertEqual(info.rowsPercents.count, 2)
        XCTAssertEqual(info.columnsPercents.count, 3)
        XCTAssertEqual(info.cellChildMap.count, 2)
        XCTAssertEqual(info.cellChildMap[0].count, 3)
    }
    
    func testGridLayoutInfoMinimalInit() {
        let info = GridLayoutInfo(minimalRows: 3, minimalColumns: 4)
        XCTAssertEqual(info.rows, 3)
        XCTAssertEqual(info.columns, 4)
    }
    
    func testGridLayoutInfoDefaultValues() {
        let info = GridLayoutInfo(rows: 2, columns: 2)
        // Default values should be 0
        for percent in info.rowsPercents {
            XCTAssertEqual(percent, 0)
        }
        for percent in info.columnsPercents {
            XCTAssertEqual(percent, 0)
        }
        for row in info.cellChildMap {
            for cell in row {
                XCTAssertEqual(cell, 0)
            }
        }
    }
    
    func testGridLayoutInfoEquatable() {
        let info1 = GridLayoutInfo(rows: 2, columns: 2)
        let info2 = GridLayoutInfo(rows: 2, columns: 2)
        let info3 = GridLayoutInfo(rows: 2, columns: 3)
        XCTAssertEqual(info1, info2)
        XCTAssertNotEqual(info1, info3)
    }
    
    func testGridLayoutInfoCodable() throws {
        var info = GridLayoutInfo(rows: 2, columns: 2)
        info.rowsPercents = [5000, 5000]
        info.columnsPercents = [5000, 5000]
        info.cellChildMap = [[0, 1], [2, 3]]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(info)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GridLayoutInfo.self, from: data)
        XCTAssertEqual(decoded, info)
    }
    
    // MARK: - CanvasZone Tests
    
    func testCanvasZoneInit() {
        let zone = CanvasZone(x: 100, y: 200, width: 300, height: 400, id: 1)
        XCTAssertEqual(zone.x, 100)
        XCTAssertEqual(zone.y, 200)
        XCTAssertEqual(zone.width, 300)
        XCTAssertEqual(zone.height, 400)
        XCTAssertEqual(zone.id, 1)
    }
    
    func testCanvasZoneCodable() throws {
        let zone = CanvasZone(x: 100, y: 200, width: 300, height: 400, id: 5)
        let encoder = JSONEncoder()
        let data = try encoder.encode(zone)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CanvasZone.self, from: data)
        XCTAssertEqual(decoded, zone)
    }
    
    // MARK: - CanvasLayoutInfo Tests
    
    func testCanvasLayoutInfoInit() {
        let zones = [
            CanvasZone(x: 0, y: 0, width: 100, height: 100, id: 0),
            CanvasZone(x: 100, y: 0, width: 100, height: 100, id: 1)
        ]
        let info = CanvasLayoutInfo(zones: zones, lastWorkAreaWidth: 1920, lastWorkAreaHeight: 1080)
        XCTAssertEqual(info.zones.count, 2)
        XCTAssertEqual(info.lastWorkAreaWidth, 1920)
        XCTAssertEqual(info.lastWorkAreaHeight, 1080)
    }
    
    func testCanvasLayoutInfoCodable() throws {
        let zones = [
            CanvasZone(x: 0, y: 0, width: 100, height: 100, id: 0)
        ]
        let info = CanvasLayoutInfo(zones: zones, lastWorkAreaWidth: 2560, lastWorkAreaHeight: 1440)
        let encoder = JSONEncoder()
        let data = try encoder.encode(info)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CanvasLayoutInfo.self, from: data)
        XCTAssertEqual(decoded, info)
    }
    
    // MARK: - ZoneSet Tests
    
    func testZoneSetGridInit() {
        let gridInfo = GridLayoutInfo(rows: 2, columns: 2)
        let zoneSet = ZoneSet(name: "Test Grid", gridInfo: gridInfo, spacing: 12)
        XCTAssertEqual(zoneSet.name, "Test Grid")
        XCTAssertEqual(zoneSet.type, .grid)
        XCTAssertNotNil(zoneSet.gridInfo)
        XCTAssertNil(zoneSet.canvasInfo)
        XCTAssertEqual(zoneSet.spacing, 12)
    }
    
    func testZoneSetCanvasInit() {
        let canvasInfo = CanvasLayoutInfo(zones: [], lastWorkAreaWidth: 1920, lastWorkAreaHeight: 1080)
        let zoneSet = ZoneSet(name: "Test Canvas", canvasInfo: canvasInfo, spacing: 8)
        XCTAssertEqual(zoneSet.name, "Test Canvas")
        XCTAssertEqual(zoneSet.type, .canvas)
        XCTAssertNil(zoneSet.gridInfo)
        XCTAssertNotNil(zoneSet.canvasInfo)
        XCTAssertEqual(zoneSet.spacing, 8)
    }
    
    func testZoneSetGeneratesUUID() {
        let gridInfo = GridLayoutInfo(rows: 2, columns: 2)
        let zoneSet1 = ZoneSet(name: "Test 1", gridInfo: gridInfo)
        let zoneSet2 = ZoneSet(name: "Test 2", gridInfo: gridInfo)
        XCTAssertNotEqual(zoneSet1.id, zoneSet2.id)
        XCTAssertFalse(zoneSet1.id.isEmpty)
        XCTAssertFalse(zoneSet2.id.isEmpty)
    }
    
    func testZoneSetWithCustomID() {
        let gridInfo = GridLayoutInfo(rows: 2, columns: 2)
        let zoneSet = ZoneSet(id: "custom-id", name: "Test", gridInfo: gridInfo)
        XCTAssertEqual(zoneSet.id, "custom-id")
    }
    
    func testZoneSetCodable() throws {
        let gridInfo = GridLayoutInfo(rows: 2, columns: 2)
        let zoneSet = ZoneSet(id: "test-id", name: "Test Grid", gridInfo: gridInfo, spacing: 16)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(zoneSet)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ZoneSet.self, from: data)
        
        XCTAssertEqual(decoded.id, zoneSet.id)
        XCTAssertEqual(decoded.name, zoneSet.name)
        XCTAssertEqual(decoded.type, zoneSet.type)
        XCTAssertEqual(decoded.spacing, zoneSet.spacing)
    }
    
    // MARK: - ZoneSetLayoutType Tests
    
    func testZoneSetLayoutTypeCodable() throws {
        let types: [ZoneSetLayoutType] = [.grid, .priorityGrid, .rows, .columns, .focus, .canvas]
        for type in types {
            let encoder = JSONEncoder()
            let data = try encoder.encode(type)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ZoneSetLayoutType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }
    
    func testCMultiplierConstant() {
        XCTAssertEqual(cMultiplier, 10000)
    }
}

// MARK: - ZoneEngine Tests

class ZoneEngineTests: XCTestCase {
    
    // MARK: - Zone Tests
    
    func testZoneInit() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 100)
        let zone = Zone(id: 1, rect: rect)
        XCTAssertEqual(zone.id, 1)
        XCTAssertEqual(zone.rect, rect)
    }
    
    func testZoneIsValidWithPositiveDimensions() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 100)
        let zone = Zone(id: 1, rect: rect)
        XCTAssertTrue(zone.isValid)
    }
    
    func testZoneIsInvalidWithZeroWidth() {
        let rect = InternalRect(x: 0, y: 0, width: 0, height: 100)
        let zone = Zone(id: 1, rect: rect)
        XCTAssertFalse(zone.isValid)
    }
    
    func testZoneIsInvalidWithZeroHeight() {
        let rect = InternalRect(x: 0, y: 0, width: 100, height: 0)
        let zone = Zone(id: 1, rect: rect)
        XCTAssertFalse(zone.isValid)
    }
    
    func testZoneIsInvalidWithNegativeWidth() {
        let rect = InternalRect(x: 0, y: 0, width: -100, height: 100)
        let zone = Zone(id: 1, rect: rect)
        XCTAssertFalse(zone.isValid)
    }
    
    func testZoneCodable() throws {
        let rect = InternalRect(x: 10, y: 20, width: 100, height: 200)
        let zone = Zone(id: 5, rect: rect)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(zone)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Zone.self, from: data)
        
        XCTAssertEqual(decoded, zone)
    }
    
    // MARK: - generateGridLayoutInfo Tests
    
    func testGenerateGridLayoutInfoWithZeroZones() {
        let info = ZoneEngine.generateGridLayoutInfo(zoneCount: 0)
        XCTAssertEqual(info.rows, 1)
        XCTAssertEqual(info.columns, 1)
    }
    
    func testGenerateGridLayoutInfoWithNegativeZones() {
        let info = ZoneEngine.generateGridLayoutInfo(zoneCount: -5)
        XCTAssertEqual(info.rows, 1)
        XCTAssertEqual(info.columns, 1)
    }
    
    func testGenerateGridLayoutInfoWith1Zone() {
        let info = ZoneEngine.generateGridLayoutInfo(zoneCount: 1)
        XCTAssertEqual(info.rows, 1)
        XCTAssertEqual(info.columns, 1)
    }
    
    func testGenerateGridLayoutInfoWith2Zones() {
        let info = ZoneEngine.generateGridLayoutInfo(zoneCount: 2)
        XCTAssertEqual(info.rows, 1)
        XCTAssertEqual(info.columns, 2)
    }
    
    func testGenerateGridLayoutInfoWith4Zones() {
        let info = ZoneEngine.generateGridLayoutInfo(zoneCount: 4)
        XCTAssertEqual(info.rows, 2)
        XCTAssertEqual(info.columns, 2)
    }
    
    func testGenerateGridLayoutInfoWith6Zones() {
        let info = ZoneEngine.generateGridLayoutInfo(zoneCount: 6)
        XCTAssertEqual(info.rows, 2)
        XCTAssertEqual(info.columns, 3)
    }
    
    func testGenerateGridLayoutInfoWith9Zones() {
        let info = ZoneEngine.generateGridLayoutInfo(zoneCount: 9)
        XCTAssertEqual(info.rows, 3)
        XCTAssertEqual(info.columns, 3)
    }
    
    func testGenerateGridLayoutInfoPercentsSumToMultiplier() {
        for zoneCount in 1...12 {
            let info = ZoneEngine.generateGridLayoutInfo(zoneCount: zoneCount)
            let rowsSum = info.rowsPercents.reduce(0, +)
            let columnsSum = info.columnsPercents.reduce(0, +)
            XCTAssertEqual(rowsSum, 10000, "Row percents should sum to 10000 for zoneCount \(zoneCount)")
            XCTAssertEqual(columnsSum, 10000, "Column percents should sum to 10000 for zoneCount \(zoneCount)")
        }
    }
    
    // MARK: - distributeEvenly Tests
    
    func testDistributeEvenly2x2() {
        let info = ZoneEngine.distributeEvenly(rows: 2, columns: 2)
        XCTAssertEqual(info.rows, 2)
        XCTAssertEqual(info.columns, 2)
        XCTAssertEqual(info.rowsPercents.reduce(0, +), 10000)
        XCTAssertEqual(info.columnsPercents.reduce(0, +), 10000)
    }
    
    func testDistributeEvenly3x3() {
        let info = ZoneEngine.distributeEvenly(rows: 3, columns: 3)
        XCTAssertEqual(info.rows, 3)
        XCTAssertEqual(info.columns, 3)
        // Check that each row is approximately 1/3
        for percent in info.rowsPercents {
            XCTAssertTrue(percent >= 3333 && percent <= 3334)
        }
        for percent in info.columnsPercents {
            XCTAssertTrue(percent >= 3333 && percent <= 3334)
        }
    }
    
    func testDistributeEvenlyCreatesCorrectCellChildMap() {
        let info = ZoneEngine.distributeEvenly(rows: 2, columns: 3)
        // Should create sequential zone IDs: 0,1,2 in row 0 and 3,4,5 in row 1
        XCTAssertEqual(info.cellChildMap[0], [0, 1, 2])
        XCTAssertEqual(info.cellChildMap[1], [3, 4, 5])
    }
    
    // MARK: - distributeRowsEvenly Tests
    
    func testDistributeRowsEvenlyPreservesColumns() {
        var info = GridLayoutInfo(rows: 3, columns: 2)
        // Set custom column percents
        info.columnsPercents = [6000, 4000]
        
        let result = ZoneEngine.distributeRowsEvenly(gridInfo: info)
        
        // Columns should be unchanged
        XCTAssertEqual(result.columnsPercents, [6000, 4000])
        // Rows should be evenly distributed
        XCTAssertEqual(result.rowsPercents.reduce(0, +), 10000)
    }
    
    // MARK: - distributeColumnsEvenly Tests
    
    func testDistributeColumnsEvenlyPreservesRows() {
        var info = GridLayoutInfo(rows: 2, columns: 3)
        // Set custom row percents
        info.rowsPercents = [7000, 3000]
        
        let result = ZoneEngine.distributeColumnsEvenly(gridInfo: info)
        
        // Rows should be unchanged
        XCTAssertEqual(result.rowsPercents, [7000, 3000])
        // Columns should be evenly distributed
        XCTAssertEqual(result.columnsPercents.reduce(0, +), 10000)
    }
}

// MARK: - DefaultLayouts Tests

class DefaultLayoutsTests: XCTestCase {
    
    func testAllLayoutsNotEmpty() {
        XCTAssertFalse(DefaultLayouts.all.isEmpty)
    }
    
    func testAllLayoutsHaveUniqueIds() {
        let ids = DefaultLayouts.all.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All layouts should have unique IDs")
    }
    
    func testAllLayoutsHaveNames() {
        for layout in DefaultLayouts.all {
            XCTAssertFalse(layout.name.isEmpty, "Layout should have a name")
        }
    }
    
    func testGrid2x2Exists() {
        let grid2x2 = DefaultLayouts.zoneSet(named: "Grid 2×2")
        XCTAssertNotNil(grid2x2)
        XCTAssertEqual(grid2x2?.type, .grid)
        XCTAssertEqual(grid2x2?.gridInfo?.rows, 2)
        XCTAssertEqual(grid2x2?.gridInfo?.columns, 2)
    }
    
    func testGrid3x3Exists() {
        let grid3x3 = DefaultLayouts.zoneSet(named: "Grid 3×3")
        XCTAssertNotNil(grid3x3)
        XCTAssertEqual(grid3x3?.type, .grid)
        XCTAssertEqual(grid3x3?.gridInfo?.rows, 3)
        XCTAssertEqual(grid3x3?.gridInfo?.columns, 3)
    }
    
    func testColumns2Exists() {
        let columns = DefaultLayouts.zoneSet(named: "Columns (2)")
        XCTAssertNotNil(columns)
        XCTAssertEqual(columns?.type, .grid)
        XCTAssertEqual(columns?.gridInfo?.rows, 1)
        XCTAssertEqual(columns?.gridInfo?.columns, 2)
    }
    
    func testRows2Exists() {
        let rows = DefaultLayouts.zoneSet(named: "Rows (2)")
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows?.type, .grid)
        XCTAssertEqual(rows?.gridInfo?.rows, 2)
        XCTAssertEqual(rows?.gridInfo?.columns, 1)
    }
    
    func testFocusLayoutExists() {
        let focus = DefaultLayouts.zoneSet(named: "Focus (5 zones)")
        XCTAssertNotNil(focus)
        XCTAssertEqual(focus?.type, .canvas)
        XCTAssertNotNil(focus?.canvasInfo)
        XCTAssertEqual(focus?.canvasInfo?.zones.count, 5)
    }
    
    func testLeftPriorityExists() {
        let leftPriority = DefaultLayouts.zoneSet(named: "Left Priority (2)")
        XCTAssertNotNil(leftPriority)
        XCTAssertEqual(leftPriority?.type, .grid)
        XCTAssertEqual(leftPriority?.gridInfo?.columns, 2)
        // Left column should be wider (66.67%)
        if let percents = leftPriority?.gridInfo?.columnsPercents {
            XCTAssertGreaterThan(percents[0], percents[1])
        }
    }
    
    func testAllGridLayoutsHaveValidPercents() {
        for layout in DefaultLayouts.all where layout.type == .grid {
            guard let gridInfo = layout.gridInfo else { continue }
            
            let rowsSum = gridInfo.rowsPercents.reduce(0, +)
            let columnsSum = gridInfo.columnsPercents.reduce(0, +)
            
            XCTAssertEqual(rowsSum, 10000, "Layout \(layout.name) rows should sum to 10000")
            XCTAssertEqual(columnsSum, 10000, "Layout \(layout.name) columns should sum to 10000")
        }
    }
    
    func testDefaultSpacing() {
        XCTAssertEqual(DefaultLayouts.defaultSpacing, 12)
    }
    
    func testZoneSetNamedReturnsNilForUnknown() {
        let unknown = DefaultLayouts.zoneSet(named: "NonexistentLayout")
        XCTAssertNil(unknown)
    }
}

// MARK: - LayoutFactory Tests

class LayoutFactoryTests: XCTestCase {
    
    func testCreateGridTemplate() {
        let layout = LayoutFactory.createGridTemplate(name: "Test Grid")
        XCTAssertEqual(layout.name, "Test Grid")
        XCTAssertEqual(layout.type, .grid)
        XCTAssertNotNil(layout.gridInfo)
        XCTAssertNil(layout.canvasInfo)
    }
    
    func testCreateGridTemplateHas1Row3Columns() {
        let layout = LayoutFactory.createGridTemplate(name: "Test")
        XCTAssertEqual(layout.gridInfo?.rows, 1)
        XCTAssertEqual(layout.gridInfo?.columns, 3)
    }
    
    func testCreateGridTemplatePercentsSumCorrectly() {
        let layout = LayoutFactory.createGridTemplate(name: "Test")
        guard let gridInfo = layout.gridInfo else {
            XCTFail("Grid info should not be nil")
            return
        }
        
        let rowsSum = gridInfo.rowsPercents.reduce(0, +)
        let columnsSum = gridInfo.columnsPercents.reduce(0, +)
        
        XCTAssertEqual(rowsSum, 10000)
        XCTAssertEqual(columnsSum, 10000)
    }
    
    func testCreateCanvasTemplate() {
        let layout = LayoutFactory.createCanvasTemplate(name: "Test Canvas")
        XCTAssertEqual(layout.name, "Test Canvas")
        XCTAssertEqual(layout.type, .canvas)
        XCTAssertNil(layout.gridInfo)
        XCTAssertNotNil(layout.canvasInfo)
    }
    
    func testCreateCanvasTemplateHasOneZone() {
        let layout = LayoutFactory.createCanvasTemplate(name: "Test")
        XCTAssertEqual(layout.canvasInfo?.zones.count, 1)
    }
    
    func testCreateCanvasTemplateZoneIsCentered() {
        let layout = LayoutFactory.createCanvasTemplate(name: "Test")
        guard let canvasInfo = layout.canvasInfo else {
            XCTFail("Canvas info should not be nil")
            return
        }
        
        // Reference is 1920x1080, zone should be 50% size centered
        XCTAssertEqual(canvasInfo.lastWorkAreaWidth, 1920)
        XCTAssertEqual(canvasInfo.lastWorkAreaHeight, 1080)
        
        guard let zone = canvasInfo.zones.first else {
            XCTFail("Should have at least one zone")
            return
        }
        
        // Width and height should be 50% of reference
        XCTAssertEqual(zone.width, 960)  // 1920/2
        XCTAssertEqual(zone.height, 540) // 1080/2
        
        // Should be centered
        XCTAssertEqual(zone.x, 480)  // (1920-960)/2
        XCTAssertEqual(zone.y, 270) // (1080-540)/2
    }
}

// MARK: - Snapping Tests

class SnappingTests: XCTestCase {
    
    // MARK: - SnappyHelperBase Tests
    
    func testSnappyHelperBaseInitialization() {
        let zones = [
            CGRect(x: 0, y: 0, width: 100, height: 100),
            CGRect(x: 100, y: 0, width: 100, height: 100)
        ]
        let helper = SnappyHelperBase(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bothEdges,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        
        XCTAssertEqual(helper.screenW, 200)
        XCTAssertEqual(helper.mode, .bothEdges)
    }
    
    func testSnappyHelperBaseSnapsContainsBounds() {
        let zones = [
            CGRect(x: 50, y: 50, width: 100, height: 100)
        ]
        let helper = SnappyHelperBase(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bothEdges,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        
        // Snaps should include 0 and screen size
        XCTAssertTrue(helper.snaps.contains(0))
        XCTAssertTrue(helper.snaps.contains(200))
    }
    
    func testSnappyHelperBaseMoveClamps() {
        let zones = [
            CGRect(x: 50, y: 50, width: 100, height: 100)
        ]
        let helper = SnappyHelperBase(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bottomEdge,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        
        // Move should be clamped within min/max
        let initialPosition = helper.position
        helper.move(delta: 1000)
        XCTAssertLessThanOrEqual(helper.position, helper.maxValue)
        
        // Reset and try negative
        helper.move(delta: -1000)
        XCTAssertGreaterThanOrEqual(helper.position, helper.minValue)
    }
    
    // MARK: - SnappyHelperNonMagnetic Tests
    
    func testSnappyHelperNonMagneticMove() {
        let zones = [
            CGRect(x: 50, y: 50, width: 100, height: 100)
        ]
        let helper = SnappyHelperNonMagnetic(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bothEdges,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        
        let initialPosition = helper.position
        helper.move(delta: 10)
        XCTAssertEqual(helper.position, min(helper.maxValue, initialPosition + 10))
    }
    
    // MARK: - SnappyHelperMagnetic Tests
    
    func testSnappyHelperMagneticInitialization() {
        let zones = [
            CGRect(x: 0, y: 0, width: 100, height: 100),
            CGRect(x: 100, y: 0, width: 100, height: 100)
        ]
        let helper = SnappyHelperMagnetic(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bothEdges,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        
        XCTAssertEqual(helper.screenW, 200)
        XCTAssertFalse(helper.snaps.isEmpty)
    }
    
    func testSnappyHelperMagneticMoveSnaps() {
        let zones = [
            CGRect(x: 50, y: 0, width: 100, height: 100)
        ]
        let helper = SnappyHelperMagnetic(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bothEdges,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        
        // After moving, position should be within bounds
        helper.move(delta: 5)
        XCTAssertGreaterThanOrEqual(helper.position, helper.minValue)
        XCTAssertLessThanOrEqual(helper.position, helper.maxValue)
    }
    
    // MARK: - ResizeMode Tests
    
    func testResizeModeBottomEdge() {
        let zones = [CGRect(x: 50, y: 50, width: 100, height: 100)]
        let helper = SnappyHelperBase(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bottomEdge,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        XCTAssertEqual(helper.mode, .bottomEdge)
        XCTAssertEqual(helper.minValue, 0)
    }
    
    func testResizeModeTopEdge() {
        let zones = [CGRect(x: 50, y: 50, width: 100, height: 100)]
        let helper = SnappyHelperBase(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .topEdge,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        XCTAssertEqual(helper.mode, .topEdge)
    }
    
    func testResizeModeBothEdges() {
        let zones = [CGRect(x: 50, y: 50, width: 100, height: 100)]
        let helper = SnappyHelperBase(
            zones: zones,
            zoneIndex: 0,
            isX: true,
            mode: .bothEdges,
            screenAxisOrigin: 0,
            screenAxisSize: 200
        )
        XCTAssertEqual(helper.mode, .bothEdges)
    }
}

// MARK: - EventMonitor Tests

class EventMonitorTests: XCTestCase {
    
    func testCurrentModifierFlagsReturnsFlags() {
        // This is a smoke test - just ensure it doesn't crash
        let flags = EventMonitor.currentModifierFlags()
        XCTAssertNotNil(flags)
    }
    
    // Note: isCommandKeyPressed, isShiftKeyPressed, etc. depend on runtime state
    // and cannot be reliably tested without mocking, but we can ensure they don't crash
    
    func testIsCommandKeyPressedDoesNotCrash() {
        _ = EventMonitor.isCommandKeyPressed()
    }
    
    func testIsShiftKeyPressedDoesNotCrash() {
        _ = EventMonitor.isShiftKeyPressed()
    }
    
    func testIsOptionKeyPressedDoesNotCrash() {
        _ = EventMonitor.isOptionKeyPressed()
    }
    
    func testIsControlKeyPressedDoesNotCrash() {
        _ = EventMonitor.isControlKeyPressed()
    }
}

// MARK: - GridIndex Tests

class GridIndexTests: XCTestCase {
    
    func testGridIndexInit() {
        let index = GridIndex(row: 1, col: 2)
        XCTAssertEqual(index.row, 1)
        XCTAssertEqual(index.col, 2)
    }
    
    func testGridIndexEquatable() {
        let index1 = GridIndex(row: 1, col: 2)
        let index2 = GridIndex(row: 1, col: 2)
        let index3 = GridIndex(row: 1, col: 3)
        XCTAssertEqual(index1, index2)
        XCTAssertNotEqual(index1, index3)
    }
    
    func testGridIndexHashable() {
        let index1 = GridIndex(row: 1, col: 2)
        let index2 = GridIndex(row: 1, col: 2)
        var set = Set<GridIndex>()
        set.insert(index1)
        set.insert(index2)
        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - Integration Tests

class IntegrationTests: XCTestCase {
    
    func testDefaultLayoutsCanBeEncoded() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(DefaultLayouts.all)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testDefaultLayoutsRoundTrip() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(DefaultLayouts.all)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([ZoneSet].self, from: data)
        
        XCTAssertEqual(decoded.count, DefaultLayouts.all.count)
        
        for (original, decoded) in zip(DefaultLayouts.all, decoded) {
            XCTAssertEqual(original.id, decoded.id)
            XCTAssertEqual(original.name, decoded.name)
            XCTAssertEqual(original.type, decoded.type)
            XCTAssertEqual(original.spacing, decoded.spacing)
        }
    }
    
    func testZoneEngineAndDefaultLayoutsIntegration() {
        // Verify that ZoneEngine can process all default layouts
        for layout in DefaultLayouts.all {
            if layout.type == .grid, let gridInfo = layout.gridInfo {
                // Verify percents sum correctly
                let rowsSum = gridInfo.rowsPercents.reduce(0, +)
                let colsSum = gridInfo.columnsPercents.reduce(0, +)
                XCTAssertEqual(rowsSum, 10000, "Layout \(layout.name) rows should sum to 10000")
                XCTAssertEqual(colsSum, 10000, "Layout \(layout.name) columns should sum to 10000")
                
                // Verify cellChildMap dimensions
                XCTAssertEqual(gridInfo.cellChildMap.count, gridInfo.rows)
                for row in gridInfo.cellChildMap {
                    XCTAssertEqual(row.count, gridInfo.columns)
                }
            }
        }
    }
}
