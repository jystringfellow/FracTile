# FracTile

FracTile is a macOS menu-bar utility for arranging windows into customizable zone layouts. It provides a lightweight FancyZones-like workflow: create grid or canvas layouts, preview them with overlays, and snap windows into zones using drag-snapping or keyboard modifiers.

This README documents how to build and run FracTile, how to grant required Accessibility permissions, how to use the menu-bar UI, and where to find the key code modules if you want to contribute.

---

## Quick overview

- App type: macOS menu-bar application (SwiftUI + AppKit glue)
- Primary features:
  - Per-display zone layouts (Grid and Canvas types)
  - Visual overlay previews and an in-place layout editor
  - Drag-based snapping and programmatic snap of the focused window
  - Persisted layouts and per-display selected layout
  - Simple preferences for Snap Key and Multi-zone Key

---

## Getting started (build & run)

Requirements:
- macOS with Xcode (recommended latest stable Xcode for best SwiftUI support)
- Xcode project located at `app/FracTile.xcodeproj`

Open in Xcode
1. Open `app/FracTile.xcodeproj` in Xcode.
2. Select the `FracTile` scheme and run (⌘R).
3. On first launch the app will prompt for Accessibility permission (see Permissions below).

Command line (advanced)
- Build:
  xcodebuild -project app/FracTile.xcodeproj -scheme FracTile -configuration Release build

- Run tests:
  xcodebuild test -project app/FracTile.xcodeproj -scheme FracTile -destination 'platform=macOS'

Note: If you use a workspace or SwiftPM dependencies, prefer opening the workspace in Xcode and building from the IDE.

---

## Permissions

FracTile requires Accessibility permission (System Settings → Privacy & Security → Accessibility) to move and resize other application windows. On first run the app will detect missing permission and open System Settings with instructions. If permission is not granted, snapping and window manipulation will silently fail or produce explanatory alerts.

To enable Accessibility:
1. Open System Settings → Privacy & Security → Accessibility
2. Toggle FracTile on
3. Restart FracTile if prompted

Without this permission the overlay preview and editors still work, but snapping operations will not be able to move windows.

---

## Usage (basic)

Open the FracTile menu bar item (top-right). The popover lets you:
- Select which layout applies to a display (the app uses the display under the mouse or the main display by default).
- Add a new layout (choose Grid or Canvas).
- Edit the selected layout (opens the overlay editor on the target display).
- Delete a layout with confirmation.
- Pick Snap Key and Multi-zone Key modifiers (stored in UserDefaults with keys `FracTile.SnapKey` and `FracTile.MultiZoneKey`).
- Factory Reset returns the app to built-in defaults and clears saved layouts.

Previewing & snapping
- Preview a layout to show overlay zones for the current display (preview is provided by the overlay controllers).
- Use drag-snapping (DragSnapController) or manually snap the focused window (SnapController) to move windows into zones.

Defaults
- The app seeds default layouts on first run (flagged by `FracTile.HasSeededDefaults`).
- Default snap keys are: Snap = `Shift`, Multi-zone = `Command`.

---

## Key files and components

A short map of the important source files under `app/Sources/`:

- `FractileApp.swift` — App entry point and menu-bar UI wiring; manages startup flow and high-level user actions.
- `LayoutModel.swift` — Data models for `ZoneSet`, grid and canvas layout representations.
- `LayoutManager.swift` — Persistence, per-display selected layout, and helper APIs to load/save layouts and available displays.
- `LayoutFactory.swift` — Helper functions to create template grid/canvas layouts.
- `DefaultLayouts.swift` — Built-in layout templates used on first run.
- `ZoneEngine.swift` — Zone calculation algorithms (grid/canvas math, spacing, internal rect conversions).
- `GridEditorView.swift`, `CanvasEditorView.swift` — SwiftUI editors used when creating or editing layouts.
- `GridEditorOverlayController.swift`, `OverlayController.swift` — Present overlay windows (previews and editing overlays).
- `SnapController.swift`, `DragSnapController.swift`, `Snapping.swift` — Logic to snap windows (drag-time and programmatic snap behavior).
- `WindowControllerAX.swift`, `AccessibilityHelper.swift` — Accessibility (AX) wrappers and permission prompt flow.
- `Tests/FracTileTests.swift` — Unit tests and simple expectations.

---

## Developer notes

Persistence & defaults
- UserDefaults keys used by the app:
  - `FracTile.HasSeededDefaults` — Bool flag indicating initial seeding of default layouts.
  - `FracTile.SavedLayouts` — (internal) stored layout JSON (managed via `LayoutManager`).
  - `FracTile.SnapKey`, `FracTile.MultiZoneKey` — persisted modifier choices.
  - Per-display selection: `LayoutManager` persists selected layout IDs using a display-specific key pattern.

Models & math
- `ZoneSet` contains the layout definition. Grid layouts are represented with a grid info structure while canvas layouts contain freeform canvas zones.
- `ZoneEngine` computes concrete `InternalRect` regions for overlays and snapping.

Accessibility & AX
- `WindowControllerAX` contains helpers to locate the focused window and set its frame via Accessibility APIs. If an operation fails due to missing permissions, look here for how the app handles errors.

Tests
- Unit tests live in `Tests/FracTileTests.swift`. Run them using the Xcode test runner or `xcodebuild test`.

---

## Troubleshooting

- Overlay doesn't appear when previewing: Ensure a layout exists for the chosen display and that displays were loaded (`FracTile.HasSeededDefaults` should be true after first run). Restarting the app can help if display changes occurred.
- Snapping doesn't work: Confirm Accessibility permissions are granted. Also ensure the target window is not a special system window that cannot be moved or resized.
- Multiple instances: FracTile intentionally exits if another instance of the same bundle is already running.

---

## Contributing

Contributions are welcome. Please:
1. Open an issue first to discuss larger changes.
2. Add tests for behavioral changes that affect layout calculation or snapping.
3. Follow Swift and SwiftUI conventions used in the project.

See `LICENSE` for license information.
