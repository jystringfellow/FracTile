# Tasks: Overlay + Snapping

**Input**: Design documents from `/specs/002-overlay-snapping/`
**Prerequisites**: plan.md, spec.md

## Phase 1: Setup (Shared Infrastructure)
 - [x] T001 Create `app/Sources/` and `app/Resources/` project structure
 - [x] T002 Initialize Swift AppKit project in `app/FracTile.xcodeproj`
 - [x] T003 Configure linting and formatting tools (SwiftLint)

---

## Phase 2: Foundational (Blocking Prerequisites)
 - [X] T004 Implement Accessibility API wrapper in `app/Sources/WindowManager.swift`
 - [X] T005 Create basic `app/Sources/OverlayWindowController.swift` with transparent grid overlay
 - [X] T006 Implement `app/Sources/ZoneConfigurator.swift` for layout definition and JSON persistence
 - [X] T007 Setup event monitoring in `app/Sources/EventController.swift` (Shift+drag, Command multi-select)
 - [X] T008 Create `app/Sources/PreferencesUI.swift` for menu bar controls
 - [X] T028 Additional unit tests in `app/Tests/FracTileTests.swift`
---

## Phase 3: User Story 1 - Trigger overlay & snap window (Priority: P1)
 - [X] T009 Show overlay on Shift+drag or shortcut
 - [X] T010 Detect zone selection via mouse/keyboard
 - [X] T011 Snap focused window to selected zone
 - [X] T012 Dismiss overlay on escape or completion
 - [X] T013 Add accessibility labels and keyboard navigation

---

## Phase 4: User Story 2 - Multi-window snapping (Priority: P2)
 - [X] T014 Support Command modifier for multi-window selection
 - [X] T015 Map selected windows to zones
 - [X] T016 Confirm batch snap and update overlay

---

## Phase 5: User Story 3 - Persist & reuse layouts (Priority: P3)
 - [X] T017 Save custom layouts as JSON
 - [X] T018 Load layouts on startup
 - [X] T019 Switch layouts via Preferences UI

---

## Phase 6: Accessibility & Edge Cases
 - [X] T020 Test keyboard/VoiceOver navigation
 - [X] T021 Handle multiple displays and scaling
 - [X] T022 Fallback for restricted/system windows
 - [X] T023 Hotkey conflict detection and rebinding
 - [X] T024 Minimum zone size fallback

---

## Phase 7: Polish & Cross-Cutting Concerns
 - [X] T025 Documentation updates
 - [X] T026 Code cleanup and refactoring
 - [X] T027 Performance optimization
 - [X] T028 Additional unit tests in `Tests/OverlayTests.swift`
 - [X] T029 Security/privacy review
