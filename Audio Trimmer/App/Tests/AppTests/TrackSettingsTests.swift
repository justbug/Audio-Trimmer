import ComposableArchitecture
import Testing
@testable import App

@Suite("TrackSettingsFeature")
struct TrackSettingsTests {
    @Test
    func confirm_withValidInputs_navigatesWithCorrectConfiguration() async {
        let store = TestStore(
            initialState: AppRootFeature.State()
        ) {
            AppRootFeature()
        }
        
        await store.send(.trackSettings(.binding(.set(\.totalDurationText, "120"))))
        await store.send(.trackSettings(.binding(.set(\.keyTimesText, "25, 75"))))
        await store.send(.trackSettings(.binding(.set(\.clipStartText, "10"))))
        await store.send(.trackSettings(.binding(.set(\.clipPercentText, "10"))))
        
        await store.send(.trackSettings(.confirmTapped))
        
        #expect(store.state.audioTrimmer != nil)
        let config = store.state.audioTrimmer!.configuration
        #expect(config.totalDuration == 120)
        #expect(config.clipStart == 10)
        #expect(abs(config.clipDuration - 12) < 0.0001)
        #expect(config.keyTimePercentages == [25, 75])
    }
    
    @Test
    func confirm_withInvalidKeyTimes_showsErrorAndDoesNotNavigate() async {
        let store = TestStore(
            initialState: AppRootFeature.State()
        ) {
            AppRootFeature()
        }
        
        await store.send(.trackSettings(.binding(.set(\.totalDurationText, "60"))))
        await store.send(.trackSettings(.binding(.set(\.keyTimesText, "101"))))
        await store.send(.trackSettings(.binding(.set(\.clipStartText, "0"))))
        await store.send(.trackSettings(.binding(.set(\.clipPercentText, "10"))))
        
        await store.send(.trackSettings(.confirmTapped))
        
        #expect(store.state.audioTrimmer == nil)
        #expect(store.state.trackSettings.keyTimesError != nil)
    }
}


