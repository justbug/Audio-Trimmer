# Implementation Plan: Track Settings Entry Page

**Branch**: `001-track-settings` | **Date**: 2025-11-10 | **Spec**: `specs/001-track-settings/spec.md`  
**Input**: Feature specification from `/specs/001-track-settings/spec.md`

## Summary

Create a new SwiftUI entry screen backed by a TCA reducer for configuring a trimming session. Users input: total track length, key time percentages (multiple), clip start, and clip percent. On Confirm, the reducer validates inputs, converts clip percent to seconds for `clipDuration`, constructs `TrackConfiguration`, and navigates to the trimming experience. The UI stays “dumb”; all validation and mapping live in the reducer to align with TCA best practices.

## Technical Context

**Language/Version**: Swift 5.10  
**Primary Dependencies**: The Composable Architecture 1.23.0, Swift `Clock` APIs  
**Storage**: N/A (in-memory only)  
**Testing**: Swift `Testing` + TCA `TestStore` with deterministic clocks  
**Target Platform**: iOS 17+ (logic in Swift package)  
**Project Type**: Mobile Swift Package powering an iOS app target  
**Performance Goals**: Validation and navigation feel instant (<100 ms perceived)  
**Constraints**: No real audio processing here; keep UI responsive, effects cancelable  
**Scale/Scope**: One new feature module (`TrackSettings`) + integration with existing `AudioTrimmer`

## Constitution Check

- **Composable Architecture Discipline**:  
  - New feature folder: `App/Sources/App/Features/TrackSettings/` with `TrackSettingsFeature` (`@Reducer`) and `TrackSettingsView`.  
  - State holds raw text fields and derived validation errors. Side effects limited to navigation and optional lightweight analytics.  
  - Parent composition: introduce a lightweight `AppRootFeature` to own navigation between `TrackSettings` and `AudioTrimmer`. Use `NavigationStackStore` to push `AudioTrimmer` with configuration.
- **Test-Driven Reliability**:  
  - `TestStore` coverage for: valid submission builds expected `TrackConfiguration` and triggers navigation; each validation rule blocks Confirm and surfaces field-specific errors; key time normalization (0–100 clamp, sort, de-dup).  
  - Scheduler overrides for any debounce (if added) remain deterministic.
- **Consistent & Accessible UX**:  
  - Clearly labeled fields with helper text (e.g., “Clip percent is of total track length”).  
  - Inline error prompts near fields; Confirm disabled when invalid.  
  - Previews demonstrating common/edge cases.
- **Performance & Efficiency Guarantees**:  
  - No long-running effects; all operations synchronous in reducer.  
  - Navigation creation is cheap; state handoff to `AudioTrimmer` is pure.
- **Code Quality & Review Integrity**:  
  - Swift API guidelines followed; feature encapsulated; no business logic in view.  
  - Public exposure only where required for reuse.  
  - Documentation inline only for non-obvious validations and normalization.

All gates pass for planning.

## Project Structure

### Documentation (this feature)

```text
specs/001-track-settings/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
```text
Audio Trimmer/App/
├── Sources/
│   └── App/
│       ├── Features/
│       │   ├── TrackSettings/
│       │   │   ├── TrackSettingsFeature.swift
│       │   │   └── TrackSettingsView.swift
│       │   └── AudioTrimmer/
│       │       ├── AudioTrimmerFeature.swift
│       │       └── AudioTrimmerView.swift
│       ├── Models/
│       │   └── TrackConfiguration.swift
│       └── RootView.swift   # to be updated to present TrackSettings first
└── Tests/
    └── AppTests/
        ├── TrackSettingsTests.swift
        └── AudioTrimmerTests.swift
```

**Structure Decision**: Introduce `TrackSettings` as a first-screen feature and update `RootView` (or a new `AppRootFeature`) to compose navigation to `AudioTrimmer`. Keep validation/mapping in `TrackSettingsFeature`; keep `AudioTrimmerFeature` unchanged and consume `TrackConfiguration` as-is.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
