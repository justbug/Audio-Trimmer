# Implementation Plan: Simulated Audio Trimming Demo

**Branch**: `001-audio-trim-sim` | **Date**: 2025-11-06 | **Spec**: `specs/001-audio-trim-sim/spec.md`
**Input**: Feature specification from `/specs/001-audio-trim-sim/spec.md`

## Summary

Implemented the audio trimming simulator logic as a pure TCA reducer with configuration loading via dependency injection, simulated countdown playback with play/pause/reset controls, and deterministic timer effects covered by `TestStore` tests. The reducer uses `PlaybackState` (not `PlaybackSimulation`) and `TimelineSnapshot` for derived state. Configuration is loaded asynchronously via `ConfigurationLoader` dependency pattern. Resume functionality is handled by `.playTapped` when status is paused or finished. UI construction is explicitly deferred; this iteration delivers the underlying state machine and tests so future SwiftUI views can bind directly to it.

**Note**: User Story 3 (configuration editing actions like `.updateClipStart`, `.updateClipDuration`, `.updateKeyTimes`) was not implemented. Configuration is loaded via the `ConfigurationLoader` dependency rather than edited interactively.

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

- **Composable Architecture Discipline**: Reducer lives at `App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift` with clearly defined `@ObservableState` (containing `configuration`, `playbackState`, `timeline`), `Action` enum, and effect body. Configuration is loaded via `ConfigurationLoader` dependency. `ConfigurationLoader` is defined in `ConfigurationLoader.swift` with `liveValue` and `testValue` implementations. No child navigation required; future UI will scope into this reducer.
- **Test-Driven Reliability**: Implementation includes `TestStore` cases covering play, pause, reset, configuration loading, and timer cancellation using `TestClock` and dependency overrides to assert effect lifecycles.
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
│       │       ├── AudioTrimmerFeature.swift          # Reducer with PlaybackState, TimelineSnapshot
│       │       └── ConfigurationLoader.swift          # Dependency for async configuration loading
│       ├── Models/
│       │   └── TrackConfiguration.swift                # Track configuration model with computed properties
│       ├── Extensions/
│       │   └── Double+Clamping.swift                  # Double.clamped() extension for normalization
│       └── App.swift                                   # Main app entry point
└── Tests/
    └── AppTests/
        └── AudioTrimmerTests.swift                    # TestStore coverage for playback and loading
```

**Structure Decision**: Follow existing TCA layout under `Features`, creating `AudioTrimmer` folder with reducer and optional dependency definitions; tests live under mirrored path in `AppTests`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
