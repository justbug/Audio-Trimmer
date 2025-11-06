# Feature Specification: Simulated Audio Trimming Demo

**Feature Branch**: `001-audio-trim-sim`  
**Created**: 2025-11-06  
**Status**: Draft  
**Input**: User description: "Simulate an audio track trimming demo without real audio. Let users input mock track data—total length, multiple chorus key times (as percentages of track length), and a fixed clipping window (e.g., trim 10 seconds, from second 5 to second 15). After entering the track info, pressing play starts simulated playback that advances once per second (for example, with a 10-second clip the countdown decreases each second). Provide a pause button that halts the simulation and can resume later."

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently

  For each story, identify the reducers, actions, and effects involved, and describe
  how the Swift Composable Architecture `TestStore` will validate the flow before implementation.
  Include accessibility and performance acceptance criteria when user interactions are involved.
-->

### User Story 1 - Configure and Play Clip Simulation (Priority: P1)

The producer configures track length, selects a 10-second clip window, reviews key time markers, and presses play to simulate countdown playback until the clip ends.

**Why this priority**: Delivers the core demo—without being able to simulate playback, the feature has no value.

**Independent Test**: `TestStore` drives `.playTapped` and `.tick` actions with a mocked `ContinuousClock`, asserting state transitions from idle → playing → finished and that countdown reaches zero exactly after the configured duration.

**Acceptance Scenarios**:

1. **Given** track length 120 seconds, clip start 5 seconds, clip duration 10 seconds, **When** the user taps play, **Then** the reducer enters `playing`, schedules 10 ticks, decrements remaining seconds each tick, and stops exactly at clip end.
2. **Given** key time markers at 25% and 75%, **When** playback runs, **Then** the UI surfaces absolute timestamps (e.g., 30s, 90s) aligned with the simulated current position without drift beyond 0.5 seconds.

---

### User Story 2 - Pause and Resume Simulation (Priority: P2)

The producer starts playback, pauses midway, confirms countdown halts, and resumes to finish the clip without resetting progress.

**Why this priority**: Provides realistic interaction for demonstrating control responsiveness and is the next most critical user expectation after basic playback.

**Independent Test**: `TestStore` sends `.playTapped`, advances time to trigger ticks, dispatches `.pauseTapped`, verifies cancellation of the timer effect, then `.resumeTapped` and confirms ticks resume from the persisted current second.

**Acceptance Scenarios**:

1. **Given** playback running with 6 seconds remaining, **When** pause is tapped, **Then** the reducer switches to `paused`, cancels further ticks, and the remaining time display holds steady.
2. **Given** playback paused at 4 seconds remaining, **When** resume is tapped, **Then** the reducer re-schedules ticks and playback completes in exactly 4 additional seconds without repeating earlier timeline events.

---

### User Story 3 - Adjust Markers and Clip Window (Priority: P3)

The producer edits key time percentages and clip window values, observing immediate validation feedback and updated timeline markers before starting playback.

**Why this priority**: Ensures the simulator visual accurately reflects new configurations, enabling iterative demo setup.

**Independent Test**: `TestStore` exercises `.updateKeyTimes`, `.updateClipStart`, and `.updateClipDuration` actions, asserting normalized, sorted marker output and validation flags toggled in state without entering playback.

**Acceptance Scenarios**:

1. **Given** the user enters key times 70%, 20%, **When** the configuration is saved, **Then** the reducer sorts them ascending, clamps values to 0–100, and exposes derived absolute timestamps.
2. **Given** clip start 80 seconds and duration 15 seconds on a 120-second track, **When** the user submits the form, **Then** validation forces the clip end to 120 seconds and surfaces an inline warning until the inputs are corrected.

---

### Edge Cases

- Track length below minimum (≤ 0 seconds) blocks playback and surfaces inline validation.
- Clip duration exceeding track length causes auto-clamping to track end and highlights the offending field until corrected.
- Duplicate or out-of-range key time percentages are deduplicated and capped at 0–100 while warning the user about adjustments.
- Timer drift: ensure the simulated clock ticks pause when app moves to background and catches up without skipping when resumed.
- VoiceOver focus while countdown updates: labels must not cause focus jumps when time remaining changes rapidly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST capture track length input between 1 and 3,600 seconds and reject values outside this range with inline validation.
- **FR-002**: System MUST accept a clip start offset and duration, enforcing that the resulting clip end does not exceed the configured track length.
- **FR-003**: System MUST allow entry of multiple key time percentages, normalize them to unique ascending values within 0–100, and surface derived absolute timestamps.
- **FR-004**: System MUST provide play, pause, and resume controls that reflect the current playback state and disable invalid transitions (e.g., disable play while already playing).
- **FR-005**: System MUST drive a simulated playback loop that emits one state update per second without relying on real audio files.
- **FR-006**: System MUST decrement the remaining playback time each tick, stop automatically at zero, and reset the current second to the clip start for future runs.
- **FR-007**: System MUST cancel scheduled ticks immediately when paused and resume from the stored current position without skipping or doubling ticks.
- **FR-008**: System MUST expose a read-only timeline model (including clip window and key markers) for SwiftUI to render progress indicators consistently during configuration and playback.

### Key Entities *(include if feature involves data)*

- **TrackConfiguration**: Represents user-defined settings comprising `totalDurationSeconds`, ordered `keyTimePercentages`, `clipStartSeconds`, and `clipDurationSeconds`; derives absolute marker times and validation errors.
- **PlaybackSimulation**: Captures runtime state including `status` (idle, playing, paused, finished), `currentSecond`, `remainingSeconds`, and the cancellable token for the active timer effect.

## Architecture & State Management *(mandatory)*

- **Feature Reducers**: Introduce `AudioTrimSimulatorFeature` annotated with `@Reducer`, owning `@ObservableState` fields for `TrackConfiguration`, `PlaybackSimulation`, form validation flags, and derived timeline models. Actions include configuration updates, `playTapped`, `pauseTapped`, `resumeTapped`, `tick`, and `onAppear`. Effects: `playTapped` starts a `ContinuousClock`-driven timer sending `.tick` every second until cancellation or completion; `pauseTapped` cancels via a stable `TimerID`.
- **Dependencies**: Leverage `Dependency(\.continuousClock)` to supply a `Clock` instance; override with `ImmediateClock` within tests for deterministic ticking. Use `Dependency(\.date.now)` only for logging playback start timestamps if needed. No external audio services are invoked.
- **Navigation**: Feature remains within existing navigation stack; exposed as a leaf reducer scoped from its parent via `Scope(state:action:)`. No modal or path-based navigation changes required.
- **View Composition**: Create `AudioTrimSimulatorView` bound to `StoreOf<AudioTrimSimulatorFeature>` using `WithViewStore`. Present a `Form` for configuration fields, a `TimelineView` or custom `GeometryReader` visualization for markers, and a control bar with play/pause buttons bound to the store. Derived bindings use `@Bindable` for form inputs while playback progress observes state changes via `ProgressView`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Simulated playback runs for the configured clip duration and stops within ±0.2 seconds of the expected end time in deterministic tests.
- **SC-002**: Pause/resume testing demonstrates zero additional ticks emitted while paused and resumes with no more than a one-second drift from the stored current position.
- **SC-003**: Configuration validation prevents submission of out-of-range values in 100% of automated TestStore scenarios covering min/max bounds.
- **SC-004**: Key time markers render in the UI at positions that match calculated absolute timestamps within 1% of total track length during snapshot/UI testing.
- **SC-005**: Timer effect cancellation occurs within 50 ms of pause in instrumentation logs, ensuring no overlapping timers remain active.
- **SC-006**: Accessibility audit confirms all playback controls expose descriptive VoiceOver labels and dynamic countdown updates announce with polite priority so focus is retained.
