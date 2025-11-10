# Data Model: Track Settings Entry Page

## Entities

### TrackConfiguration (existing, unchanged)
- Fields
  - `totalDuration: TimeInterval` (seconds)
  - `clipStart: TimeInterval` (seconds)
  - `clipDuration: TimeInterval` (seconds, derived from clip percent)
  - `keyTimePercentages: [Double]` (0–100)
- Notes
  - The feature computes `clipDuration` from user-entered clip percent.
  - Existing computed properties (`clipEnd`, `clipRangeSeconds`, `normalized...`) remain the source of truth for downstream views.

### TrackSettingsForm
- Purpose: Captures raw user input for configuration prior to validation/mapping.
- Fields (as Strings for SwiftUI bindings)
  - `totalDurationText: String` (required; > 0)
  - `keyTimesText: String` (required; comma/space separated list, e.g., "25, 75")
  - `clipStartText: String` (required; ≥ 0)
  - `clipPercentText: String` (required; > 0 and ≤ 100)
- Derived (parsed/normalized, internal use)
  - `parsedTotalDuration: TimeInterval?`
  - `parsedKeyTimes: [Double]?` (after normalization: clamp to [0,100], round(2), sort, unique)
  - `parsedClipStart: TimeInterval?`
  - `parsedClipPercent: Double?`
  - `computedClipDuration: TimeInterval?` = `parsedTotalDuration * (parsedClipPercent / 100)`
- Validation Errors
  - `fieldErrors: [Field: String]` where `Field ∈ { totalDuration, keyTimes, clipStart, clipPercent }`
  - Semantics:
    - totalDuration must be > 0
    - clipPercent in (0, 100]
    - keyTimes not empty and every value in [0, 100]
    - clipStart ≥ 0 and `clipStart + clipDuration ≤ totalDuration`

### Navigation State
- Purpose: Drive transition into trimming feature with the validated configuration.
- Fields
  - `destination: Destination?`
  - `Destination.audioTrimmer(TrackConfiguration)`

## Relationships
- `TrackSettingsFeature.State` owns a `TrackSettingsForm` and navigation `destination`.
- On `.confirmTapped`, reducer validates form, computes `clipDuration` from `clipPercent`, constructs `TrackConfiguration`, clears errors, and routes to `Destination.audioTrimmer(configuration)`.
- `AudioTrimmerFeature.State` is initialised from the supplied `TrackConfiguration` and runs independently thereafter.

## Validation Rules
- Parsing
  - Accept decimal numbers with dot (`.`) separator; other characters cause field errors.
  - `keyTimesText` is split by commas or whitespace; empty tokens ignored.
- Business Rules
  - `totalDuration > 0`
  - `clipPercent ∈ (0, 100]`
  - `clipDuration = totalDuration * (clipPercent / 100)` must be > 0
  - `clipStart ≥ 0` and `clipStart + clipDuration ≤ totalDuration`
  - At least one `key time`; all ∈ [0, 100]; normalization clamp → round(2) → sort → unique

## State Transitions
- Idle → Editing: user types into fields, errors may clear on re-validate.
- Editing → Validated: `.confirmTapped` runs validation; on success produce `TrackConfiguration` and navigate.
- Editing → Error: `.confirmTapped` produces `fieldErrors`; `destination` remains `nil`.


