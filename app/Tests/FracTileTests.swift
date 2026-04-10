import XCTest
@testable import FracTile

class FracTileTests: XCTestCase {
    func testOverlayShows() {
        // TODO: Implement overlay show/hide test
        XCTAssertTrue(true)
    }
}

class OverlayWindowControllerTests: XCTestCase {
    func testGridOverlayViewDrawsGrid() {
        let view = GridOverlayView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        view.setNeedsDisplay(view.bounds)
        // No crash = pass for now
        XCTAssertTrue(true)
    }
}

class ZoneConfiguratorTests: XCTestCase {
    func testZonePersistence() throws {
        let zone = Zone(id: "zone1", frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let configurator = ZoneConfigurator()
        configurator.addZone(zone)
        let url = URL(fileURLWithPath: "/tmp/zones.json")
        try configurator.saveZones(to: url)
        try configurator.loadZones(from: url)
        // No crash = pass for now
        XCTAssertTrue(true)
    }
}

class EventControllerTests: XCTestCase {
    func testStartStopMonitoring() {
        let controller = EventController()
        controller.startMonitoring()
        controller.stopMonitoring()
        // No crash = pass for now
        XCTAssertTrue(true)
    }
}

class DragSnapControllerSelectionTests: XCTestCase {
    func testMultiZoneSelectionShrinksWhenCursorMovesBackTowardAnchor() {
        let activeZones = makeGridZones(rows: 4, columns: 4)
        let initialSelection = DragSnapController.resolveMultiZoneSelection(
            activeZones: activeZones,
            currentHighlightedIndices: [],
            anchorIndices: nil,
            zonesUnderCursor: [3]
        )
        XCTAssertEqual(initialSelection.highlightedIndices, [3])
        XCTAssertEqual(initialSelection.anchorIndices, [3])

        let expandedSelection = DragSnapController.resolveMultiZoneSelection(
            activeZones: activeZones,
            currentHighlightedIndices: initialSelection.highlightedIndices,
            anchorIndices: initialSelection.anchorIndices,
            zonesUnderCursor: [14]
        )
        XCTAssertEqual(expandedSelection.highlightedIndices, [2, 3, 6, 7, 10, 11, 14, 15])
        XCTAssertEqual(expandedSelection.anchorIndices, [3])

        let shrunkenSelection = DragSnapController.resolveMultiZoneSelection(
            activeZones: activeZones,
            currentHighlightedIndices: expandedSelection.highlightedIndices,
            anchorIndices: expandedSelection.anchorIndices,
            zonesUnderCursor: [9]
        )
        XCTAssertEqual(shrunkenSelection.highlightedIndices, [1, 2, 3, 5, 6, 7, 9, 10, 11])
        XCTAssertEqual(shrunkenSelection.anchorIndices, [3])
    }

    func testMultiZoneSelectionUsesCurrentHighlightAsAnchorWhenModifierTurnsOnMidDrag() {
        let activeZones = makeGridZones(rows: 2, columns: 3)
        let selection = DragSnapController.resolveMultiZoneSelection(
            activeZones: activeZones,
            currentHighlightedIndices: [1],
            anchorIndices: nil,
            zonesUnderCursor: [5]
        )

        XCTAssertEqual(selection.highlightedIndices, [1, 2, 4, 5])
        XCTAssertEqual(selection.anchorIndices, [1])
    }

    private func makeGridZones(rows: Int, columns: Int) -> [InternalRect] {
        var zones: [InternalRect] = []
        for row in 0..<rows {
            for column in 0..<columns {
                zones.append(
                    InternalRect(
                        x: CGFloat(column * 100),
                        y: CGFloat(row * 100),
                        width: 100,
                        height: 100
                    )
                )
            }
        }
        return zones
    }
}
