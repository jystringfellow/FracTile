# Feature Specification: Overlay + Snapping (overlay-snapping)

**Feature Branch**: `001-overlay-snapping`
**Created**: 2025-10-25
**Status**: Draft
**Input**: System components and interfaces provided by user (see below)

---

## System Summary

This feature implements a lightweight, accessible overlay-driven window
management experience for macOS (FracTile). It introduces an overlay grid UI
that users can trigger via drag+modifier and keyboard shortcuts to snap one or
multiple windows into configurable zone layouts. It focuses on local (offline)
operation, adherence to macOS Accessibility boundaries, and low CPU impact.

### Provided system components

- overlay_window:
  - Displays a transparent, floating grid overlay that users can configure.
  - Handles mouse hover and click detection for zone selection.
- window_manager:
  - Interacts with macOS Accessibility APIs to query, move, and resize windows.
  - Supports snapping to one or multiple zones.
- zone_configurator:
  - Allows the user to define and persist custom layouts (rows, columns, or
    fractal patterns).
  - Stores data in JSON under `~/Library/Application Support/FracTile/`.
- event_controller:
  - Listens for key/mouse combinations (e.g. Shift+Drag) to trigger snapping
    overlay. Uses global event monitors.
- preferences_ui:
  - Menu bar interface for selecting layouts, toggling snapping, and setting
    hotkeys.

### Interfaces

User-facing:
- Drag + modifier key to trigger overlay
- Modifier key to allow selecting multiple zones
- Keyboard shortcuts for snapping
- Menu bar dropdown for quick layout switching

Developer-facing:
- JSON schema for layouts
- Event hooks for extensions (future goal)

---

## User Scenarios & Testing (mandatory)

### User Story 1 - Trigger overlay & snap window (Priority: P1)
A single-window user flow for snapping a window into a chosen zone.

**Why this priority**: This is the core interaction delivering the primary
value of FracTile: fast, predictable window arrangement.

**Independent Test**: User can open overlay, select a zone, and the window
is positioned accordingly.

**Acceptance Scenarios**:

1. **Given** a user has a focused window and hovers/presses the modifier key
   while dragging the window, **When** the user releases the drag on a zone,
   **Then** the window snaps to that zone and the overlay hides.
2. **Given** a user opens the overlay via a keyboard shortcut, **When** the
   user selects a zone with keyboard navigation and confirms, **Then** the
   focused window snaps to the selected zone.

---

### User Story 2 - Multi-window snapping (Priority: P2)
Allow selecting multiple windows and snapping them to multiple zones.

**Why this priority**: Improves productivity for multi-window workflows.

**Independent Test**: User selects multiple windows and maps them to zones in a
single interaction.

**Acceptance Scenarios**:

1. **Given** a user holds the multi-select modifier and clicks additional
   windows, **When** the user confirms zone assignment, **Then** all selected
   windows are placed into the chosen zones in a deterministic order.

---

### User Story 3 - Persist & reuse layouts (Priority: P3)
Users define, save, and switch between custom layout presets.

**Why this priority**: Enables repeatable workflows and personalization.

**Independent Test**: User saves a layout and can re-apply it later via the
menu bar UI.

**Acceptance Scenarios**:

1. **Given** a user configures a layout in the zone configurator and saves it,
   **When** the user selects that layout from the menu bar, **Then** the overlay
   shows the saved layout and snapping uses that configuration.

---

### Accessibility Scenarios (mandatory)

1. **Given** a user who relies on keyboard or VoiceOver, **When** they open the
   overlay, **Then** they can navigate zones and confirm assignments via
   keyboard with appropriate screen-reader announcements.

2. **Given** high-contrast or large-text settings, **When** the overlay renders,
   **Then** contrast and sizing meet accessibility readability requirements.

---

## Functional Requirements (testable)

- FR-001: The system MUST display an overlay grid when the user performs Drag
  + modifier or activates the assigned keyboard shortcut.
- FR-002: The system MUST allow single-window snapping: focused window snaps to
  a selected zone upon confirm action.
- FR-003: The system MUST support multi-window selection and batch snapping
  when the multi-select modifier is used.
- FR-004: The system MUST persist user-defined layouts as JSON under
  `~/Library/Application Support/FracTile/` and load them on startup.
- FR-005: The overlay MUST be dismissible without performing an action (escape
  key or alternate gesture) leaving windows unchanged.
- FR-006: The overlay and snapping flows MUST provide accessible labels and
  keyboard navigation compliant with VoiceOver.
- FR-007: The system MUST avoid using private macOS APIs and operate within
  Accessibility API boundaries.
- FR-008: The system MUST not run persistent CPU-heavy background processes;
  background helpers MUST be event-driven or idle when unused.
- FR-009: Preferences UI MUST allow selecting a saved layout, toggling snapping,
  and configuring hotkeys.

## Key Entities

- Layout
  - id, name, grid/zone definitions, layout metadata
- Zone
  - coordinates relative to screen/space, size, label
- WindowAction
  - mapping of a window to a zone, ordering for multi-window snaps
- Preference
  - hotkeys, default modifier, quick-switch bindings
- Event
  - user inputs (drag, modifiers, keyboard) and lifecycle events for overlay

## Success Criteria (measurable & user-focused)

- SC-001: Primary snap flow is completed by users in 3 or fewer interactions
  (trigger overlay → select zone → confirm) for 95% of successful tests.
- SC-002: Overlay shows and responds to selection input with latency low enough
  that perceived responsiveness is immediate to users (qualitative: users do
  not report lag in a short usability test — quantitative measurements can be
  added during implementation tests).
- SC-003: 95% of acceptance tests for accessibility scenarios pass (keyboard
  navigation + screen-reader announcements) in the test suite.
- SC-004: Saved layouts persist and re-apply successfully in 100% of automated
  load/save unit tests in CI (storage and parsing correctness).
- SC-005: CPU usage remains negligible when idle (no persistent heavy background
  process) as measured by helper process monitoring during integration tests.

## Edge Cases

- Multiple displays with different resolutions and scaling factors.
- Application windows that opt out of accessibility control or are system-owned
  (where movement/resizing is restricted).
- Conflicting global hotkeys and modifier keys set by other apps — fallback
  and rebind behavior required.
- Snap target too small for minimum window size — define fallback behavior.

## Assumptions

- Users expect local-only operation; no telemetry will be collected without
  explicit opt-in.
 - Default modifiers: Shift to trigger the overlay; Command for multi-select.
   Hotkeys and modifiers are configurable in Preferences.
- Layout JSON format and schema will be versioned to support future changes.

## Data & Storage

- Layouts persisted as JSON under `~/Library/Application Support/FracTile/`.
- Stored artifacts MUST include a schema version and migration strategy.

## Developer Notes / Extension Points

- Provide a JSON schema for layouts and document event hooks for possible
  extensions (future work).
- Ensure code paths are testable with mock Accessibility responses for CI.

---

**Spec file path**: `specs/001-overlay-snapping/spec.md`

