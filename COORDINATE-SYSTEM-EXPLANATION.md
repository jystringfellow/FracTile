# macOS Coordinate System Explanation

## The Problem

macOS uses a **bottom-left origin** coordinate system for screen coordinates, which is different from most UI frameworks that use top-left origin. This caused confusion in our zone calculations.

## Screen Coordinates (macOS)

```
                      (0, 1080) ← top of screen
                      │
                      │  (higher Y values)
                      │
                      │
                      │
(0, 0) ← bottom-left  └─────────────── (1920, 0)
       origin
```

## Grid Layout Logical View

When we think of a 2x2 grid, we think:

```
Row 0: [Zone 0] [Zone 1]  ← Top row
Row 1: [Zone 2] [Zone 3]  ← Bottom row
```

## How Zones Should Map to Screen Coordinates

For a 2x2 grid on a 1920x1080 screen:

```
Zone 0 (Row 0, Col 0):               Zone 1 (Row 0, Col 1):
  origin: (0, 540)                     origin: (960, 540)
  size: (960, 540)                     size: (960, 540)
  ← higher Y = top of screen           ← higher Y = top of screen

Zone 2 (Row 1, Col 0):               Zone 3 (Row 1, Col 1):
  origin: (0, 0)                       origin: (960, 0)
  size: (960, 540)                     size: (960, 540)
  ← lower Y = bottom of screen         ← lower Y = bottom of screen
```

## The Bug

The original code was doing:
```swift
let top = rowTuples[rowIndex].start  // Row 0 got low Y values
```

This meant:
- Row 0 → Y values 0-540 (BOTTOM of screen) ❌
- Row 1 → Y values 540-1080 (TOP of screen) ❌

## The Fix

We now flip the row index:
```swift
let flippedRowIndex = gridInfo.rows - 1 - rowIndex
let top = rowTuples[flippedRowIndex].start
```

This means:
- Row 0 → Y values 540-1080 (TOP of screen) ✅
- Row 1 → Y values 0-540 (BOTTOM of screen) ✅

## Three Coordinate Systems in Play

1. **Screen Coordinates** (NSScreen, NSEvent.mouseLocation):
   - Origin: bottom-left
   - Y increases upward
   - Used for: zone rectangles, mouse position

2. **View Coordinates** (NSView drawing):
   - Origin: top-left
   - Y increases downward
   - Used for: overlay rendering

3. **Logical Grid Coordinates** (GridLayoutInfo):
   - Origin: top-left (conceptually)
   - Row 0 = top, Row N = bottom
   - Col 0 = left, Col N = right
   - Used for: layout definitions

## Conversion Flow

```
Logical Grid (top-left) 
    ↓ ZoneEngine (FLIP ROW INDEX)
Screen Coords (bottom-left)
    ↓ Hit Testing (no conversion needed)
Highlighted Zones
    ↓ OverlayWindowController (FLIP Y AXIS)
View Coords (top-left)
    ↓ Drawing
Visual Overlay
```

## Why Two Flips?

1. **ZoneEngine flip**: Convert logical grid (row 0 = top) to screen coords (high Y = top)
2. **Overlay flip**: Convert screen coords (bottom-left origin) to view coords (top-left origin) for drawing

These are **different** flips for **different** purposes, and both are necessary!
