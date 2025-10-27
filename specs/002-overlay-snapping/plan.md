# Implementation Plan: Overlay + Snapping

**Branch**: `002-overlay-snapping` | **Date**: 2025-10-25 | **Spec**: [specs/002-overlay-snapping/spec.md]
**Input**: Feature specification from `/specs/002-overlay-snapping/spec.md`

## Summary

Implement a transparent, floating grid overlay for macOS window management. Users can trigger the overlay via Shift+drag or keyboard shortcut, select zones, and snap windows. Multi-window selection is supported via Command modifier. Layouts are persisted as JSON. All operations use Accessibility APIs and run locally/offline with minimal CPU impact.

## Technical Context

**Language/Version**: Swift 5.x, AppKit (macOS)
**Primary Dependencies**: AppKit, Accessibility API
**Storage**: JSON files under `~/Library/Application Support/FracTile/`
**Testing**: XCTest (unit), manual accessibility checks
**Target Platform**: macOS 12+
**Project Type**: Desktop app
**Performance Goals**: Overlay shows/hides in <100ms; snap completes in <200ms
**Constraints**: No persistent background CPU-heavy processes; must run offline; accessibility compliance
**Scale/Scope**: Single-user desktop utility

## Constitution Check

- User control and simplicity: Overlay is always user-triggered, automation is opt-in.
- Visual clarity: Overlay is lightweight, unobtrusive, and dismissible.
- Accessibility-first: All UI and window actions use Accessibility APIs only; no private APIs.
- Open/modular: Layouts and event hooks are documented for future extension.

## Project Structure

### Documentation (this feature)
```
specs/002-overlay-snapping/
├── plan.md
├── spec.md
├── tasks.md
├── checklists/
```
### Source Code (repository root)
```
macos/FracTile/
├── AppDelegate.swift
├── OverlayWindowController.swift
├── WindowManager.swift
├── ZoneConfigurator.swift
├── EventController.swift
├── PreferencesUI.swift
├── Models/
│   ├── Layout.swift
│   ├── Zone.swift
│   └── Preference.swift
├── Tests/
│   └── OverlayTests.swift
```
**Structure Decision**: Single desktop app project under `macos/FracTile/` with modular controllers and models.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None      |            |                                     |
