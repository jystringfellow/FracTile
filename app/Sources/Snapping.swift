//
//  Snapping.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Foundation
import CoreGraphics

// Responsibilities:
// - Build snap point lists from zone edges and monitor bounds
// - Magnetic snapping behavior with magnet zone sizes
// - Non-magnetic simple clamping movement

public enum ResizeMode {
    case bottomEdge
    case topEdge
    case bothEdges
}

public class SnappyHelperBase {
    public private(set) var screenW: Int = 0
    public private(set) var snaps: [Int] = []
    public private(set) var minValue: Int = 0
    public private(set) var maxValue: Int = 0
    public fileprivate(set) var position: Int = 0
    public private(set) var mode: ResizeMode = .bothEdges

    // zones: list of rects describing all zones in screen coordinates (origin consistent with ZoneEngine)
    // zoneIndex: the index of zone we are tracking
    // isX: whether to track X (true) or Y (false)
    // mode: bottomEdge/topEdge/bothEdges semantics
    // screenAxisOrigin and screenAxisSize: origin and size along axis for monitor workArea
    public init(zones: [CGRect], zoneIndex: Int, isX: Bool, mode: ResizeMode, screenAxisOrigin: Int, screenAxisSize: Int) {
        let zoneRect = zones[zoneIndex]
        let zonePosition = isX ? Int(zoneRect.origin.x) : Int(zoneRect.origin.y)
        let zoneAxisSize = isX ? Int(zoneRect.width) : Int(zoneRect.height)
        let minAxisSize = isX ? 64 : 72 // mirrors MinZoneWidth/MinZoneHeight used in editor
        var keyPositions: [Int] = []

        for (index, otherZone) in zones.enumerated() where index != zoneIndex {
            let otherPosition = isX ? Int(otherZone.origin.x) : Int(otherZone.origin.y)
            let otherAxisSize = isX ? Int(otherZone.width) : Int(otherZone.height)
            keyPositions.append(otherPosition)
            keyPositions.append(otherPosition + otherAxisSize)
            if mode == .bothEdges {
                keyPositions.append(otherPosition - zoneAxisSize)
                keyPositions.append(otherPosition + otherAxisSize - zoneAxisSize)
            }
        }

        // Add monitor bounds (work areas) relative to screenAxisOrigin
        keyPositions.append(0)
        keyPositions.append(screenAxisSize)
        if mode == .bothEdges {
            keyPositions.append(-zoneAxisSize)
            keyPositions.append(screenAxisSize - zoneAxisSize)
        }

        // Remove duplicates and sort
        keyPositions.sort()
        snaps = []
        if !keyPositions.isEmpty {
            snaps.append(keyPositions[0])
            var last = keyPositions[0]
            for value in keyPositions.dropFirst() where value != last {
                snaps.append(value)
                last = value
            }
        }

        // Set min/max/position depending on mode (mirror C++ logic)
        switch mode {
        case .bottomEdge:
            minValue = 0
            maxValue = zonePosition + zoneAxisSize - minAxisSize
            position = zonePosition
        case .topEdge:
            minValue = zonePosition + minAxisSize
            maxValue = screenAxisSize
            position = zonePosition + zoneAxisSize
        case .bothEdges:
            minValue = 0
            maxValue = screenAxisSize - zoneAxisSize
            position = zonePosition
        }

        self.mode = mode
        self.screenW = screenAxisSize
    }

    // Subclasses override Move(delta:)
    public func move(delta: Int) {
        // default move: clamp
        let pos = position + delta
        position = max(min(maxValue, pos), minValue)
    }
}

public final class SnappyHelperNonMagnetic: SnappyHelperBase {
    public override func move(delta: Int) {
        let pos = (position + delta)
        position = max(min(maxValue, pos), minValue)
    }
}

public final class SnappyHelperMagnetic: SnappyHelperBase {
    private var magnetZoneSizes: [Int] = []
    private var freePosition: Int = 0

    private var magnetZoneMaxSize: Int {
        return Int(0.08 * CGFloat(screenW))
    }

    public override init(zones: [CGRect], zoneIndex: Int, isX: Bool, mode: ResizeMode, screenAxisOrigin: Int, screenAxisSize: Int) {
        super.init(zones: zones, zoneIndex: zoneIndex, isX: isX, mode: mode, screenAxisOrigin: screenAxisOrigin, screenAxisSize: screenAxisSize)
        freePosition = position
        magnetZoneSizes = []
        for snapIndex in 0..<snaps.count {
            let previous = (snapIndex == 0) ? 0 : snaps[snapIndex - 1]
            let next = (snapIndex == snaps.count - 1) ? screenW : snaps[snapIndex + 1]
            let spanBefore = snaps[snapIndex] - previous
            let spanAfter = next - snaps[snapIndex]
            let size = min(spanBefore, min(spanAfter, magnetZoneMaxSize)) / 2
            magnetZoneSizes.append(size)
        }
    }

    public override func move(delta: Int) {
        freePosition = position + delta
        var snapId = -1
        for (index, snap) in snaps.enumerated() where abs(freePosition - snap) <= magnetZoneSizes[index] {
            snapId = index
            break
        }

        if snapId == -1 {
            position = freePosition
        } else {
            let deadZoneWidth = (magnetZoneSizes[snapId] + 1) / 2
            if abs(freePosition - snaps[snapId]) <= deadZoneWidth {
                position = snaps[snapId]
            } else if freePosition < snaps[snapId] {
                let gap = snaps[snapId] - magnetZoneSizes[snapId]
                position = freePosition + (freePosition - gap)
            } else {
                let gap = snaps[snapId] + magnetZoneSizes[snapId]
                position = freePosition - (gap - freePosition)
            }
        }

        position = max(min(maxValue, position), minValue)
    }
}
