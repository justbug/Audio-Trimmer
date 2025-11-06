# Implementation Plan: Simulated Audio Trimming Demo

**Branch**: `001-audio-trim-sim` | **Date**: 2025-11-06 | **Spec**: `specs/001-audio-trim-sim/spec.md`
**Input**: Feature specification from `/specs/001-audio-trim-sim/spec.md`

## Summary

Implement the audio trimming simulator logic as a pure TCA reducer using dummy data, enforcing configuration validation, simulated countdown playback with play/pause/resume, and deterministic timer effects covered by `TestStore` tests. UI construction is explicitly deferred; this iteration delivers the underlying state machine and tests so future SwiftUI views can bind directly to it.

## Technical Context

**Language/Version**: Swift 5.10 (Swift 5.9+ compatible with current toolchain)  
**Primary Dependencies**: The Composable Architecture 1.23.0, Swift `Clock` APIs  
**Storage**: N/A (in-memory simulation only)  
**Testing**: Swift `Testing` package with TCA `TestStore`, `ImmediateClock` overrides  
**Target Platform**: iOS 17+ (logic in Swift package reusable across platforms)  
**Project Type**: Swift Package powering an iOS wrapper (Audio Trimmer app)  
**Performance Goals**: Timer ticks emitted precisely at 1 Hz with <0.2 s drift under deterministic clocks  
**Constraints**: No real audio processing; effects must be cancellable and main-thread safe  
**Scale/Scope**: Single feature reducer plus unit test coverage within existing App package

## Constitution Check

- **Composable Architecture Discipline**: Reducer will live at `App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift` with clearly defined `@ObservableState`, `Action`, and effect body. Dummy data is injected through state initialisers and dependencies. No child navigation required; future UI will scope into this reducer.
- **Test-Driven Reliability**: Plan enforces red-green loop via `TestStore` cases covering play, pause, resume, validation, and timer cancellation using `ImmediateClock` and dependency overrides to assert effect lifecycles before shipping.
- **Consistent & Accessible UX**: Although UI is postponed, we will document expected bindings, accessibility labels, and state exposures so the upcoming UI work can satisfy VoiceOver and Dynamic Type requirements without refactoring the reducer.
- **Performance & Efficiency Guarantees**: Simulated playback uses a cancellable timer effect keyed by a `TimerID`, ensuring no overlapping timers. Deterministic tests plus instrumentation hooks (e.g., optional logging dependency) keep countdown work off the main thread where feasible.
- **Code Quality & Review Integrity**: Implementation will conform to Swift formatting, expose only necessary types public, include inline comments for complex timer handling, and update documentation/tests so reviewers can verify reducer behaviour quickly.

All gates satisfied; proceed to Phase 0 research.

## Project Structure

### Documentation (this feature)

```text
specs/001-audio-trim-sim/
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
```text
Audio Trimmer/App/
├── Package.swift
├── Sources/
│   └── App/
│       ├── Features/
│       │   └── AudioTrimmer/
│       │       ├── AudioTrimmerFeature.swift          # New reducer + dummy data
│       │       └── Dependencies/                      # (If needed) shared clients
│       ├── SharedUI/                                  # Existing shared components (unused this iteration)
│       └── Support/                                   # Utilities
└── Tests/
    └── AppTests/
        └── AudioTrimmerTests.swift                    # New TestStore coverage
```

**Structure Decision**: Follow existing TCA layout under `Features`, creating `AudioTrimmer` folder with reducer and optional dependency definitions; tests live under mirrored path in `AppTests`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
