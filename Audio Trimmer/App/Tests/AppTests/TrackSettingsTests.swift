import ComposableArchitecture
import CoreGraphics
import Testing
@testable import App

@Suite("TrackSettingsFeature")
struct TrackSettingsTests {
    @MainActor
    @Test
    func confirm_withValidInputs_navigatesWithCorrectConfiguration() async {
        let store = TestStore(
            initialState: AppRootFeature.State()
        ) {
            AppRootFeature()
        }
        
        await store.send(.trackSettings(.binding(.set(\.totalDurationText, "120")))) {
            $0.trackSettings.totalDurationText = "120"
        }
        await store.send(.trackSettings(.binding(.set(\.keyTimesText, "25, 75")))) {
            $0.trackSettings.keyTimesText = "25, 75"
        }
        await store.send(.trackSettings(.binding(.set(\.clipStartText, "10")))) {
            $0.trackSettings.clipStartText = "10"
        }
        await store.send(.trackSettings(.binding(.set(\.clipPercentText, "10")))) {
            $0.trackSettings.clipPercentText = "10"
        }
        
        await store.send(.trackSettings(.confirmTapped))
        
        // Receive the delegate action
        let configuration = TrackConfiguration(
            totalDuration: 120,
            clipStart: 10,
            clipDuration: 12,
            keyTimePercentages: [25, 75]
        )
        store.exhaustivity = .off
        await store.receive(.trackSettings(.delegate(.confirmed(configuration))))
        store.exhaustivity = .on
        
        // Verify path contains audioTrimmer
        #expect(store.state.path.count == 1)
        guard let id = store.state.path.ids.first else {
            #expect(Bool(false), "Expected path to have an id")
            return
        }
        
        if case .audioTrimmer(let audioTrimmerState) = store.state.path.first {
            let config = audioTrimmerState.configuration
            #expect(config.totalDuration == 120)
            #expect(config.clipStart == 10)
            #expect(abs(config.clipDuration - 12) < 0.0001)
            #expect(config.keyTimePercentages == [25, 75])
        } else {
            #expect(Bool(false), "Expected audioTrimmer in path")
        }
        
        // Verify onAppear action is sent and handled
        await store.receive(.path(.element(id: id, action: .audioTrimmer(.onAppear)))) {
            if case .audioTrimmer(var audioTrimmerState) = $0.path[id: id] {
                audioTrimmerState.playbackState = .idle(configuration: configuration)
                audioTrimmerState.timeline = AudioTrimmerFeature.TimelineSnapshot(
                    configuration: configuration,
                    playbackProgressPercent: configuration.clipStart / configuration.totalDuration,
                    clipProgressPercent: 0
                )
                $0.path[id: id] = .audioTrimmer(audioTrimmerState)
            }
        }
        
        // Verify waveform updateScrollOffsetFromClipStart action is sent
        await store.receive(.path(.element(id: id, action: .audioTrimmer(.waveform(.updateScrollOffsetFromClipStart))))) {
            if case .audioTrimmer(var audioTrimmerState) = $0.path[id: id] {
                let percent = (configuration.clipStart / configuration.totalDuration).clamped()
                let position = CGFloat(percent) * audioTrimmerState.waveform.viewConfiguration.waveformItemsWidth
                let clampedOffset = max(0, min(position, audioTrimmerState.waveform.viewConfiguration.maxOffset))
                audioTrimmerState.waveform.scrollOffset = -clampedOffset
                audioTrimmerState.waveform.dragStartOffset = -clampedOffset
                $0.path[id: id] = .audioTrimmer(audioTrimmerState)
            }
        }
    }
    
    @MainActor
    @Test
    func confirm_withInvalidKeyTimes_showsErrorAndDoesNotNavigate() async {
        let store = TestStore(
            initialState: AppRootFeature.State()
        ) {
            AppRootFeature()
        }
        
        await store.send(.trackSettings(.binding(.set(\.totalDurationText, "60")))) {
            $0.trackSettings.totalDurationText = "60"
        }
        await store.send(.trackSettings(.binding(.set(\.keyTimesText, "101")))) {
            $0.trackSettings.keyTimesText = "101"
        }
        await store.send(.trackSettings(.binding(.set(\.clipStartText, "0")))) {
            $0.trackSettings.clipStartText = "0"
        }
        await store.send(.trackSettings(.binding(.set(\.clipPercentText, "10")))) {
            $0.trackSettings.clipPercentText = "10"
        }
        
        await store.send(.trackSettings(.confirmTapped)) {
            $0.trackSettings.keyTimesError = "Key times must be between 0% and 100%."
        }
        
        #expect(store.state.path.isEmpty)
        #expect(store.state.trackSettings.keyTimesError != nil)
    }
}


