# Data Model: Audio Trim Simulator

## Entities

### TrackConfiguration
- **Fields**
  - `totalDuration: TimeInterval` (total duration of the track in seconds)
  - `clipStart: TimeInterval` (start time of the clip in seconds)
  - `clipDuration: TimeInterval` (duration of the clip in seconds)
  - `keyTimePercentages: [Double]` (key time percentages of the clip, 0-100)
- **Computed Properties**
  - `clipEnd: TimeInterval` = `clipStart + clipDuration`
  - `clipRangeSeconds: ClosedRange<TimeInterval>` = clamped range from `clipStart` to `min(clipEnd, totalDuration)`
  - `normalizedClipRangePercent: ClosedRange<Double>` = normalized to 0...1 range based on `totalDuration` (returns `0...0` if `totalDuration <= 0`)
  - `normalizedKeyTimesPercent: [Double]` = `keyTimePercentages.map { ($0 / 100).clamped() }` (normalized to 0...1 range)
- **Edge Case Handling**
  - When `totalDuration <= 0`, `normalizedClipRangePercent` returns `0...0`
  - `clipRangeSeconds` ensures the clip end does not exceed `totalDuration` via `min(clipEnd, totalDuration)`
  - Key time percentages are clamped to 0-1 range (0-100%) via `Double.clamped()` extension

### PlaybackState
- **Fields**
  - `status: Status` (enum: `.idle`, `.playing`, `.paused`, `.finished`)
  - `currentPosition: TimeInterval` (current playback position, starts at `clipStart`, advances during playback)
  - `remainingDuration: TimeInterval` (remaining time until clip end, starts at `clipDuration`, decrements during playback)
- **Static Factory Methods**
  - `.idle` = `PlaybackState(status: .idle, currentPosition: 0, remainingDuration: 0)`
  - `.idle(configuration:)` = initializes with `currentPosition = clipStart`, `remainingDuration = clipDuration`
  - `.playing(configuration:)` = initializes playing state with `currentPosition = clipStart`, `remainingDuration = clipDuration`
- **State Transitions**
  - `.idle` → `.playing` on `.playTapped`; sets `currentPosition = clipStart`, `remainingDuration = clipDuration`, starts timer effect.
  - `.playing` → `.paused` on `.pauseTapped`; cancels timer effect via `TimerID.playback`, preserves current position.
  - `.paused` → `.playing` on `.playTapped`; resumes from stored `currentPosition`, restarts timer effect.
  - `.playing` → `.finished` when `currentPosition >= clipEnd`; timer cancels automatically, status set to `.finished`.
  - `.finished` → `.playing` on `.playTapped`; reinitializes to `.playing(configuration:)` state, restarts from clip start.
  - Any state → `.idle` on `.resetTapped`; resets to `.idle(configuration:)` state, cancels timer effect.

### TimelineSnapshot
- **Fields**
  - `clipRangeSeconds: ClosedRange<TimeInterval>` (absolute time range of the clip)
  - `clipRangePercent: ClosedRange<Double>` (normalized clip range 0...1 based on total duration)
  - `markerPositionsPercent: [Double]` (normalized marker positions 0...1, derived from `normalizedKeyTimesPercent`)
  - `currentProgressPercent: Double` (current playback progress 0...1 within the clip)
- **Initializers**
  - `init(clipRangeSeconds:clipRangePercent:markerPositionsPercent:currentProgressPercent:)` - direct initialization
  - `init(configuration:playbackProgressPercent:)` - computed from `TrackConfiguration` and playback progress
  - `.zero` - static instance with all zero/empty values
- **Purpose**
  - Exposed as read-only data for SwiftUI visualizations; recomputed via `updateDerivedState` helper whenever configuration or playback changes.
  - `currentProgressPercent` is computed from `(currentPosition - clipStart) / clipDuration`, clamped to 0...1.

## Relationships
- Reducer state (`AudioTrimmerFeature.State`) owns `configuration: TrackConfiguration`, `playbackState: PlaybackState`, and `timeline: TimelineSnapshot`.
- `TimelineSnapshot` derives from both `TrackConfiguration` and playback progress, recomputed via `updateDerivedState` helper function.
- Configuration is loaded asynchronously via `ConfigurationLoader` dependency, which provides `liveValue` (throws error by default) and `testValue` (returns test configuration) implementations.
- No persistent storage; all mutations happen within reducer actions.

## State Management
- Timer cancellation is handled via `TimerID.playback` effect ID, not stored in state.
- Playback actions guard against invalid transitions (e.g., `.playTapped` ignores if already playing, `.pauseTapped` ignores if not playing).
- Configuration loading is async via `.loadConfiguration` action, which dispatches `.configurationLoaded(TrackConfiguration)` on success or `.loadConfigurationFailed(String)` on error.
- The `updateDerivedState` helper function rebuilds `TimelineSnapshot` whenever `configuration` or `playbackState` changes, ensuring the timeline always reflects current state.
