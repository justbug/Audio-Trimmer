import ComposableArchitecture
import Foundation
import Testing
@testable import App

@Suite("AudioTrimmerFeature")
struct AudioTrimmerTests {
    @MainActor
    @Test("playback countdown completes for configured clip")
    func playCountdownCompletes() async throws {
        let context = try await makeConfiguredStore()
        let store = context.store
        let configuration = context.configuration
        let clock = context.clock

        await startPlayback(using: context)
        
        // Verify initial clipProgressPercent is 0 at clip start
        #expect(store.state.timeline.clipProgressPercent == 0.0)

        let tickCount = Int(configuration.clipDuration)
        for tick in 1...tickCount {
            await clock.advance(by: .seconds(1))
            let expectedPosition = configuration.clipStart + TimeInterval(tick)
            let expectedRemaining = configuration.clipDuration - TimeInterval(tick)
            let expectedClipProgress = clipProgress(for: configuration, at: expectedPosition)
            await store.receive(.tick) {
                $0.playbackState.currentPosition = expectedPosition
                $0.playbackState.remainingDuration = max(expectedRemaining, 0)
                $0.timeline = timeline(for: configuration, at: expectedPosition)
                if expectedRemaining <= 0 {
                    $0.playbackState.status = .finished
                }
            }
            // Verify clipProgressPercent increases correctly during playback
            #expect(store.state.timeline.clipProgressPercent == expectedClipProgress)
        }
        
        // Verify clipProgressPercent is 1.0 at clip end
        #expect(store.state.timeline.clipProgressPercent == 1.0)
    }

    @MainActor
    @Test("timeline snapshot derives clip range and marker positions")
    func timelineSnapshotReflectsConfiguration() async throws {
        let context = try await makeConfiguredStore()
        #expect(context.store.state.timeline != .zero)
        // Verify clipProgressPercent is 0 at clip start
        #expect(context.store.state.timeline.clipProgressPercent == 0.0)
    }

    @MainActor
    @Test("pause cancels countdown timer")
    func pauseCancelsSimulationTimer() async throws {
        let context = try await makeConfiguredStore()
        let store = context.store
        let configuration = context.configuration
        let clock = context.clock

        await startPlayback(using: context)

        let ticksBeforePause = 3
        for tick in 1...ticksBeforePause {
            await clock.advance(by: .seconds(1))
            let expectedPosition = configuration.clipStart + TimeInterval(tick)
            let expectedRemaining = configuration.clipDuration - TimeInterval(tick)
            let expectedClipProgress = clipProgress(for: configuration, at: expectedPosition)
            await store.receive(.tick) {
                $0.playbackState.currentPosition = expectedPosition
                $0.playbackState.remainingDuration = max(expectedRemaining, 0)
                $0.timeline = timeline(for: configuration, at: expectedPosition)
                if expectedRemaining <= 0 {
                    $0.playbackState.status = .finished
                }
            }
            // Verify clipProgressPercent increases during playback
            #expect(store.state.timeline.clipProgressPercent == expectedClipProgress)
        }

        let pausedPosition = configuration.clipStart + TimeInterval(ticksBeforePause)
        let expectedPausedClipProgress = clipProgress(for: configuration, at: pausedPosition)
        await store.send(.pauseTapped) {
            $0.playbackState.status = .paused
            $0.timeline = timeline(for: configuration, at: pausedPosition)
        }
        
        // Verify clipProgressPercent is maintained after pause
        #expect(store.state.timeline.clipProgressPercent == expectedPausedClipProgress)

        let remainingDuration = store.state.playbackState.remainingDuration
        await clock.advance(by: .seconds(1))
        #expect(store.state.playbackState.remainingDuration == remainingDuration)
        #expect(store.state.playbackState.status == .paused)
    }

    @MainActor
    @Test("loadConfiguration successfully loads and updates state")
    func loadConfigurationSucceeds() async throws {
        let loadedConfiguration = try await ConfigurationLoader.testValue.load()
        let (store, _) = makeStore(
            configurationLoader: ConfigurationLoader {
                loadedConfiguration
            }
        )

        await store.send(.loadConfiguration)

        await store.receive(.configurationLoaded(loadedConfiguration)) {
            $0.configuration = loadedConfiguration
            $0.playbackState = .idle(configuration: loadedConfiguration)
            $0.timeline = timeline(for: loadedConfiguration, at: loadedConfiguration.clipStart)
            $0.waveform = WaveformFeature.State(
                totalDuration: loadedConfiguration.totalDuration,
                clipStart: loadedConfiguration.clipStart,
                clipDuration: loadedConfiguration.clipDuration
            )
        }
        await store.receive(.waveform(.updateScrollOffsetFromClipStart)) {
            // Calculate expected scroll offset
            let percent = (loadedConfiguration.clipStart / loadedConfiguration.totalDuration).clamped()
            let position = CGFloat(percent) * $0.waveform.viewConfiguration.waveformItemsWidth
            let clampedOffset = max(0, min(position, $0.waveform.viewConfiguration.maxOffset))
            $0.waveform.scrollOffset = -clampedOffset
            $0.waveform.dragStartOffset = -clampedOffset
        }
        // Verify clipProgressPercent is 0 at clip start after loading configuration
        #expect(store.state.timeline.clipProgressPercent == 0.0)
    }

    @MainActor
    @Test("loadConfiguration handles errors and sends loadConfigurationFailed action")
    func loadConfigurationHandlesErrors() async throws {
        let testError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load configuration"])

        let (store, _) = makeStore(
            configurationLoader: ConfigurationLoader {
                throw testError
            }
        )

        await store.send(.loadConfiguration)

        await store.receive(.loadConfigurationFailed("Failed to load configuration"))
        // State should remain unchanged on error
    }

    @MainActor
    @Test("markerTapped moves clip to marker position within valid range")
    func markerTappedMovesClipWithinValidRange() async throws {
        let context = try await makeConfiguredStore()
        let store = context.store
        let configuration = context.configuration
        
        // Use a marker at 50% of track
        let markerPositionPercent = 0.5
        let expectedClipStart = markerPositionPercent * configuration.totalDuration
        
        await store.send(.markerTapped(markerPositionPercent: markerPositionPercent)) {
            $0.configuration = TrackConfiguration(
                totalDuration: configuration.totalDuration,
                clipStart: expectedClipStart,
                clipDuration: configuration.clipDuration,
                keyTimePercentages: configuration.keyTimePercentages
            )
            $0.playbackState = .idle(configuration: TrackConfiguration(
                totalDuration: configuration.totalDuration,
                clipStart: expectedClipStart,
                clipDuration: configuration.clipDuration,
                keyTimePercentages: configuration.keyTimePercentages
            ))
            $0.waveform.clipStart = expectedClipStart
            $0.waveform.clipProgressPercent = 0
            $0.timeline = timeline(
                for: TrackConfiguration(
                    totalDuration: configuration.totalDuration,
                    clipStart: expectedClipStart,
                    clipDuration: configuration.clipDuration,
                    keyTimePercentages: configuration.keyTimePercentages
                ),
                at: expectedClipStart
            )
        }
        
        // Verify progress resets to 0
        #expect(store.state.timeline.clipProgressPercent == 0.0)
        #expect(store.state.playbackState.status == .idle)
        
        // Handle waveform scroll offset update
        await store.receive(.waveform(.updateScrollOffsetFromClipStart)) {
            let percent = (expectedClipStart / configuration.totalDuration).clamped()
            let position = CGFloat(percent) * $0.waveform.viewConfiguration.waveformItemsWidth
            let clampedOffset = max(0, min(position, $0.waveform.viewConfiguration.maxOffset))
            $0.waveform.scrollOffset = -clampedOffset
            $0.waveform.dragStartOffset = -clampedOffset
        }
    }

    @MainActor
    @Test("markerTapped adjusts clipStart when clipEnd would exceed totalDuration")
    func markerTappedHandlesBoundaryConstraint() async throws {
        let context = try await makeConfiguredStore()
        let store = context.store
        let configuration = context.configuration
        
        // Use a marker near the end that would cause clipEnd to exceed totalDuration
        // Place marker at 90% of track, but clipDuration is 6 seconds
        // If totalDuration is 60, marker at 90% = 54 seconds
        // clipEnd would be 54 + 6 = 60, which is exactly at the boundary
        // Let's use a marker that would definitely exceed: 95% = 57 seconds
        // clipEnd would be 57 + 6 = 63, which exceeds 60
        let markerPositionPercent = 0.95
        let expectedClipEnd = configuration.totalDuration
        let expectedClipStart = expectedClipEnd - configuration.clipDuration
        
        await store.send(.markerTapped(markerPositionPercent: markerPositionPercent)) {
            $0.configuration = TrackConfiguration(
                totalDuration: configuration.totalDuration,
                clipStart: expectedClipStart,
                clipDuration: configuration.clipDuration,
                keyTimePercentages: configuration.keyTimePercentages
            )
            $0.playbackState = .idle(configuration: TrackConfiguration(
                totalDuration: configuration.totalDuration,
                clipStart: expectedClipStart,
                clipDuration: configuration.clipDuration,
                keyTimePercentages: configuration.keyTimePercentages
            ))
            $0.waveform.clipStart = expectedClipStart
            $0.waveform.clipProgressPercent = 0
            $0.timeline = timeline(
                for: TrackConfiguration(
                    totalDuration: configuration.totalDuration,
                    clipStart: expectedClipStart,
                    clipDuration: configuration.clipDuration,
                    keyTimePercentages: configuration.keyTimePercentages
                ),
                at: expectedClipStart
            )
        }
        
        // Verify clipStart was adjusted backward
        #expect(store.state.configuration.clipStart == expectedClipStart)
        #expect(store.state.configuration.clipEnd <= configuration.totalDuration)
        // Verify progress resets to 0
        #expect(store.state.timeline.clipProgressPercent == 0.0)
        
        // Handle waveform scroll offset update
        await store.receive(.waveform(.updateScrollOffsetFromClipStart)) {
            let percent = (expectedClipStart / configuration.totalDuration).clamped()
            let position = CGFloat(percent) * $0.waveform.viewConfiguration.waveformItemsWidth
            let clampedOffset = max(0, min(position, $0.waveform.viewConfiguration.maxOffset))
            $0.waveform.scrollOffset = -clampedOffset
            $0.waveform.dragStartOffset = -clampedOffset
        }
    }

    @MainActor
    @Test("markerTapped stops playback and resets progress when playing")
    func markerTappedStopsPlayback() async throws {
        let context = try await makeConfiguredStore()
        let store = context.store
        let configuration = context.configuration
        let clock = context.clock

        // Start playback
        await startPlayback(using: context)
        
        // Advance by 1 second to get one tick
        await clock.advance(by: .seconds(1))
        let tickPosition = configuration.clipStart + 1
        await store.receive(.tick) {
            $0.playbackState.currentPosition = tickPosition
            $0.playbackState.remainingDuration = configuration.clipDuration - 1
            $0.timeline = timeline(for: configuration, at: tickPosition)
            // waveform clipProgressPercent is updated by updateDerivedState
            let elapsed = tickPosition - configuration.clipStart
            $0.waveform.clipProgressPercent = (elapsed / configuration.clipDuration).clamped()
        }
        
        // Verify we're playing and have progress
        #expect(store.state.playbackState.status == .playing)
        #expect(store.state.timeline.clipProgressPercent > 0)
        
        // Tap a marker (this should cancel the timer, so no more ticks should arrive)
        let markerPositionPercent = 0.3
        let expectedClipStart = markerPositionPercent * configuration.totalDuration
        
        await store.send(.markerTapped(markerPositionPercent: markerPositionPercent)) {
            $0.configuration = TrackConfiguration(
                totalDuration: configuration.totalDuration,
                clipStart: expectedClipStart,
                clipDuration: configuration.clipDuration,
                keyTimePercentages: configuration.keyTimePercentages
            )
            $0.playbackState = .idle(configuration: TrackConfiguration(
                totalDuration: configuration.totalDuration,
                clipStart: expectedClipStart,
                clipDuration: configuration.clipDuration,
                keyTimePercentages: configuration.keyTimePercentages
            ))
            $0.waveform.clipStart = expectedClipStart
            $0.waveform.clipProgressPercent = 0
            $0.timeline = timeline(
                for: TrackConfiguration(
                    totalDuration: configuration.totalDuration,
                    clipStart: expectedClipStart,
                    clipDuration: configuration.clipDuration,
                    keyTimePercentages: configuration.keyTimePercentages
                ),
                at: expectedClipStart
            )
        }
        
        // Verify playback stopped
        #expect(store.state.playbackState.status == .idle)
        // Verify progress reset to 0
        #expect(store.state.timeline.clipProgressPercent == 0.0)
        
        // Handle waveform scroll offset update
        await store.receive(.waveform(.updateScrollOffsetFromClipStart)) {
            let percent = (expectedClipStart / configuration.totalDuration).clamped()
            let position = CGFloat(percent) * $0.waveform.viewConfiguration.waveformItemsWidth
            let clampedOffset = max(0, min(position, $0.waveform.viewConfiguration.maxOffset))
            $0.waveform.scrollOffset = -clampedOffset
            $0.waveform.dragStartOffset = -clampedOffset
        }
        
        // Verify timer was cancelled (no more ticks should arrive)
        await clock.advance(by: .seconds(1))
        // Timer was cancelled, so no more ticks should be received
    }
}

private extension AudioTrimmerTests {
    struct ConfiguredStoreContext {
        let store: TestStoreOf<AudioTrimmerFeature>
        let configuration: TrackConfiguration
        let clock: TestClock<Duration>
    }

    @MainActor
    func makeStore(
        clock providedClock: TestClock<Duration> = TestClock(),
        configurationLoader: ConfigurationLoader? = nil
    ) -> (store: TestStoreOf<AudioTrimmerFeature>, clock: TestClock<Duration>) {
        let store = TestStore(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        } withDependencies: {
            $0.continuousClock = providedClock
            if let configurationLoader {
                $0.configurationLoader = configurationLoader
            }
        }
        return (store, providedClock)
    }

    @MainActor
    func makeConfiguredStore(
        clock initialClock: TestClock<Duration> = TestClock()
    ) async throws -> ConfiguredStoreContext {
        let configuration = try await ConfigurationLoader.testValue.load()
        let (store, clock) = makeStore(clock: initialClock)

        await store.send(.loadConfiguration)

        await store.receive(.configurationLoaded(configuration)) {
            $0.configuration = configuration
            $0.playbackState = .idle(configuration: configuration)
            $0.timeline = timeline(for: configuration, at: configuration.clipStart)
            $0.waveform = WaveformFeature.State(
                totalDuration: configuration.totalDuration,
                clipStart: configuration.clipStart,
                clipDuration: configuration.clipDuration
            )
        }
        await store.receive(.waveform(.updateScrollOffsetFromClipStart)) {
            // Calculate expected scroll offset
            let percent = (configuration.clipStart / configuration.totalDuration).clamped()
            let position = CGFloat(percent) * $0.waveform.viewConfiguration.waveformItemsWidth
            let clampedOffset = max(0, min(position, $0.waveform.viewConfiguration.maxOffset))
            $0.waveform.scrollOffset = -clampedOffset
            $0.waveform.dragStartOffset = -clampedOffset
        }

        return ConfiguredStoreContext(store: store, configuration: configuration, clock: clock)
    }

    @MainActor
    func startPlayback(using context: ConfiguredStoreContext) async {
        await context.store.send(.playTapped) {
            $0.playbackState.status = .playing
            $0.playbackState.currentPosition = context.configuration.clipStart
            $0.playbackState.remainingDuration = context.configuration.clipDuration
            $0.timeline = timeline(for: context.configuration, at: context.configuration.clipStart)
        }
    }

    func playbackProgress(
        for configuration: TrackConfiguration,
        at position: TimeInterval
    ) -> Double {
        guard configuration.totalDuration > 0 else {
            return 0
        }
        return (position / configuration.totalDuration).clamped()
    }

    func clipProgress(
        for configuration: TrackConfiguration,
        at position: TimeInterval
    ) -> Double {
        guard configuration.totalDuration > 0, configuration.clipDuration > 0 else {
            return 0
        }
        let elapsed = position - configuration.clipStart
        return (elapsed / configuration.clipDuration).clamped()
    }

    func timeline(
        for configuration: TrackConfiguration,
        at position: TimeInterval
    ) -> AudioTrimmerFeature.TimelineSnapshot {
        let playbackProgress = playbackProgress(for: configuration, at: position)
        let clipProgress = clipProgress(for: configuration, at: position)
        return AudioTrimmerFeature.TimelineSnapshot(
            configuration: configuration,
            playbackProgressPercent: playbackProgress,
            clipProgressPercent: clipProgress
        )
    }
}
