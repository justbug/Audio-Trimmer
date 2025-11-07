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
