# Quickstart: Track Settings Entry Page

## Prerequisites
- Xcode 15.x with Swift 5.10 toolchain
- The Composable Architecture 1.23.0 resolved via `Package.swift`

## Build
```bash
swift build --package-path "Audio Trimmer/App"
```

## Test
```bash
swift test --package-path "Audio Trimmer/App" --filter TrackSettingsTests
swift test --package-path "Audio Trimmer/App" --filter AudioTrimmerTests
```

## Run (Simulator)
```bash
xcodebuild -project "Audio Trimmer.xcodeproj" -scheme "Audio Trimmer" -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Reviewer Focus
- Reducer placement: `App/Sources/App/Features/TrackSettings/TrackSettingsFeature.swift`
- View binding: `TrackSettingsView` uses `StoreOf<TrackSettingsFeature>` and `@Bindable` fields
- Validation coverage in `TrackSettingsTests.swift`
- Navigation handoff to `AudioTrimmerFeature` with correctly formed `TrackConfiguration`
- No business logic in SwiftUI views; validation and mapping live in the reducer


