# Research: Simulated Audio Trimmer

## Decision 1: Use `Dependency(\.continuousClock)` with cancellable timer effect
- **Decision**: Drive playback ticks using TCA `Effect.run` and the injected `continuousClock`, keyed by a stable `TimerID` for pause/cancel support.
- **Rationale**: Aligns with TCA 1.23.0 best practices for scheduled work, keeps the reducer deterministic, and allows tests to override the clock with `ImmediateClock`.
- **Alternatives considered**: Using `Timer.publish` directly was rejected because it couples to Combine and complicates deterministic testing; manually dispatching `DispatchQueue.main.asyncAfter` was rejected due to cancellation complexity and thread affinity risks.

## Decision 2: Represent configuration and playback as separate structs within state
- **Decision**: Model `TrackConfiguration` and `PlaybackSimulation` structs nested in reducer state with all durations stored as `TimeInterval`, deriving computed properties (clip end, marker timestamps) via pure functions.
- **Rationale**: Keeps validation rules localized, makes state mutations predictable, and mirrors entities outlined in the feature spec for easier testing and UI binding.
- **Alternatives considered**: Flattening all fields into the root state was rejected because it mixes configuration with runtime variables and complicates validation reuse.

## Decision 3: Seed dummy data through reducer initialiser and preview helper
- **Decision**: Provide default state initialisers with representative dummy track data and expose a static `.preview` factory to help future SwiftUI previews.
- **Rationale**: Ensures logic can be exercised without external inputs, accelerates UI integration later, and keeps this iteration focused on logic only.
- **Alternatives considered**: Loading JSON fixtures or relying on external files was rejected because it introduces unnecessary I/O, conflicts with “dummy data only,” and complicates test determinism.
