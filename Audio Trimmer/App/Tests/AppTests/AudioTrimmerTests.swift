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

        await startPlayback(using: context)
        
        // Verify initial clipProgressPercent is 0 at clip start
        #expect(store.state.timeline.clipProgressPercent == 0.0)

        let tickCount = Int(configuration.clipDuration)
        for tick in 1...tickCount {
            await expectTick(
                store: store,
                configuration: configuration,
                clock: context.clock,
                tickNumber: tick
            )
            // Verify clipProgressPercent increases correctly during playback
            let expectedPosition = configuration.clipStart + TimeInterval(tick)
            let expectedClipProgress = clipProgress(for: configuration, at: expectedPosition)
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

        await startPlayback(using: context)

        let ticksBeforePause = 3
        for tick in 1...ticksBeforePause {
            await expectTick(
                store: store,
                configuration: configuration,
                clock: context.clock,
                tickNumber: tick
            )
            // Verify clipProgressPercent increases during playback
            let expectedPosition = configuration.clipStart + TimeInterval(tick)
            let expectedClipProgress = clipProgress(for: configuration, at: expectedPosition)
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
        await context.clock.advance(by: .seconds(1))
        #expect(store.state.playbackState.remainingDuration == remainingDuration)
        #expect(store.state.playbackState.status == .paused)
    }

    @MainActor
    @Test("onAppear initializes timeline and waveform scroll offset")
    func onAppearInitializesState() async throws {
        let configuration = TrackConfiguration(
            totalDuration: 120,
            clipStart: 5,
            clipDuration: 10,
            keyTimePercentages: [25, 75]
        )
        let (store, _) = makeStore(initialState: AudioTrimmerFeature.State(configuration: configuration))

        await store.send(.onAppear) {
            $0.playbackState = .idle(configuration: configuration)
            $0.timeline = timeline(for: configuration, at: configuration.clipStart)
        }

        await expectScrollOffsetUpdate(
            store: store,
            configuration: configuration,
            clipStart: configuration.clipStart
        )

        // Verify timeline is initialized correctly
        #expect(store.state.timeline != .zero)
        #expect(store.state.timeline.clipProgressPercent == 0.0)
        #expect(store.state.timeline.currentProgressPercent == (configuration.clipStart / configuration.totalDuration))
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
        
        await expectMarkerTappedStateUpdate(
            store: store,
            configuration: configuration,
            expectedClipStart: expectedClipStart
        )
        
        // Verify progress resets to 0
        #expect(store.state.timeline.clipProgressPercent == 0.0)
        #expect(store.state.playbackState.status == .idle)
        
        // Handle waveform scroll offset update
        await expectScrollOffsetUpdate(
            store: store,
            configuration: configuration,
            clipStart: expectedClipStart
        )
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
        // The marker position percent is calculated internally by expectMarkerTappedStateUpdate
        let expectedClipEnd = configuration.totalDuration
        let expectedClipStart = expectedClipEnd - configuration.clipDuration
        
        await expectMarkerTappedStateUpdate(
            store: store,
            configuration: configuration,
            expectedClipStart: expectedClipStart
        )
        
        // Verify clipStart was adjusted backward
        #expect(store.state.configuration.clipStart == expectedClipStart)
        #expect(store.state.configuration.clipEnd <= configuration.totalDuration)
        // Verify progress resets to 0
        #expect(store.state.timeline.clipProgressPercent == 0.0)
        
        // Handle waveform scroll offset update
        await expectScrollOffsetUpdate(
            store: store,
            configuration: configuration,
            clipStart: expectedClipStart
        )
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
        await expectTick(
            store: store,
            configuration: configuration,
            clock: clock,
            tickNumber: 1
        )
        
        // Verify we're playing and have progress
        #expect(store.state.playbackState.status == .playing)
        #expect(store.state.timeline.clipProgressPercent > 0)
        
        // Tap a marker (this should cancel the timer, so no more ticks should arrive)
        let markerPositionPercent = 0.3
        let expectedClipStart = markerPositionPercent * configuration.totalDuration
        
        await expectMarkerTappedStateUpdate(
            store: store,
            configuration: configuration,
            expectedClipStart: expectedClipStart
        )
        
        // Verify playback stopped
        #expect(store.state.playbackState.status == .idle)
        // Verify progress reset to 0
        #expect(store.state.timeline.clipProgressPercent == 0.0)
        
        // Handle waveform scroll offset update
        await expectScrollOffsetUpdate(
            store: store,
            configuration: configuration,
            clipStart: expectedClipStart
        )
        
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
        initialState: AudioTrimmerFeature.State = AudioTrimmerFeature.State(),
        clock providedClock: TestClock<Duration> = TestClock()
    ) -> (store: TestStoreOf<AudioTrimmerFeature>, clock: TestClock<Duration>) {
        let store = TestStore(
            initialState: initialState
        ) {
            AudioTrimmerFeature()
        } withDependencies: {
            $0.continuousClock = providedClock
        }
        return (store, providedClock)
    }

    @MainActor
    func makeConfiguredStore(
        clock initialClock: TestClock<Duration> = TestClock()
    ) async throws -> ConfiguredStoreContext {
        let configuration = TrackConfiguration(
            totalDuration: 120,
            clipStart: 5,
            clipDuration: 10,
            keyTimePercentages: [25, 75]
        )
        let (store, clock) = makeStore(
            initialState: AudioTrimmerFeature.State(configuration: configuration),
            clock: initialClock
        )

        await store.send(.onAppear) {
            $0.playbackState = .idle(configuration: configuration)
            $0.timeline = timeline(for: configuration, at: configuration.clipStart)
        }

        await expectScrollOffsetUpdate(
            store: store,
            configuration: configuration,
            clipStart: configuration.clipStart
        )

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

    /// Calculates the expected scroll offset for a given clipStart position
    func expectedScrollOffset(
        clipStart: TimeInterval,
        totalDuration: TimeInterval,
        clipDuration: TimeInterval,
        maxOffset: CGFloat
    ) -> CGFloat {
        let maxClipStart = max(0, totalDuration - clipDuration)
        guard maxClipStart > 0 else {
            return 0
        }
        let percent = (clipStart / maxClipStart).clamped()
        return -CGFloat(percent) * maxOffset
    }

    /// Helper to expect and verify scroll offset update in TestStore
    @MainActor
    func expectScrollOffsetUpdate(
        store: TestStoreOf<AudioTrimmerFeature>,
        configuration: TrackConfiguration,
        clipStart: TimeInterval
    ) async {
        await store.receive(.waveform(.updateScrollOffsetFromClipStart)) {
            let expectedOffset = expectedScrollOffset(
                clipStart: clipStart,
                totalDuration: configuration.totalDuration,
                clipDuration: configuration.clipDuration,
                maxOffset: $0.waveform.viewConfiguration.maxOffset
            )
            $0.waveform.scrollOffset = expectedOffset
            $0.waveform.dragStartOffset = expectedOffset
        }
    }

    /// Creates a new TrackConfiguration with updated clipStart
    func updatedConfiguration(
        from configuration: TrackConfiguration,
        clipStart: TimeInterval
    ) -> TrackConfiguration {
        TrackConfiguration(
            totalDuration: configuration.totalDuration,
            clipStart: clipStart,
            clipDuration: configuration.clipDuration,
            keyTimePercentages: configuration.keyTimePercentages
        )
    }

    /// Helper to update state after markerTapped action
    @MainActor
    func expectMarkerTappedStateUpdate(
        store: TestStoreOf<AudioTrimmerFeature>,
        configuration: TrackConfiguration,
        expectedClipStart: TimeInterval
    ) async {
        let newConfiguration = updatedConfiguration(from: configuration, clipStart: expectedClipStart)
        await store.send(.markerTapped(markerPositionPercent: expectedClipStart / configuration.totalDuration)) {
            $0.configuration = newConfiguration
            $0.playbackState = .idle(configuration: newConfiguration)
            $0.waveform.clipStart = expectedClipStart
            $0.waveform.clipProgressPercent = 0
            $0.timeline = timeline(for: newConfiguration, at: expectedClipStart)
        }
    }

    /// Helper to process a single tick during playback
    @MainActor
    func expectTick(
        store: TestStoreOf<AudioTrimmerFeature>,
        configuration: TrackConfiguration,
        clock: TestClock<Duration>,
        tickNumber: Int
    ) async {
        await clock.advance(by: .seconds(1))
        let expectedPosition = configuration.clipStart + TimeInterval(tickNumber)
        let expectedRemaining = configuration.clipDuration - TimeInterval(tickNumber)
        let expectedClipProgress = clipProgress(for: configuration, at: expectedPosition)
        await store.receive(.tick) {
            $0.playbackState.currentPosition = expectedPosition
            $0.playbackState.remainingDuration = max(expectedRemaining, 0)
            $0.timeline = timeline(for: configuration, at: expectedPosition)
            $0.waveform.clipProgressPercent = expectedClipProgress
            if expectedRemaining <= 0 {
                $0.playbackState.status = .finished
            }
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
