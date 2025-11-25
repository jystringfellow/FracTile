//
//  OverlayController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import Foundation
import Combine
import CoreGraphics
import AppKit

// Lightweight SwiftUI-friendly bridge around the AppKit overlay window controller.
// Keep this file small — the heavy lifting lives in OverlayWindowController (AppKit) in its own file.
final class OverlayController: ObservableObject {
    static let shared = OverlayController()

    private let overlayWC = OverlayWindowController()

    @Published private(set) var isVisible = false
    
    /// Current zones being displayed by the overlay
    @Published private(set) var currentZones: [InternalRect] = []
    private(set) var currentScreen: NSScreen?

    private init() {}

    func showOverlay() {
        overlayWC.showOverlay()
        isVisible = true
    }

    func showOverlay(on screen: NSScreen) {
        overlayWC.showOverlay(on: screen)
        currentScreen = screen
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

    func updateZones(_ zones: [InternalRect], screen: NSScreen) {
        currentZones = zones
        currentScreen = screen
        overlayWC.updateZones(zones, screen: screen)
    }

    /// Highlight specific zone indices on the overlay
    func highlightZones(_ indices: [Int]) {
        overlayWC.highlightZones(indices)
    }
}
