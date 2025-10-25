# FracTile Constitution

## Project

**Name**: FracTile

**Mission**:
To bring flexible, grid-based window management to macOS. FracTile empowers
users to create, visualize, and snap windows into customizable fractal-like
layouts that adapt to their workflow.

## Core Principles

### 1. User control and simplicity over automation
Users MUST remain in control; automation is an assist, not the default. Features
shall expose simple controls and undo paths. Complex automation MUST be opt-in
and clearly visible. Rationale: predictable UI behavior reduces friction and
avoids surprising users.

### 2. Visual clarity through lightweight, unobtrusive overlays
UI overlays and indicators MUST be minimal, non-blocking, and dismissible. Any
visual affordance MUST prioritize legibility and avoid obscuring important
content. Rationale: overlays should aid workflows without distracting from the
primary task.

### 3. Accessibility-first interaction (no private APIs)
Designs and implementations MUST prioritize accessibility (VoiceOver, keyboard
navigation, high-contrast modes) and MUST NOT rely on private or unsupported
APIs. Rationale: accessibility broadens the user base and private APIs risk
stability and App Store rejection.

### 4. Open, modular, and hackable by design
The codebase and features SHOULD be modular with clear extension points. Public
APIs (or internal extension points) MUST be documented. Rationale: modularity
encourages contributions, experimentation, and long-term maintainability.

## Platform Constraints

- Must operate entirely within macOS Accessibility API boundaries.
- No persistent background CPU-heavy processes; prefer event-driven behavior.
- Must run locally, offline, and respect user privacy (no telemetry without
  explicit opt-in).
- Written primarily in Swift (AppKit-based) unless a compelling reason exists.

## Operational Constraints (brief)

- Secure defaults for any networked component (if introduced).
- Minimal privilege for helper processes and sandbox-friendly design where
  applicable.
- Dependency hygiene: prefer well-maintained Swift packages; review native
  dependencies for license and maintenance status.

## Development Workflow

- Planning: Features require a `spec.md` and `plan.md`; the plan MUST include a
  Constitution Check describing how the feature satisfies the Core Principles.
- Reviews: PRs that change UI/UX, public APIs, or add background work MUST
  include screenshots, accessibility notes, tests, and at least one maintainer
  approval.
- Quality Gates: CI MUST run unit tests and linting; fast integration checks
  for critical UI/behavior paths are encouraged.

## Governance

Amendments
- Propose amendments by opening a PR that modifies `.specify/memory/constitution.md`.
- The PR MUST include: rationale, migration plan for behavioral changes, and an
  explicit version bump suggestion (MAJOR/MINOR/PATCH) with reasoning.
- Approval: changes require approval from the project maintainers. If no
  maintainers are listed, the PR MUST name suggested approvers and request
  review from collaborators.

Versioning Policy
- The Constitution follows semantic versioning. Bump MAJOR for incompatible
  governance/principle removals or redefinitions, MINOR for new principles or
  material expansions, and PATCH for clarifications and non-semantic edits.

Compliance & Reviews
- PRs implementing features or infra MUST reference this Constitution and
  include a short compliance checklist (accessibility, privacy, CPU impact,
  dependency review).
- Periodic review: the Constitution SHOULD be reviewed annually or after any
  MAJOR governance change.

**Version**: 0.2.0 | **Ratified**: TODO(RATIFICATION_DATE): original adoption date unknown | **Last Amended**: 2025-10-25
