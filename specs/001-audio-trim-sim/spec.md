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

**Independent Test**: `TestStore` sends `.playTapped`, advances time to trigger ticks, dispatches `.pauseTapped`, verifies cancellation of the timer effect, then sends `.playTapped` again (which handles resume) and confirms ticks resume from the persisted current second.

**Acceptance Scenarios**:

1. **Given** playback running with 6 seconds remaining, **When** pause is tapped, **Then** the reducer switches to `paused`, cancels further ticks, and the remaining time display holds steady.
2. **Given** playback paused at 4 seconds remaining, **When** play is tapped again, **Then** the reducer re-schedules ticks and playback completes in exactly 4 additional seconds without repeating earlier timeline events.

---

### User Story 3 - Load Configuration (Priority: P3)

The producer loads track configuration from an external source (via `ConfigurationLoader` dependency), and the system updates state with the loaded configuration, resetting playback to idle state.

**Why this priority**: Enables dynamic configuration loading for different demo scenarios without hardcoding track data.

**Independent Test**: `TestStore` exercises `.loadConfiguration` action, verifies async loading via `ConfigurationLoader` dependency, and asserts state updates on `.configurationLoaded` or error handling on `.loadConfigurationFailed`.

**Acceptance Scenarios**:

1. **Given** a `ConfigurationLoader` dependency providing a valid `TrackConfiguration`, **When** `.loadConfiguration` is dispatched, **Then** the reducer loads the configuration asynchronously and updates state with the new configuration, resetting playback to idle.
2. **Given** a `ConfigurationLoader` dependency that throws an error, **When** `.loadConfiguration` is dispatched, **Then** the reducer receives `.loadConfigurationFailed` with the error message and state remains unchanged.

**Note**: Configuration editing actions (`.updateKeyTimes`, `.updateClipStart`, `.updateClipDuration`) are not implemented in the current codebase. Configuration is loaded via the `ConfigurationLoader` dependency pattern.

---

### Edge Cases

- Track length below minimum (≤ 0 seconds) is handled through computed properties that return safe defaults (e.g., `normalizedClipRangePercent` returns `0...0` when `totalDuration <= 0`).
- Clip duration exceeding track length causes auto-clamping via `clipRangeSeconds` computed property which ensures the clip end does not exceed `totalDuration`.
- Key time percentages are normalized via `normalizedKeyTimesPercent` which clamps values to 0–1 range (0–100%).
- Timer cancellation: the timer effect is properly cancelled when paused or reset, using `TimerID.playback` to prevent overlapping timers.
- Playback state transitions: `.playTapped` handles both initial play and resume from paused/finished states by checking current status.
- VoiceOver focus while countdown updates: labels must not cause focus jumps when time remaining changes rapidly (UI implementation pending).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST store track length as a `TimeInterval` in `TrackConfiguration.totalDuration`. Computed properties handle edge cases (e.g., `normalizedClipRangePercent` returns `0...0` when `totalDuration <= 0`).
- **FR-002**: System MUST accept a clip start offset and duration, stored as `TimeInterval` values in `TrackConfiguration`. The `clipRangeSeconds` computed property enforces that the resulting clip window stays within the configured track length by clamping the end to `totalDuration`.
- **FR-003**: System MUST store multiple key time percentages in `TrackConfiguration.keyTimePercentages` and normalize them via `normalizedKeyTimesPercent` which clamps values to 0–1 range (0–100%).
- **FR-004**: System MUST provide play (`.playTapped`), pause (`.pauseTapped`), and reset (`.resetTapped`) controls. The `.playTapped` action handles both initial play and resume from paused/finished states by checking current playback status.
- **FR-005**: System MUST drive a simulated playback loop that emits one state update per second via `.tick` actions, scheduled using `ContinuousClock` timer effect without relying on real audio files.
- **FR-006**: System MUST decrement the remaining playback time each tick using `TimeInterval` arithmetic, stop automatically when `currentPosition >= clipEnd`, and provide `.resetTapped` to reset playback to idle state.
- **FR-007**: System MUST cancel scheduled ticks immediately when paused (via `.pauseTapped`) or reset (via `.resetTapped`) using `TimerID.playback`, and resume from the stored current position when `.playTapped` is dispatched again.
- **FR-008**: System MUST expose a read-only `TimelineSnapshot` model (including `clipRangeSeconds`, `clipRangePercent`, `markerPositionsPercent`, `currentProgressPercent`) that is recomputed via `updateDerivedState` whenever configuration or playback changes.
- **FR-009**: System MUST support loading configuration asynchronously via `.loadConfiguration` action, which uses the `ConfigurationLoader` dependency to fetch `TrackConfiguration` and updates state via `.configurationLoaded` or `.loadConfigurationFailed` actions.

### Key Entities *(include if feature involves data)*

- **TrackConfiguration**: Represents track settings comprising `totalDuration`, `clipStart`, `clipDuration`, and `keyTimePercentages`; provides computed properties `clipEnd`, `clipRangeSeconds`, `normalizedClipRangePercent`, and `normalizedKeyTimesPercent` for derived values.
- **PlaybackState**: Captures runtime playback state including `status` (idle, playing, paused, finished), `currentPosition`, and `remainingDuration`. Provides static factory methods `.idle`, `.idle(configuration:)`, and `.playing(configuration:)` for initialization.
- **TimelineSnapshot**: Read-only snapshot of timeline state including `clipRangeSeconds`, `clipRangePercent`, `markerPositionsPercent`, and `currentProgressPercent`. Computed from `TrackConfiguration` and playback progress.
- **ConfigurationLoader**: Dependency protocol for loading `TrackConfiguration` asynchronously. Provides `liveValue` (throws `ConfigurationLoadError.notImplemented` by default) and `testValue` (returns test configuration) implementations.

## Architecture & State Management *(mandatory)*

- **Feature Reducers**: `AudioTrimmerFeature` annotated with `@Reducer`, owning `@ObservableState` with fields: `configuration: TrackConfiguration`, `playbackState: PlaybackState`, and `timeline: TimelineSnapshot`. All duration and offset values represented as `TimeInterval`. Actions include `playTapped`, `pauseTapped`, `resetTapped`, `tick`, `loadConfiguration`, `configurationLoaded(TrackConfiguration)`, and `loadConfigurationFailed(String)`. Effects: `playTapped` starts a `ContinuousClock`-driven timer sending `.tick` every second until cancellation or completion (keyed by `TimerID.playback`); `pauseTapped` and `resetTapped` cancel the timer effect. The `updateDerivedState` helper function rebuilds `TimelineSnapshot` whenever configuration or playback changes.
- **Dependencies**: Leverage `@Dependency(\.continuousClock)` to supply a `Clock` instance; override with `TestClock` within tests for deterministic ticking. Use `@Dependency(\.configurationLoader)` to load track configuration asynchronously; provides `liveValue` (throws error by default) and `testValue` (returns test configuration) implementations. No external audio services are invoked.
- **Navigation**: Feature remains within existing navigation stack; exposed as a leaf reducer scoped from its parent via `Scope(state:action:)`. No modal or path-based navigation changes required.
- **View Composition**: Create `AudioTrimmerView` bound to `StoreOf<AudioTrimmerFeature>` using `@Bindable` properties generated by `@ObservableState`. Present configuration display, a timeline visualization for markers, and a control bar with play/pause/reset buttons bound to the store. Playback progress observes state changes via the `timeline.currentProgressPercent` property.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Simulated playback runs for the configured clip duration and stops within ±0.2 seconds of the expected end time in deterministic tests.
- **SC-002**: Pause/resume testing demonstrates zero additional ticks emitted while paused and resumes with no more than a one-second drift from the stored current position when `.playTapped` is dispatched again.
- **SC-003**: Configuration loading via `ConfigurationLoader` dependency succeeds in test scenarios and properly updates state with loaded configuration, resetting playback to idle state.
- **SC-004**: Key time markers render in the UI at positions that match calculated absolute timestamps within 1% of total track length during snapshot/UI testing.
- **SC-005**: Timer effect cancellation occurs within 50 ms of pause in instrumentation logs, ensuring no overlapping timers remain active.
- **SC-006**: Accessibility audit confirms all playback controls expose descriptive VoiceOver labels and dynamic countdown updates announce with polite priority so focus is retained.
