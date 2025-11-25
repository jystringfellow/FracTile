# FancyZones – Functional Requirements and Behavior

_This document is reverse‑engineered from the FancyZones module in [microsoft/PowerToys @ db7c9e18](https://github.com/microsoft/PowerToys/tree/db7c9e180e113f9e53c26ce093d1767e70fa54d1/src).  
It is intended as a platform‑agnostic specification to support re‑implementation (e.g., on macOS) while preserving behavior and feature parity._

---

## 1. High‑Level Overview

FancyZones is a window management subsystem that:

- Defines **layouts** of rectangular **zones** per “work area” (monitor × virtual desktop).
- Lets users snap windows into one or more zones using:
  - Mouse drag + **snap key** (modifier).
  - Keyboard hotkeys.
- Supports multiple built‑in layout types (focus, rows, columns, grid, priority grid) and **custom** layouts:
  - **Grid‑based** (percentages + cell map).
  - **Canvas** (arbitrary rectangles).
- Persists layout definitions and window assignments across sessions and layout changes.

The macOS implementation must reproduce these behaviors and algorithms at the level of:

- Layout and zone geometry.
- Window → zone assignment, multi‑zone spanning.
- Interaction patterns (mouse + keyboard).
- Persistence and reconstruction.

---

## 2. Core Concepts and Data Structures

### 2.1 Work Area

**Definition**

- A **WorkArea** is a logical region where a single layout is applied.
- On Windows:
  - Defined by `(monitor, virtual desktop)` pair.
- Requirement for macOS:
  - A WorkArea MUST be uniquely identified per display and per virtual desktop (Space).
  - A WorkArea MAY also represent “All displays combined” when spanning across monitors is enabled.

**Responsibilities**

- Holds:
  - `workAreaRect`: the usable rectangle (excluding OS reserved regions like taskbar / menu bar).
  - `layout`: the active zone layout for this work area.
  - `layoutWindows`: the mapping from windows to assigned zones.
- Provides operations:
  - `InitLayout()` – compute and store `layout` from current settings.
  - `Snap(window, zones, updatePosition = true)` – assign window to zone(s) and optionally reposition.
  - `Unsnap(window)` – remove any assignment from this layout.
  - `ShowZones(highlight, draggedWindow)` – show overlay with zones (optionally highlight subset).
  - `HideZones()`, `FlashZones()` – overlay control.
  - `UpdateWindowPositions()` – re‑snap windows after layout or geometry changes.

### 2.2 Layout & LayoutData

**LayoutData** (from `FancyZonesData/LayoutData.h`):

- Fields:
  - `uuid` – global identifier for this layout definition.
  - `type` – one of:
    - `Blank`
    - `Focus`
    - `Columns`
    - `Rows`
    - `Grid`
    - `PriorityGrid`
    - `Custom` (with subtypes Canvas / Grid).
  - `showSpacing` – whether gaps between zones are drawn and applied.
  - `spacing` – spacing size in pixels for gaps.
  - `zoneCount` – number of zones (for built‑in layouts).
  - `sensitivityRadius` – pixel radius for hit‑testing (mouse zone selection, overlapping).

**Layout**

- Represents the **instantiated** layout for a specific work area:
  - Stores:
    - `LayoutData m_data`
    - `ZonesMap m_zones` – mapping `ZoneIndex -> Zone`.
- On initialization (`Layout::Init(workAreaRect, monitorHandle)`):
  - Validates:
    - `workAreaRect.width > 0` and `height > 0`.
    - `zoneCount >= 0`.
    - For grid‑type layouts (`Columns`, `Rows`, `Grid`, `PriorityGrid`): `zoneCount > 0`.
  - Computes `m_zones` via `LayoutConfigurator` based on `type` and `zoneCount`.
  - For `Custom` type, retrieves persisted `CustomLayoutData` and uses `LayoutConfigurator::Custom`.

**Requirements**

- A `Layout` MUST NOT initialize when work area is degenerate or `zoneCount` invalid.
- A successfully initialized `Layout` MUST have `m_zones.size() == m_data.zoneCount` (for grid types).
- `showSpacing` and `spacing` MUST affect final zone rectangles as described in §3.

### 2.3 Zone and ZonesMap

**Zone**

- Wraps a rectangle (zone bounds) and an index/id.
- A zone is **valid** only if:
  - Rectangle width > 0 and height > 0.
- Requirements:
  - Any layout MUST only expose valid zones; invalid zones cause layout creation failure.

**ZonesMap**

- A mapping from `ZoneIndex` (integer) to `Zone`.
- Requirements:
  - Indices MUST be consecutive starting from 0 for built‑in layouts.
  - Zone indices MUST be stable for the lifetime of a given Layout instance (to preserve window assignment consistency).

### 2.4 LayoutAssignedWindows

Tracks which windows occupy which zones within a layout.

- `Assign(window, zones: ZoneIndexSet)`:
  - First `Dismiss(window)` (remove prior mapping).
  - Then store `window -> zones`.
  - Insert window into per‑zone lists for cycling, etc.
- `Dismiss(window)`:
  - Remove window from its assigned index set and any internal structures.
- `GetZoneIndexSetFromWindow(window)`:
  - Returns the `ZoneIndexSet` (possibly empty if not zoned).
- Requirements:
  - A window MAY be assigned to **one or multiple** zones simultaneously.
  - ZoneIndexSet order must be preserved (used for history and cycling).

---

## 3. Layout Geometry and Math

### 3.1 Common Constants and Conventions

- `C_MULTIPLIER = 10000`:
  - Represents 100% (1.0) in fixed‑point integer math.
  - Grid percentage fields (rowsPercents, columnsPercents) are integers summing to `C_MULTIPLIER`.
- All percentage → pixel conversions use integer math with careful cumulative expressions to avoid rounding drift, ensuring:

> The sum of zone widths equals the work area width,  
> and the sum of zone heights equals the work area height.

### 3.2 GridLayoutInfo

A configuration object for grid layouts:

- Fields:
  - `rows`, `columns` – counts.
  - `rowsPercents` – vector of `int` of size `rows`; sum is `C_MULTIPLIER`.
  - `columnsPercents` – vector of `int` of size `columns`; sum is `C_MULTIPLIER`.
  - `cellChildMap` – 2D matrix `[rows][columns]` of zone indices:
    - `cellChildMap[r][c] = i` means cell `(r, c)` belongs to zone `i`.
    - Multiple cells with same `i` form a larger merged zone.
- There are two constructors:
  - `Minimal { rows, columns }` – default uniform grid, later filled in.
  - `Full { rows, columns, rowsPercents, columnsPercents, cellChildMap, ... }` – used by priority grid and custom grids.

### 3.3 CalculateGridZones (generic grid → actual zones)

Core algorithm (from `LayoutConfigurator::CalculateGridZones`):

1. Compute pixel extents for rows:

   - Given work area height `H`, percentages `r[0..R-1]`:
     - Let `prefix = 0`.
     - For each row `k`:
       - `Start[k] = prefix * H / C_MULTIPLIER`.
       - `prefix += r[k]`.
       - `End[k] = prefix * H / C_MULTIPLIER`.
       - `Extent[k] = End[k] - Start[k]`.

2. Compute pixel extents for columns (`W`, `c[0..C-1]`) similarly.

3. Create zones using `cellChildMap`:

   - For each cell `(row, col)`:
     - Let `i = cellChildMap[row][col]`.
     - If `i < 0`: skip (no zone).
     - If this cell is the **top‑left** of a contiguous block of `i`:
       - Find maximal `maxRow >= row` such that all `cellChildMap[r][col] == i` for `row ≤ r ≤ maxRow`.
       - Find maximal `maxCol >= col` such that all `cellChildMap[row][c] == i` for `col ≤ c ≤ maxCol`.
       - Zone rectangle before spacing:
         - `top = rowStart[row]`, `bottom = rowEnd[maxRow]`.
         - `left = colStart[col]`, `right = colEnd[maxCol]`.

4. Apply spacing:

   For each zone:
   - Vertical spacing:
     - If `row == 0`: `top += spacing`.
       Else: `top += spacing / 2`.
     - If `maxRow == rows - 1`: `bottom -= spacing`.
       Else: `bottom -= spacing / 2`.
   - Horizontal spacing:
     - If `col == 0`: `left += spacing`.
       Else: `left += spacing / 2`.
     - If `maxCol == columns - 1`: `right -= spacing`.
       Else: `right -= spacing / 2`.

5. Validate and insert:

   - Create `Zone{RECT(left, top, right, bottom), id = i}`.
   - If `Zone.IsValid() == false`, abort and fail this layout.
   - If `ZoneId` duplicates an existing ID, also fail (zone IDs must be unique).

**Requirements**

- All math MUST be integer‑based (no accumulated floating error).
- The sum of all zone extents plus gaps MUST cover exactly the work area rectangle.
- Spacing MUST be symmetric: interior shared edges get half spacing from each neighbor, outer edges get full spacing vs work area border.

### 3.4 LayoutConfigurator::Grid

Given `zoneCount`:

1. **Determine rows and columns:**

   ```text
   rows = 1;
   while (zoneCount / rows >= rows) rows++;
   rows--;
   columns = zoneCount / rows;
   if (zoneCount % rows != 0) columns++;
   ```

   - This finds the largest `rows` such that `zoneCount / rows >= rows`, then decrements once.
   - Then `columns` is `ceil(zoneCount / rows)`.
   - This tends to produce near‑square grids.

2. **Compute row and column percentages:**

   For each row `r`:

   ```text
   rowsPercents[r] = C_MULTIPLIER * (r + 1) / rows
                     - C_MULTIPLIER * r / rows
   ```

   Similarly for columns with `columns`.

3. **Fill cellChildMap:**

   - Initialize each row as vector of length `columns`.
   - Set `cellChildMap[row][col] = index++` in row‑major order.
   - If `index == zoneCount`, keep `index--` (repeat the last zone index for remaining cells).
     - This merges extra cells into the last zone when `rows * columns > zoneCount`.

4. Call `CalculateGridZones(workArea, gridLayoutInfo, spacing)`.

**Requirements**

- Must produce `zoneCount` distinct IDs in `ZonesMap` even if `rows * columns > zoneCount` (via merging).
- Grid must use full work area with configured spacing.

### 3.5 LayoutConfigurator::Rows

1. Preconditions: `zoneCount > 0`.

2. Compute:

   ```text
   totalWidth  = workArea.width  - 2 * spacing
   totalHeight = workArea.height - spacing * (zoneCount + 1)
   top = spacing
   left = spacing
   ```

3. For each row index `i` in `[0, zoneCount)`:

   ```text
   right = totalWidth + spacing   // full width minus left/right spacing
   bottom = top
          + ((i + 1) * totalHeight / zoneCount
             - i * totalHeight / zoneCount)
   Zone = [left, top, right, bottom]
   top = bottom + spacing
   ```

**Requirements**

- All rows span identical width and partition height as equal as possible via cumulative integer fractions.
- Outer and inner vertical spacings exactly match the chosen `spacing` semantics.

### 3.6 LayoutConfigurator::Columns

Mirrors `Rows`:

- Subtract `spacing * (zoneCount + 1)` from width instead of height.
- Each zone spans entire height and partitions width using the same cumulative fraction trick.

### 3.7 LayoutConfigurator::Focus

- Produces a focus layout: typically a primary centered zone (or repeated focus zones) using a fixed proportion of the work area (e.g., 40% width × 40% height).
- Additional zones (if `zoneCount > 1`) are offset diagonally by fixed increments.

**Requirements**

- Primary zone must be centered and sized at a consistent fraction of work area.
- Additional zones must be offset by fixed pixel increments (e.g., 50 px) relative to previous.

### 3.8 LayoutConfigurator::PriorityGrid

- For `zoneCount <= 11`, uses **predefined** `GridLayoutInfo` objects:

  - Specific:
    - `rows`, `columns`
    - `rowsPercents`, `columnsPercents`
    - `cellChildMap`
  - These are tuned to create layouts with larger “priority” zones and smaller adjunct zones.

- For `zoneCount > 11`:
  - Fallback to standard `Grid` algorithm.

**Requirements**

- Given `zoneCount ∈ [1, 11]`, the layout geometry MUST match the predefined tables.
- For `zoneCount > 11`, behavior MUST match `Grid` exactly.

### 3.9 Custom Layouts (Canvas & Custom Grid)

`LayoutConfigurator::Custom(workArea, monitor, zoneSet, spacing)`:

- If `zoneSet.type == Canvas`:
  - Treat `zoneSet.info` as a list of rectangles:
    - Stored at some `lastWorkAreaWidth / Height` reference size.
  - Scale each zone:

    ```text
    scaled_x      = zone.x      * workArea.width  / lastWorkAreaWidth
    scaled_y      = zone.y      * workArea.height / lastWorkAreaHeight
    scaled_width  = zone.width  * workArea.width  / lastWorkAreaWidth
    scaled_height = zone.height * workArea.height / lastWorkAreaHeight
    ```

  - Apply DPI conversions as appropriate to platform.
  - Rectangles are used directly as zones without any grid semantics.

- If `zoneSet.type == Grid` with `GridLayoutInfo` variant:
  - Call `CalculateGridZones` with that info.

**Requirements**

- Canvas layouts MUST preserve relative proportions under work area resizing.
- Grid custom layouts MUST respect their specified row/column percentages and cell map.

---

## 4. Hit‑Testing / Zone Selection by Point

### 4.1 Layout::ZonesFromPoint

Given a point `pt` (mouse position), returns a `ZoneIndexSet`:

1. Initialize two sets:
   - `capturedZones` – zones whose rectangles extended by `sensitivityRadius` contain `pt`.
   - `strictlyCapturedZones` – zones whose raw rectangles contain `pt`.

2. For each zone:
   - If `pt` lies within `[rect.left - radius, rect.right + radius] × [rect.top - radius, rect.bottom + radius]`:
     - Add zone ID to `capturedZones`.
   - If `pt` lies within the strict rect `[rect.left, rect.right) × [rect.top, rect.bottom)`:
     - Add zone ID to `strictlyCapturedZones`.

3. If `capturedZones.size() == 1` and `strictlyCapturedZones.size() == 0`:
   - Return empty set (avoid snapping to a zone that user is only near, not in).

4. Check for overlap among captured zones (considering `sensitivityRadius`):
   - If no overlap: return `capturedZones` (multi‑zone if the point legitimately intersects multiple disjoint zones).
   - If there is overlap:
     - Use an **overlapping zones algorithm** based on settings:
       - Smallest: choose smallest area zone.
       - Largest: choose largest area zone.
       - Positional: subdivide the overlapping region and choose based on pointer position.
       - ClosestCenter: choose zone whose center is nearest the pointer (ties broken by smaller zone).

**Requirements**

- Hit testing MUST respect `sensitivityRadius` from `LayoutData`.
- When zones overlap visually, the chosen algorithm must match the configured setting.

---

## 5. Window Snapping – Core Semantics

### 5.1 WorkArea::Snap

See §2.4 and §3: **multi‑zone** is implemented by passing a set of indices to `Snap`.

**Key requirements**

- `zones` parameter MUST be a non‑empty `ZoneIndexSet`.
- Each `zone` in `zones` MUST be valid for current layout.
- On success, `Snap` MUST:
  - Update in‑memory mapping: `LayoutAssignedWindows.Assign(window, zones)`.
  - Persist assignment to history and window properties.
  - If `updatePosition == true`:
    - Compute `GetCombinedZonesRect(zones)` – union of zone rectangles.
    - Resize/move the window to fill the union rectangle.

### 5.2 WorkArea::Unsnap

- Clears assignment for the window from this WorkArea.
- Removes zone index property from the window.
- Does NOT change window size or position automatically (unless additional policies are implemented).

---

## 6. Mouse‑Driven Snapping and Multi‑Zone Selection

### 6.1 WindowMouseSnap – Lifecycle

**Create(window, activeWorkAreas)**:

- Rejects:
  - Non‑processable windows (child windows, tool windows, etc.).
  - Elevated processes when runner is non‑elevated (on Windows; macOS analog should respect security model).
- Returns an instance for the active drag, or `nullptr` if FancyZones should not manage this drag.

**MoveSizeStart(monitor, isSnapping)**:

- Called when window move/resize begins.
- Identifies current WorkArea based on monitor.
- If `isSnapping == true`:
  - Enter snapping mode via `SwitchSnappingMode(true)`:
    - Apply transparency to dragged window (if setting enabled).
    - Show overlays:
      - Current work area (always).
      - All monitors (optionally, if `showZonesOnAllMonitors` is true).
  - Call `currentWorkArea->Unsnap(window)` so the window is free to move.

**MoveSizeUpdate(monitor, ptScreen, isSnapping, isSelectManyZonesState)**:

- Called on every mouse movement during drag.
- If `isSnapping == true`:
  - Update current WorkArea based on monitor; if changed:
    - Reset highlights and show/hide overlays appropriately.
  - Transform `ptScreen` into work area coordinates.
  - Use highlight manager (`m_highlightedZones`) to update selected zones:
    - Single or multiple, depending on `isSelectManyZonesState`:
      - When `isSelectManyZonesState == false`:
        - A single zone is chosen based on `ZonesFromPoint` and overlapping algorithm.
      - When `isSelectManyZonesState == true`:
        - Additional zones can be added/removed to form a multi‑zone set.
  - If highlight changed, call `ShowZones(highlightSet, window)` on the current WorkArea.

- `SwitchSnappingMode(isSnapping)` is called at the end, allowing on‑the‑fly toggling of snapping (user pressing/releasing snap key mid‑drag).

**MoveSizeEnd()**

- If `m_snappingMode == true`:
  - If window is maximized (certain edge cases): abort zoning (do nothing).
  - Else if `currentWorkArea` exists:
    - Call `currentWorkArea->Snap(window, highlightedZones)`:
      - `highlightedZones` is a `ZoneIndexSet` (possibly multi‑zone).
- Else (not in snapping mode):
  - Restore transparency and optionally restore window size from previous saved size (subject to settings).

**Requirements**

- Mouse snapping MUST operate only while the snap key is held (`isSnapping`).
- Multi‑zone selection MUST be enabled only when multi‑zone modifier is held (`isSelectManyZonesState`).
- At drag end, if highlight set is empty, window position MUST NOT be modified by FancyZones.

---

## 7. Keyboard‑Driven Snapping and Multi‑Zone Extension

Keyboard snapping acts through `WindowKeyboardSnap`, invoked from the FancyZones main WndProc when the user presses configured shortcuts.

### 7.1 Snap vs Extend (keyboard)

- **Snap key**: FancyZones keyboard shortcut (e.g., `Win+←/→` etc.).
- **Multi‑zone modifier** (keyboard): `Alt` key (VK_MENU) in this codebase.

**Dispatcher behavior**:

- If `Alt` is not pressed:
  - Call `WindowKeyboardSnap::Snap(...)` or `SnapHotkeyBasedOnZoneNumber(...)`.
- If `Alt` is pressed:
  - Call `WindowKeyboardSnap::Extend(...)`.

### 7.2 Snap (single‑zone keyboard snapping)

`WindowKeyboardSnap::Snap(window, windowRect, monitor, vkCode, activeWorkAreas, monitors)`:

- Clears previous extend state (`m_extendData.Reset()`).
- Finds current WorkArea from `activeWorkAreas` using `monitor`.
- If `moveWindowAcrossMonitors` setting is enabled:
  - Try to move by position on current monitor via `MoveByDirectionAndPosition`.
  - If that fails, attempt to snap on neighboring monitors, iterating list of monitors.
- `MoveByDirectionAndPosition(...)`:

  - Fetch current `layout`, `zones`, `layoutWindows`.
  - Determine zones the window already uses: `windowZones`.
  - Build list of candidate zones (`zoneRects`) that the window does **not** occupy.
  - Transform `windowRect` into work area coordinates.
  - Use `ChooseNextZoneByPosition(vkCode, windowRect, zoneRects)` to pick the next zone index.
  - If valid:
    - Snap to that single zone: `WorkArea::Snap(window, {freeZoneIndex[result]})`.
    - Record telemetry.

**Requirements**

- Snap key without Alt MUST assign exactly one zone per invocation.
- Candidate zones for movement MUST exclude those already occupied by the window (in this variant).
- Movement direction MUST be geometrically coherent (e.g., pressing left moves to zone whose center lies to the left).

### 7.3 Snap by Zone Number / Index

`WindowKeyboardSnap::SnapHotkeyBasedOnZoneNumber(...)` and `MoveByDirectionAndIndex`:

- Moves window through ordered list of zones by index (as opposed to position).
- If window has no zone:
  - First assignment is `zone = 0` or `zone = numZones-1` depending on direction.
- Else:
  - Uses index arithmetic and optional cycling to determine next zone index.
- Then calls `WorkArea::Snap(window, {zone})`.

**Requirements**

- Index‑based movement MUST be available as an alternative to spatial movement, matching configuration.
- When cycling is enabled, moving past first/last zone wraps around.

### 7.4 Extend (multi‑zone keyboard snapping)

`WindowKeyboardSnap::Extend(window, windowRect, vkCode, workArea)`:

- Precondition: `Alt` (multi‑zone modifier) is held.
- Behavior:

  1. Retrieve current layout and layoutWindows; abort if unavailable.
  2. Get current `appliedZones` for window (may be empty).
  3. Build `usedZoneIndices` array to exclude zones already part of the span.
  4. Handle two cases:
     - **First extend for this window**:
       - Use current window rectangle and layout geometry to choose an additional zone based on `vkCode` and relative position.
       - Create a new ZoneIndexSet that is the union of existing assigned zones and the new zone.
     - **Subsequent extensions** (same window, same session):
       - `m_extendData.IsExtended(window)` returns true:
         - Use stored `windowFinalIndex` to inform candidate selection (e.g., avoiding same zone).
         - Expand or shift the span to include a new zone and potentially exclude old ones (depending on behavior).
  5. Snap to the new **combined** ZoneIndexSet:
     - `WorkArea::Snap(window, combinedZones);`

- Extend session resets (sets `IsExtended == false`) when:

  - Non‑extend snap is performed.
  - Window is unsnapped or layout changes.
  - Code explicitly calls `m_extendData.Reset()` (in `Snap` paths and some layout changes).

**Requirements**

- Alt + snap key MUST cause windows to **span multiple zones** by building a ZoneIndexSet, not merely jump between single zones.
- Each key press MUST either:
  - Grow the span in the direction indicated by `vkCode`, or
  - Move the “active edge” of the span if logic dictates shifting rather than expanding.
- Window rectangle MUST always be resized to the union of all zones in the span (see §5.1).

---

## 8. Persistence & Restoration

### 8.1 Layout Persistence

- Layout definitions are stored in JSON (on Windows) with:
  - LayoutData (`uuid`, `type`, `spacing`, `zoneCount`, `sensitivityRadius`).
  - For grid layouts: `rows`, `columns`, `rowsPercents`, `columnsPercents`, `cellChildMap`.
  - For canvas layouts: zone rectangles and reference dimensions.

**Requirements**

- macOS implementation MUST persist equivalent information, in a stable format, so:
  - User layouts survive restart.
  - Layouts are portable across displays with different resolutions / scaling.

### 8.2 Window Assignment Persistence

- For each window:
  - Zone assignments (`ZoneIndexSet`) are stamped into properties (`StampZoneIndexProperty`).
  - `AppZoneHistory` stores last zone assignment per WorkArea + layout.

On startup or layout change:

- FancyZones enumerates windows on the current desktop and retrieves zone indices.
- According to settings:
  - If `spanZonesAcrossMonitors` is enabled:
    - There is a single effective WorkArea across displays:
      - `workArea->Snap(window, zones, false)` re‑assigns windows without moving them until geometry is recalculated.
  - Otherwise:
    - Each WorkArea reacquires windows that belong to it.

**Requirements**

- When reconfiguring monitors or virtual desktops:
  - Previously snapped windows MUST be re‑assigned to zones wherever possible.
  - Behavior when zones differ between old and new layout MUST be predictable (e.g., snapping to closest matching zone set).

---

## 9. macOS‑Specific Porting Considerations (Non‑Normative)

These are not strict requirements from the Windows code, but guidance for parity:

- Replace:
  - HWND → NSWindow identifiers.
  - HMONITOR / monitor handle → CGDirectDisplayID or NSScreen.
  - Virtual Desktop / Virtual Desktop ID → macOS Spaces IDs.
- Implement analogues for:
  - Getting window rects, adjusting for window decorations.
  - Making a window translucent while dragging (e.g., setting alpha).
  - Global keyboard hook for fancyzones shortcuts.
  - Global mouse drag tracking only when snap key is held.

The logical behaviors specified above MUST remain unchanged regardless of platform.

---

## 10. Test Cases for Feature Parity

This section outlines test scenarios to validate a macOS implementation against the behavior described above. Use real numbers for work area sizes (e.g., 1920×1080) but ensure tests are robust to different resolutions.

### 10.1 Layout Geometry

1. **Rows layout, even division**

   - Work area: 1000×1000 px; spacing: 0; zoneCount: 4; type: Rows.
   - Expected:
     - 4 zones, each 1000×250 px.
     - Combined height exactly 1000 px.
     - No gaps between zones; `top` of zones: 0, 250, 500, 750.

2. **Columns layout with spacing**

   - Work area: width 1200, height 800; spacing: 20; zoneCount: 3; type: Columns.
   - Expected:
     - `totalWidth = 1200 - (zoneCount+1)*spacing = 1200 - 80 = 1120`.
     - Zone widths derived by cumulative fraction:
       - W0 ≈ 1120/3 rounded pattern such that sum(W0, W1, W2) = 1120.
     - Zone rects:
       - Zone 0: left = 20; right = left + W0; top = 20; bottom = 780.
       - Zone 1: left = right_of_zone0 + 20; etc.
     - No over/underflow beyond work area.

3. **Grid layout rounding**

   - Work area: 1000×1000; zoneCount: 5; type: Grid; spacing: 0.
   - Verify:
     - `rows` and `columns` as per algorithm (rows=2, columns=3).
     - Some cells share zone indices; `ZonesMap.size() == 5`.
     - Sum of zone extents + gaps equals the entire work area.

4. **PriorityGrid small counts**

   - ZoneCount = 2..11, work area 1920×1080, spacing 10.
   - Check against predefined layouts from Windows:
     - One or more zones notably larger (higher priority).
     - Row/column distributions match stored percentages within integer arithmetic.

5. **Canvas layout scaling**

   - Store a canvas layout for a 1600×900 work area with zones at known relative positions.
   - Recreate layout in a 1920×1080 work area.
   - Verify:
     - Zones appear at correct scaled positions using ratio 1920/1600 and 1080/900.
     - Proportional relations (e.g., zone centered) maintained.

### 10.2 Mouse Snapping – Single Zone

6. **Basic mouse snap**

   - Layout: Grid with N zones.
   - Snap key held while dragging window over zone 3.
   - On mouse up:
     - Window assigned to `{3}`.
     - Window bounds equal zone 3 rect (with adjustments for decoration).
   - When moving again without snap key:
     - Window moves normally, not snapping.

7. **Sensitivity radius**

   - `sensitivityRadius = 10`.
   - Pointer at 5 px outside zone border:
     - If pointer not strictly inside any zone but within radius:
       - `capturedZones` may be nonempty.
       - If exactly 1 captured and 0 strictly captured → no snap.
   - Pointer 5 px inside border:
     - Zone should be strictly captured and thus selected.

### 10.3 Mouse Snapping – Multi‑Zone

8. **Multi‑zone drag span**

   - Layout: 2×2 grid (4 zones).
   - Drag with snap key + multi‑zone modifier over top‑left zone, then move into top‑right zone while still holding modifier.
   - Visual overlay:
     - Both top‑left and top‑right zones highlighted.
   - On mouse up:
     - Window assigned to `{0,1}` (or indexes of those zones).
     - Window bounds equal union of those two rects (top half of screen).

9. **Multi‑zone persistence**

   - After multi‑zone snap:
     - Move window without snap key; ensure it retains assigned zones (still snapped).
   - Trigger layout reload or restart app; ensure:
     - Window is reassigned to combined zones after restoration (if layout unchanged).

### 10.4 Keyboard Snapping – Single Zone

10. **Directional snap (no Alt)**

    - Layout: 3 columns (zones 0,1,2 left→right).
    - Window not assigned to any zone.
    - Press snap key + Right:
      - Window must move into leftmost zone first (or configured starting zone).
    - Press snap key + Right again:
      - Window moves to next zone to the right.
    - Press snap key + Right at rightmost zone with cycling disabled:
      - Window remains in rightmost zone.

11. **Index‑based cycling**

    - Same layout, index‑based snapping enabled.
    - Press snap key + Right repeatedly with cycling enabled:
      - Window cycles through zones 0→1→2→0→…

### 10.5 Keyboard Snapping – Multi‑Zone Extend

12. **Extend to neighboring zone**

    - Layout: 3 columns (0,1,2).
    - Snap window to zone 1 (middle) via keyboard (no Alt).
    - Hold Alt and press snap key + Right:
      - Window’s assigned zones become `{1,2}`.
      - Window expands to cover right two thirds of screen.
    - Hold Alt and press snap key + Left:
      - Depending on implementation, window either:
        - Expands to `{0,1,2}` OR
        - Shifts span `{0,1}` (implementation‑specific but should match Windows).
    - Releasing Alt and pressing snap key:
      - Ends extension session; subsequent snaps use single‑zone semantics.

13. **Extend session reset**

    - Start extend sequence (Alt + snap).
    - Press a plain snap (no Alt):
      - Window’s span becomes a single zone.
      - Subsequent Alt+snap sequences start new extension from that zone.

### 10.6 Cross‑Monitor Behavior

14. **Move across monitors**

    - Two displays with WorkAreas; `moveWindowAcrossMonitors` enabled.
    - Layout: identical on both.
    - Window initially snapped on monitor A.
    - Keyboard snap Right repeatedly until zones exhausted on A:
      - Implementation should attempt to snap to monitor B using geometry and direction.
    - Snap and extend behavior must remain consistent after crossing monitors.

15. **spanZonesAcrossMonitors**

    - Same monitors, `spanZonesAcrossMonitors` enabled.
    - Single WorkArea spanning displays, layout defined across full virtual rectangle.
    - Snap window to multiple zones that physically span both monitors.
    - Verify:
      - Geometry is coherent (zones may cross monitor boundaries).
      - Window occupancy and history handle cross‑monitor zones.

---

## 11. Acceptance Criteria

For a macOS implementation to be considered feature‑parity:

1. All layout types (Focus, Rows, Columns, Grid, PriorityGrid up to 11 zones, Custom Canvas and Custom Grid) must:
   - Generate zone rectangles using math equivalent to this spec.
   - Respect `showSpacing`, `spacing`, `zoneCount`, and `sensitivityRadius`.

2. Mouse snapping must:
   - Use a snap key and multi‑zone modifier key with behavior identical to §6.
   - Correctly highlight and snap to single or multiple zones.

3. Keyboard snapping must:
   - Support directional and index‑based snapping.
   - Use a multi‑zone modifier (Alt equivalent) to extend spans across multiple zones.

4. Multi‑zone spans must:
   - Be represented as sets of zone indices.
   - Resize windows to the union of the zones’ rectangles.
   - Persist across restarts and layout reinitializations.

5. All listed test cases (§10) MUST pass under equivalent conditions on macOS.

