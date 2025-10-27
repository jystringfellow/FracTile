# Tasks: Overlay + Snapping

**Input**: Design documents from `/specs/002-overlay-snapping/`
**Prerequisites**: plan.md, spec.md

## Phase 1: Setup (Shared Infrastructure)
 - [x] T001 Create `app/Sources/` and `app/Resources/` project structure
 - [x] T002 Initialize Swift AppKit project in `app/FracTile.xcodeproj`
 - [ ] T003 Configure linting and formatting tools

---
 - [ ] T004 Implement Accessibility API wrapper in `app/Sources/WindowManager.swift`
 - [ ] T005 Create basic `app/Sources/OverlayWindowController.swift` with transparent grid overlay
 - [ ] T006 Implement `app/Sources/ZoneConfigurator.swift` for layout definition and JSON persistence
 - [ ] T007 Setup event monitoring in `app/Sources/EventController.swift` (Shift+drag, Command multi-select)
 - [ ] T008 Create `app/Sources/PreferencesUI.swift` for menu bar controls
- [ ] T007 Setup event monitoring in `EventController.swift` (Shift+drag, Command multi-select)
- [ ] T008 Create `PreferencesUI.swift` for menu bar controls
 - [ ] T028 Additional unit tests in `app/Tests/FracTileTests.swift`
---

## Phase 3: User Story 1 - Trigger overlay & snap window (Priority: P1)
- [ ] T009 Show overlay on Shift+drag or shortcut
- [ ] T010 Detect zone selection via mouse/keyboard
- [ ] T011 Snap focused window to selected zone
- [ ] T012 Dismiss overlay on escape or completion
- [ ] T013 Add accessibility labels and keyboard navigation

---

## Phase 4: User Story 2 - Multi-window snapping (Priority: P2)
- [ ] T014 Support Command modifier for multi-window selection
- [ ] T015 Map selected windows to zones
- [ ] T016 Confirm batch snap and update overlay

---

## Phase 5: User Story 3 - Persist & reuse layouts (Priority: P3)
- [ ] T017 Save custom layouts as JSON
- [ ] T018 Load layouts on startup
- [ ] T019 Switch layouts via Preferences UI

---

## Phase 6: Accessibility & Edge Cases
- [ ] T020 Test keyboard/VoiceOver navigation
- [ ] T021 Handle multiple displays and scaling
- [ ] T022 Fallback for restricted/system windows
- [ ] T023 Hotkey conflict detection and rebinding
- [ ] T024 Minimum zone size fallback

---

## Phase 7: Polish & Cross-Cutting Concerns
- [ ] T025 Documentation updates
- [ ] T026 Code cleanup and refactoring
- [ ] T027 Performance optimization
- [ ] T028 Additional unit tests in `Tests/OverlayTests.swift`
- [ ] T029 Security/privacy review
