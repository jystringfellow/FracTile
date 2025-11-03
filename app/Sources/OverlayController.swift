//
//  OverlayController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import Foundation
import Combine
import CoreGraphics

// Lightweight SwiftUI-friendly bridge around the AppKit overlay window controller.
// Keep this file small — the heavy lifting lives in OverlayWindowController (AppKit) in its own file.
final class OverlayController: ObservableObject {
    static let shared = OverlayController()

    private let overlayWC = OverlayWindowController()

    @Published private(set) var isVisible = false

    private init() {}

    func showOverlay() {
        overlayWC.showOverlay()
        isVisible = true
    }

    func hideOverlay() {
        overlayWC.hideOverlay()
        isVisible = false
    }

    func toggleOverlay() {
        if overlayWC.isVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    func updateZones(_ zones: [CGRect]) {
        overlayWC.updateZones(zones)
    }
}
