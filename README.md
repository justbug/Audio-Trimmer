# Audio Trimmer

Audio Trimmer models an audio trimming experience using SwiftUI and The Composable Architecture (TCA) 1.23.0.
The Swift package encapsulates all business logic and can be reused by the iOS host app for previews and
simulator builds.

## Requirements
- macOS 14.4 or later with Xcode 16 (or an equivalent Swift 6 toolchain that satisfies `swift-tools-version: 6.2`)
- Swift 5.10+ source compatibility (keep the toolchain aligned with TCA 1.23.0 as noted in the repo guidelines)
- iOS 18.0, macOS 15.0, or visionOS 2.0 SDKs for platform builds

## Repository Layout
```text
Audio Trimmer/
├─ App/Package.swift                      # SwiftPM manifest for the reusable package
├─ App/Sources/App/RootView.swift         # SwiftUI entry point using TCA architecture
├─ App/Sources/App/Features/AudioTrimmer/ # Audio trimming feature reducer & dependencies
├─ App/Sources/App/Models/                # Cross-platform domain models
├─ App/Sources/App/Extensions/            # Shared helpers (Double+Extensions, TimeInterval+Extensions)
├─ App/Tests/AppTests/                    # Swift Testing + TCA TestStore coverage
├─ Audio Trimmer.xcodeproj                # iOS shell + asset catalog
└─ README.md                              # Single source of truth for build & architecture
```

## Build & Run
- Build the Swift package:
  ```bash
  swift build --package-path "Audio Trimmer/App"
  ```
- Run the unit test suite:
  ```bash
  swift test --package-path "Audio Trimmer/App"
  ```
- Build the shell app in the simulator (useful for SwiftUI previews):
  ```bash
  xcodebuild \
    -project "Audio Trimmer.xcodeproj" \
    -scheme "Audio Trimmer" \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    build
  ```

## Architecture
- Reducer-first design using TCA macros (`@Reducer`, `@ObservableState`) keeping side effects in the dependency
  system and out of SwiftUI views.
- Each feature reducer lives under `Audio Trimmer/App/Sources/App/Features/<FeatureName>/` and exposes its state,
  actions, and body from a single type.
- Dependencies are surfaced through `DependencyValues`; the package currently provides a configurable
  `ConfigurationLoader` and uses TCA's `continuousClock` for time-based effects.
- Views bind to `StoreOf<Feature>` and derive navigation/scoped state rather than owning mutable data.

### AudioTrimmerFeature
`Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`

- **State** tracks the loaded `TrackConfiguration`, the current `PlaybackState`, and a derived
  `TimelineSnapshot`. A placeholder configuration supports showing the feature before data loads.
- **Actions** cover playback controls (`playTapped`, `pauseTapped`, `resetTapped`, `tick`) and data loading
  (`loadConfiguration`, `configurationLoaded`, `loadConfigurationFailed`).
- **Effects** start a cancellable timer (`TimerID.playback`) when playback begins and cancel it when
  playback pauses, finishes, or resets. The reducer uses `@Dependency(\.continuousClock)` for timer delivery.
- **Derived data** is rebuilt through `updateDerivedState`, ensuring `TimelineSnapshot` stays consistent with the
  active configuration and playback progress. The feature now tracks clip progress separately from overall playback
  progress, providing more granular control over the trimming experience.

### Domain Models
- `TrackConfiguration` (`Audio Trimmer/App/Sources/App/Models/TrackConfiguration.swift`) defines the raw trimming
  metadata, exposes derived ranges (`clipRangeSeconds`, `normalizedClipRangePercent`, `normalizedKeyTimesPercent`),
  and keeps values clamped to valid bounds.
- `AudioTrimmerFeature.TimelineSnapshot` converts the configuration into UI-ready percentages for the playback
  timeline and marker positions.
- `Double+Extensions` (`Audio Trimmer/App/Sources/App/Extensions/Double+Extensions.swift`) provides formatting and
  clamping utilities for numeric values.
- `TimeInterval+Extensions` (`Audio Trimmer/App/Sources/App/Extensions/TimeInterval+Extensions.swift`) provides
  time formatting methods for display purposes.

### Configuration Loading
- `ConfigurationLoader` (`Audio Trimmer/App/Sources/App/Features/AudioTrimmer/ConfigurationLoader.swift`) is exposed
  as a dependency with `liveValue` (throws `ConfigurationLoadError.notImplemented` by default) and `testValue`
  (returns canned data for previews/tests).
- Provide a live implementation at composition time, for example:
  ```swift
  store = Store(initialState: AudioTrimmerFeature.State()) {
      AudioTrimmerFeature()
          .dependency(\.configurationLoader, .init {
              try await apiClient.fetchConfiguration()
          })
  }
  ```

## SwiftUI Shell
- `RootView` (`Audio Trimmer/App/Sources/App/RootView.swift`) is the main SwiftUI entry point that initializes
  and provides the `AudioTrimmerFeature` store to the view hierarchy.
- `AudioTrimmerView` (`Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerView.swift`) implements
  the complete UI for audio trimming, including:
  - Timeline visualization with clip range and key time markers
  - Playback controls (play, pause, reset)
  - Clip details display (start time, duration, end time)
  - Progress tracking for both overall playback and clip-specific progress
- Assets dedicated to iOS belong in `Audio Trimmer/Assets.xcassets`; cross-platform logic stays inside the Swift
  package so the package tests and the Xcode target share the same code.

## Testing
- Tests live under `Audio Trimmer/App/Tests/AppTests/` and use the Swift `Testing` package alongside TCA's
  `TestStore`. The current coverage (`AudioTrimmerTests.swift`) verifies:
  - Successful configuration loading updates state.
  - Playback timers tick until completion and respect pause/reset.
  - Timeline snapshots reflect derived ranges and markers.
  - Clip progress tracking works independently from overall playback progress.
- Run `swift test --package-path "Audio Trimmer/App"` before opening a pull request or merging changes.

## Development Workflow
- Maintain compatibility with TCA 1.23.0 and keep reducer macros up to date.
- When adding features, create a new reducer in `Features/`, expose dependencies via `DependencyValues`, and
  compose them using `Scope` from parent reducers.
- Keep business logic inside reducers/effects and drive SwiftUI through state bindings and actions.
- Follow Conventional Commits (e.g. `feat: add waveform trimming reducer`) and document verification commands in
  pull requests.
- Prefer command-line builds/tests for fast feedback; use `xcodebuild … build` or Xcode previews for UI-only work.

## Recent Changes

### Added
- Implemented `AudioTrimmerView` with complete UI components for audio trimming, playback controls, and configuration loading
- Added extensions for `Double` and `TimeInterval` with formatting and clamping methods
- Replaced `ContentView` with `RootView` to enhance app structure and introduce Composable Architecture

### Changed
- Enhanced `AudioTrimmerFeature` with clip progress tracking and updated UI to reflect new progress metrics
- Optimized playback progress calculation by moving logic into `updateDerivedState` method

### Chores
- Updated `.gitignore` to include `buildServer.json` and `.clangModuleCache`

## Next Steps
- Implement a production `ConfigurationLoader` that fetches track metadata from disk or a service.
- Add seek and scrub functionality to allow users to jump to specific positions in the audio.
- Extend coverage with reducer tests for new behaviors (seek, scrub, waveform markers) as they are introduced.
- Enhance the UI with waveform visualization and interactive marker editing.
