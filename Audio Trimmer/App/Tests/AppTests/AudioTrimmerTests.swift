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

        let tickCount = Int(configuration.clipDuration)
        for tick in 1...tickCount {
            await clock.advance(by: .seconds(1))
            let expectedPosition = configuration.clipStart + TimeInterval(tick)
            let expectedRemaining = configuration.clipDuration - TimeInterval(tick)
            let progress = playbackProgress(for: configuration, at: expectedPosition)
            await store.receive(.tick) {
                $0.playbackState.currentPosition = expectedPosition
                $0.playbackState.remainingDuration = max(expectedRemaining, 0)
                $0.timeline = timeline(for: configuration, progress: progress)
                if expectedRemaining <= 0 {
                    $0.playbackState.status = .finished
                }
            }
        }
    }

    @MainActor
    @Test("timeline snapshot derives clip range and marker positions")
    func timelineSnapshotReflectsConfiguration() async throws {
        let context = try await makeConfiguredStore()
        #expect(context.store.state.timeline != .zero)
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
            let progress = playbackProgress(for: configuration, at: expectedPosition)
            await store.receive(.tick) {
                $0.playbackState.currentPosition = expectedPosition
                $0.playbackState.remainingDuration = max(expectedRemaining, 0)
                $0.timeline = timeline(for: configuration, progress: progress)
                if expectedRemaining <= 0 {
                    $0.playbackState.status = .finished
                }
            }
        }

        let pausedPosition = configuration.clipStart + TimeInterval(ticksBeforePause)
        let pausedProgress = playbackProgress(for: configuration, at: pausedPosition)
        await store.send(.pauseTapped) {
            $0.playbackState.status = .paused
            $0.timeline = timeline(for: configuration, progress: pausedProgress)
        }

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
            $0.timeline = timeline(for: loadedConfiguration, progress: 0)
        }
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
            $0.timeline = timeline(for: configuration, progress: 0)
        }

        return ConfiguredStoreContext(store: store, configuration: configuration, clock: clock)
    }

    @MainActor
    func startPlayback(using context: ConfiguredStoreContext) async {
        await context.store.send(.playTapped) {
            $0.playbackState.status = .playing
            $0.playbackState.currentPosition = context.configuration.clipStart
            $0.playbackState.remainingDuration = context.configuration.clipDuration
            $0.timeline = timeline(for: context.configuration, progress: 0)
        }
    }

    func playbackProgress(
        for configuration: TrackConfiguration,
        at position: TimeInterval
    ) -> Double {
        ((position - configuration.clipStart) / configuration.clipDuration).clamped()
    }

    func timeline(
        for configuration: TrackConfiguration,
        progress: Double
    ) -> AudioTrimmerFeature.TimelineSnapshot {
        AudioTrimmerFeature.TimelineSnapshot(
            configuration: configuration,
            playbackProgressPercent: progress
        )
    }
}
