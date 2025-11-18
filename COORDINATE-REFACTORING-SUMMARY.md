# Unified Coordinate System Refactoring - Complete

**Date:** November 16, 2025  
**Status:** ✅ Successfully Completed

## Overview

Successfully implemented a comprehensive coordinate system refactoring to introduce unified internal coordinates with a **top-left origin** throughout the FracTile application. This eliminates scattered Y-coordinate conversions and provides a single, consistent coordinate system for all internal logic.

## New Core Types

### InternalPoint.swift
- Represents points in top-left origin coordinate system
- Provides conversion from bottom-left (NSEvent/NSScreen) coordinates
- Includes `cgPoint(for:)` method to convert back to bottom-left for Accessibility APIs
- Includes `distance(to:)` helper for distance calculations

### InternalRect.swift
- Represents rectangles in top-left origin coordinate system
- Provides conversion from bottom-left (NSScreen.visibleFrame) coordinates
- Includes `cgRect(for:)` method to convert back to bottom-left for Accessibility APIs
- Includes `contains(_:InternalPoint)` method for hit testing
- Includes `center` property and convenience properties (minX, maxX, etc.)

## Modified Files

### ZoneEngine.swift
- **Zone struct**: Changed `rect` property from `CGRect` to `InternalRect`
- **calculateGridZones**: Updated signature to accept `NSScreen` parameter
- Immediately converts bottom-left `workArea` to `InternalRect` at entry
- All zone calculations now performed in top-left coordinate space
- Returns zones with `InternalRect` properties

### DragSnapController.swift
- **activeZones**: Changed from `[CGRect]` to `[InternalRect]`
- **handleMouseDragged**: Converts `NSEvent.mouseLocation` to `InternalPoint` immediately
- Uses `InternalRect.contains(_:InternalPoint)` for hit testing
- **handleMouseUp**: Converts final zone back to bottom-left `CGRect` for `WindowControllerAX.setWindowFrame`
- **nearestZone**: Updated to accept `InternalPoint` and return `InternalRect`
- **updateOverlayVisibility**: Passes screen parameter to `calculateGridZones` and `updateZones`

### OverlayController.swift
- **currentZones**: Changed from `[CGRect]` to `[InternalRect]`
- **currentScreen**: Added private(set) property to track the active screen
- **updateZones**: Updated signature to accept `[InternalRect]` and `NSScreen`

### OverlayWindowController.swift
- **OverlayContentView.zones**: Changed from `[CGRect]` to `[InternalRect]`
- **OverlayContentView.screen**: Added property to store screen reference
- **updateZones**: Updated to accept `[InternalRect]` and `NSScreen`
- **drawZones**: Simplified to use `InternalRect.cgRect` directly (both use top-left origin)
- **Removed**: `convertFromScreenRect` method - no longer needed!

### LayoutManager.swift
- **preview method**: Updated to pass screen parameter to `calculateGridZones`
- **Grid layouts**: Extract `InternalRect` from zones and pass to overlay
- **Canvas layouts**: Convert workArea to `InternalRect` for consistent processing
- All zones passed to overlay are now in internal coordinate system

### SnapController.swift
- **snapFocusedWindow**: Updated signature to accept `[InternalRect]` and `NSScreen`
- Converts window frame from Accessibility API (bottom-left) to `InternalRect`
- **findBestZone**: Updated to work with `InternalRect` for overlap calculations
- Uses `InternalPoint.distance` for nearest-center heuristic
- Converts final zone back to bottom-left `CGRect` for `setWindowFrame`

### FractileApp.swift
- **snapFocusedWindow**: Updated to pass screen from `overlayController.currentScreen`
- Removed duplicate `DragSnapController` class definition

## Coordinate Conversion Points (Boundaries)

### Input Boundaries (External → Internal)
1. **NSEvent.mouseLocation** → `InternalPoint(fromBottomLeft:screen:)`
2. **NSScreen.visibleFrame** → `InternalRect(fromBottomLeft:screen:)`
3. **WindowControllerAX.getWindowFrame** → `InternalRect(fromBottomLeft:screen:)`

### Output Boundaries (Internal → External)
1. **Zone drawing in NSView** → `InternalRect.cgRect` (both use top-left, no conversion!)
2. **WindowControllerAX.setWindowFrame** → `InternalRect.cgRect(for:screen:)`
3. **WindowControllerAX.getWindowUnderPoint** → Keep as bottom-left `CGPoint`

## Benefits

1. **Consistency**: All internal logic uses the same coordinate system
2. **Clarity**: No more scattered Y-coordinate flipping throughout the codebase
3. **Simplicity**: Overlay drawing simplified - `InternalRect` and NSView both use top-left
4. **Maintainability**: Future code works with intuitive top-left coordinates
5. **Bug Prevention**: Type system prevents mixing coordinate systems

## Build Status

✅ **Build Successful** - No compilation errors  
✅ **All files validated** - No syntax or type errors  
✅ **Clean build** - Project compiles cleanly from scratch

## Testing Recommendations

1. **Test overlay display**: Verify zones appear in correct positions
2. **Test mouse drag snapping**: Verify hit detection works correctly
3. **Test window snapping**: Verify windows snap to correct zones
4. **Test multi-screen**: Verify coordinate conversions work on secondary displays
5. **Test different screen arrangements**: Verify handling of screen offsets

## Future Considerations

- Consider adding more helper methods to `InternalRect` (e.g., `inset`, `offset`)
- Consider making the coordinate types @frozen for performance
- Consider adding validation in debug builds to catch coordinate system mistakes
- Update documentation to explain the internal coordinate system

---

**Refactoring completed successfully on November 16, 2025**
