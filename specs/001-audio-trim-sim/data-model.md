# Data Model: Audio Trim Simulator

## Entities

### TrackConfiguration
- **Fields**
  - `totalDuration: TimeInterval` (> 0)
  - `clipStart: TimeInterval` (≥ 0, < totalDuration)
  - `clipDuration: TimeInterval` (≥ 1, ≤ totalDuration)
  - `keyTimePercentages: [Double]` (values 0...100, unique, sorted)
- **Derived**
  - `clipEnd = min(totalDuration, clipStart + clipDuration)`
  - `normalizedKeyTimes = keyTimePercentages.map(clamp to 0...100).unique.sorted`
  - `absoluteKeyTimes = normalizedKeyTimes.map { totalDuration * percentage / 100 }`
- **Validation Rules**
  - Reject total duration ≤ 0 with error `invalidTotalDuration`.
  - Reject clip start < 0 or clip start >= totalDuration with error `clipStartOutOfBounds`.
  - When `clipEnd > totalDuration`, surface `clipExceedsTrack` warning and clamp end to track length.
  - Require `clipDuration >= 1`.
  - Ensure `clipStart + clipDuration <= totalDuration`; otherwise emit `clipWindowOutOfBounds` error and block playback.
  - Flag warnings for duplicates or adjustments to key times so UI can communicate changes.

### PlaybackSimulation
- **Fields**
  - `status: Status` (enum: `.idle`, `.playing`, `.paused`, `.finished`)
  - `currentPosition: TimeInterval` (>= `clipStart`, <= `clipEnd`)
  - `remainingDuration: TimeInterval` (>= 0)
  - `timerID: TimerID?` (identifies cancellable effect)
- **State Transitions**
  - `.idle` → `.playing` on `.playTapped` if validation passes; set `currentPosition = clipStart`, `remainingDuration = clipDuration`.
  - `.playing` → `.paused` on `.pauseTapped`; cancel timer effect.
  - `.paused` → `.playing` on `.resumeTapped`; restart timer from stored `currentPosition`.
  - `.playing` → `.finished` when `remainingDuration <= 0`; timer cancels automatically.
  - `.finished` → `.playing` on `.playTapped` reusing current configuration.

### TimelineSnapshot
- **Fields**
  - `clipRange: ClosedRange<Double>` (normalized 0...1)
  - `markerPositions: [Double]` (normalized 0...1 matching `normalizedKeyTimes`)
  - `currentProgress: Double` (0...1 while playing)
- **Purpose**
  - Exposed as read-only data for SwiftUI visualizations; recomputed whenever configuration or playback changes.

## Relationships
- Reducer state owns `TrackConfiguration` and `PlaybackSimulation`. `TimelineSnapshot` derives from both.
- No persistent storage or external services; all mutations happen within reducer actions.

## Validation & Error Surface
- Reducer stores validation flags (e.g., `configurationErrors: [ConfigurationError]`) to allow UI to show inline messaging.
- Configuration updates run through pure helper functions returning updated config plus warnings.
- Playback actions guard against invalid transitions (e.g., ignore `.pauseTapped` when already paused).
