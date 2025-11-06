# Quickstart: Audio Trim Simulator Logic

## Prerequisites
- Xcode 15.x with Swift 5.10 toolchain
- Swift Composable Architecture 1.23.0 already resolved via `Package.swift`

## Build
```bash
swift build --package-path "Audio Trimmer/App"
```

## Test
```bash
swift test --package-path "Audio Trimmer/App" --filter AudioTrimmerTests
```
> If the command fails in the sandbox due to module cache permissions, re-run locally outside the restricted environment to validate.

## Focus Areas for Reviewers
- Reducer placement under `App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`
- State structure: `configuration: TrackConfiguration`, `playbackState: PlaybackState`, `timeline: TimelineSnapshot`
- Deterministic timer handling using `@Dependency(\.continuousClock)` with `TimerID.playback` for cancellation
- Configuration loading via `ConfigurationLoader` dependency pattern (`ConfigurationLoader.swift`)
- `TimelineSnapshot` derivation via `updateDerivedState` helper function
- Test coverage using `TestClock` for deterministic playback simulation
- Actions: `.playTapped` (handles play and resume), `.pauseTapped`, `.resetTapped`, `.tick`, `.loadConfiguration`, `.configurationLoaded`, `.loadConfigurationFailed`
