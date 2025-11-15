# Zone Snapping Bug Fixes - Summary

## Date: November 15, 2025

## Issues Fixed

### Issue 1: Overlay persists after releasing snap key
**Problem**: The overlay would show when the snap key was pressed before dragging, but would remain visible even after releasing the snap key during the drag. This prevented users from placing windows freely without snapping.

**Solution**: Refactored `DragSnapController` to:
- Continuously monitor modifier key state during drag using `flagsChanged` events
- Check snap key state on every drag event
- Only show overlay when BOTH conditions are true:
  1. User is actively dragging (left mouse button held)
  2. Snap key is currently pressed
- Hide overlay immediately when snap key is released, even if still dragging
- Allow users to press snap key during an already-in-progress drag to show overlay

**Files Modified**:
- `/Volumes/Craig/Code/FracTile/app/Sources/DragSnapController.swift`

**Key Changes**:
- Added `flagsChangedMonitor` to track modifier key changes
- Renamed `isDragActive` to `isDragging` for clarity
- Created `updateOverlayVisibility()` method that checks both conditions
- Created `isSnapKeyHeld()` helper method
- Moved event monitors to `start()` so they persist across drags
- Call `updateOverlayVisibility()` from drag events and flags changed events

### Issue 2: Vertical coordinate inversion when snapping
**Problem**: Windows were being snapped to incorrect vertical positions - zones near the top would snap to the bottom, and vice versa. Horizontal placement was correct.

**Root Cause**: macOS uses a bottom-left origin coordinate system (y=0 at bottom of screen), but NSView typically uses a top-left origin (y=0 at top). The coordinate conversion in `OverlayWindowController.convertFromScreenRect()` was not properly accounting for this difference.

**Solution**: Fixed the coordinate conversion to properly flip the Y axis:
- Calculate screen positions relative to bottom of screen (as provided)
- Convert to view positions relative to top of window
- Formula: `localY = windowTop - screenTop`

**Files Modified**:
- `/Volumes/Craig/Code/FracTile/app/Sources/OverlayWindowController.swift`

**Key Changes**:
- Rewrote `convertFromScreenRect()` method in `OverlayContentView`
- Added proper Y-axis flipping calculation
- Added documentation explaining the coordinate system conversion

## Testing Recommendations

1. **Test overlay visibility behavior**:
   - Start dragging a window without snap key → overlay should NOT appear
   - Press snap key during drag → overlay should appear
   - Release snap key while still dragging → overlay should disappear
   - Continue drag without snap key → window should move freely
   - Release window → window should stay where placed (no snapping)

2. **Test overlay with snap key first**:
   - Press snap key, then start dragging → overlay should appear immediately
   - Keep snap key pressed throughout drag → overlay should stay visible
   - Release window over a zone → window should snap to that zone

3. **Test vertical positioning**:
   - Drag window to top zones → should snap to top of screen
   - Drag window to bottom zones → should snap to bottom of screen
   - Drag window to middle zones → should snap to middle of screen
   - Verify horizontal positioning remains correct

4. **Test multi-zone selection** (if applicable):
   - Hold snap key + multi-zone key during drag
   - Verify multiple zones can be highlighted
   - Verify snapping works correctly for multi-zone selections

### Issue 3: Zone highlighting mismatch (discovered during testing)
**Problem**: When hovering the mouse over a zone, a different zone would be highlighted. For example, in a 2x2 grid, hovering over the top-right zone would highlight the bottom-left zone. Windows would snap to the highlighted zone, not the hovered zone.

**Root Cause**: The `ZoneEngine.calculateGridZones()` method was creating zones with inverted Y coordinates. In macOS screen coordinates, y=0 is at the **bottom** of the screen, so row 0 (the top row logically) should have the **highest** Y value. However, the code was treating row 0 as having the lowest Y value, effectively creating zones upside-down.

**Solution**: Fixed the zone calculation to properly flip row indices when calculating Y coordinates:
- Row 0 (top) now correctly uses the highest Y values from the screen
- Row N-1 (bottom) now correctly uses the lowest Y values from the screen
- Added flipping logic: `flippedRowIndex = gridInfo.rows - 1 - rowIndex`
- Updated rect creation to use bottom as origin.y and calculate height correctly

**Files Modified**:
- `/Volumes/Craig/Code/FracTile/app/Sources/ZoneEngine.swift`

**Key Changes**:
- Added `flippedRowIndex` calculation to invert row mapping for Y coordinates
- Changed rect creation to use `bottomAdj` as origin.y (bottom of zone in screen coords)
- Changed height calculation to `topAdj - bottomAdj` (top is higher value than bottom)
- Added comments explaining the coordinate system conversion

## Build Status
✅ Build succeeded with no errors (warnings are pre-existing and unrelated to these changes)
