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

## Focus Areas for Reviewers
- Reducer placement under `App/Sources/App/Features/AudioTrimmer/`
- Deterministic timer handling using `continuousClock`
- Validation logic for clip configuration and key markers
