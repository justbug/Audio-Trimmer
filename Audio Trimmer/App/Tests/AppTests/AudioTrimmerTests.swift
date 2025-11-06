import ComposableArchitecture
import Foundation
import Testing
@testable import App

@Suite("AudioTrimmerFeature")
struct AudioTrimmerTests {
    @MainActor
    @Test("playback countdown completes for configured clip")
    func playCountdownCompletes() async throws {
        let configuration = try await ConfigurationLoader.testValue.load()
        let clock = TestClock()
        let store = TestStore(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.loadConfiguration)
        
        await store.receive(.configurationLoaded(configuration)) {
            $0.configuration = configuration
            $0.playbackState = .idle(configuration: configuration)
            $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                configuration: configuration,
                playbackProgressPercent: 0
            )
        }

        await store.send(.playTapped) {
            $0.playbackState.status = .playing
            $0.playbackState.currentPosition = configuration.clipStart
            $0.playbackState.remainingDuration = configuration.clipDuration
            $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                configuration: configuration,
                playbackProgressPercent: 0
            )
        }

        let tickCount = Int(configuration.clipDuration)
        for tick in 1...tickCount {
            await clock.advance(by: .seconds(1))
            let expectedPosition = configuration.clipStart + TimeInterval(tick)
            let expectedRemaining = configuration.clipDuration - TimeInterval(tick)
            let progress = ((expectedPosition - configuration.clipStart) / configuration.clipDuration).clamped()
            await store.receive(.tick) {
                $0.playbackState.currentPosition = expectedPosition
                $0.playbackState.remainingDuration = max(expectedRemaining, 0)
                $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                    configuration: configuration,
                    playbackProgressPercent: progress
                )
                if expectedRemaining <= 0 {
                    $0.playbackState.status = .finished
                }
            }
        }
    }

    @MainActor
    @Test("timeline snapshot derives clip range and marker positions")
    func timelineSnapshotReflectsConfiguration() async throws {
        let configuration = try await ConfigurationLoader.testValue.load()
        let clock = TestClock()
        let store = TestStore(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.loadConfiguration)
        
        await store.receive(.configurationLoaded(configuration)) {
            $0.configuration = configuration
            $0.playbackState = .idle(configuration: configuration)
            $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                configuration: configuration,
                playbackProgressPercent: 0
            )
        }

        #expect(store.state.timeline != .zero)
    }

    @MainActor
    @Test("pause cancels countdown timer")
    func pauseCancelsSimulationTimer() async throws {
        let configuration = try await ConfigurationLoader.testValue.load()
        let clock = TestClock()
        let store = TestStore(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.loadConfiguration)
        
        await store.receive(.configurationLoaded(configuration)) {
            $0.configuration = configuration
            $0.playbackState = .idle(configuration: configuration)
            $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                configuration: configuration,
                playbackProgressPercent: 0
            )
        }

        await store.send(.playTapped) {
            $0.playbackState.status = .playing
            $0.playbackState.currentPosition = configuration.clipStart
            $0.playbackState.remainingDuration = configuration.clipDuration
            $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                configuration: configuration,
                playbackProgressPercent: 0
            )
        }

        let ticksBeforePause = 3
        for tick in 1...ticksBeforePause {
            await clock.advance(by: .seconds(1))
            let expectedPosition = configuration.clipStart + TimeInterval(tick)
            let expectedRemaining = configuration.clipDuration - TimeInterval(tick)
            let progress = ((expectedPosition - configuration.clipStart) / configuration.clipDuration).clamped()
            await store.receive(.tick) {
                $0.playbackState.currentPosition = expectedPosition
                $0.playbackState.remainingDuration = max(expectedRemaining, 0)
                $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                    configuration: configuration,
                    playbackProgressPercent: progress
                )
                if expectedRemaining <= 0 {
                    $0.playbackState.status = .finished
                }
            }
        }

        let pausedPosition = configuration.clipStart + TimeInterval(ticksBeforePause)
        let pausedProgress = ((pausedPosition - configuration.clipStart) / configuration.clipDuration).clamped()
        await store.send(.pauseTapped) {
            $0.playbackState.status = .paused
            $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                configuration: configuration,
                playbackProgressPercent: pausedProgress
            )
        }

        let remainingDuration = store.state.playbackState.remainingDuration
        await clock.advance(by: .seconds(1))
        #expect(store.state.playbackState.remainingDuration == remainingDuration)
        #expect(store.state.playbackState.status == .paused)
    }

    @MainActor
    @Test("loadConfiguration successfully loads and updates state")
    func loadConfigurationSucceeds() async throws {
        let loadedConfiguration = TrackConfiguration(
            totalDuration: 200,
            clipStart: 10,
            clipDuration: 20,
            keyTimePercentages: [30, 60, 90]
        )
        let clock = TestClock()

        let store = TestStore(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        } withDependencies: {
            $0.configurationLoader = ConfigurationLoader {
                loadedConfiguration
            }
            $0.continuousClock = clock
        }

        await store.send(.loadConfiguration)

        await store.receive(.configurationLoaded(loadedConfiguration)) {
            $0.configuration = loadedConfiguration
            $0.playbackState = .idle(configuration: loadedConfiguration)
            $0.timeline = AudioTrimmerFeature.TimelineSnapshot(
                configuration: loadedConfiguration,
                playbackProgressPercent: 0
            )
        }
    }

    @MainActor
    @Test("loadConfiguration handles errors and sends loadConfigurationFailed action")
    func loadConfigurationHandlesErrors() async throws {
        let testError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load configuration"])

        let store = TestStore(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        } withDependencies: {
            $0.configurationLoader = ConfigurationLoader {
                throw testError
            }
        }

        await store.send(.loadConfiguration)

        await store.receive(.loadConfigurationFailed("Failed to load configuration"))
        // State should remain unchanged on error
    }

}

private func timelineSnapshot(
    configuration: TrackConfiguration,
    currentPosition: TimeInterval
) -> AudioTrimmerFeature.TimelineSnapshot {
    let denominator = configuration.clipDuration > 0 ? configuration.clipDuration : 1
    let rawProgress = (currentPosition - configuration.clipStart) / denominator
    let currentProgressPercent = rawProgress.clamped()

    return .init(
        configuration: configuration,
        playbackProgressPercent: currentProgressPercent
    )
}

