import ComposableArchitecture
import Foundation
import Testing
@testable import App

@Suite("WaveformFeature")
struct WaveformTests {
    @MainActor
    @Test("state initializes with default values")
    func stateInitializesWithDefaults() {
        let state = WaveformFeature.State()
        #expect(state.totalDuration == 0)
        #expect(state.clipStart == 0)
        #expect(state.clipDuration == 0)
        #expect(state.scrollTargetIndex == nil)
    }
    
    @MainActor
    @Test("state initializes with custom values")
    func stateInitializesWithCustomValues() {
        let state = WaveformFeature.State(
            totalDuration: 120,
            clipStart: 10,
            clipDuration: 30,
            scrollTargetIndex: 5
        )
        #expect(state.totalDuration == 120)
        #expect(state.clipStart == 10)
        #expect(state.clipDuration == 30)
        #expect(state.scrollTargetIndex == 5)
    }
    
    @MainActor
    @Test("state equality works correctly")
    func stateEqualityWorks() {
        let state1 = WaveformFeature.State(
            totalDuration: 60,
            clipStart: 0,
            clipDuration: 12,
            scrollTargetIndex: 2
        )
        let state2 = WaveformFeature.State(
            totalDuration: 60,
            clipStart: 0,
            clipDuration: 12,
            scrollTargetIndex: 2
        )
        let state3 = WaveformFeature.State(
            totalDuration: 60,
            clipStart: 0,
            clipDuration: 12,
            scrollTargetIndex: 3
        )
        #expect(state1 == state2)
        #expect(state1 != state3)
    }
    
    @MainActor
    @Test("imageCount returns minimum of 10 when totalDuration is less than 60")
    func imageCountReturnsMinimumForShortDuration() {
        let state1 = WaveformFeature.State(totalDuration: 0)
        #expect(state1.imageCount == 10) // 60 / 6 = 10
        
        let state2 = WaveformFeature.State(totalDuration: 1)
        #expect(state2.imageCount == 10)
        
        let state3 = WaveformFeature.State(totalDuration: 5)
        #expect(state3.imageCount == 10)
        
        let state4 = WaveformFeature.State(totalDuration: 59)
        #expect(state4.imageCount == 10)
    }
    
    @MainActor
    @Test("imageCount returns 10 when totalDuration equals 60")
    func imageCountReturns10For60Seconds() {
        let state = WaveformFeature.State(totalDuration: 60)
        #expect(state.imageCount == 10) // 60 / 6 = 10
    }
    
    @MainActor
    @Test("imageCount returns duration divided by 6 when totalDuration is greater than 60")
    func imageCountReturnsDurationDividedBy6ForLongDuration() {
        let state1 = WaveformFeature.State(totalDuration: 120)
        #expect(state1.imageCount == 20) // 120 / 6 = 20
        
        let state2 = WaveformFeature.State(totalDuration: 300)
        #expect(state2.imageCount == 50) // 300 / 6 = 50
        
        let state3 = WaveformFeature.State(totalDuration: 66)
        #expect(state3.imageCount == 11) // 66 / 6 = 11
    }
    
    @MainActor
    @Test("scrollToIndex sets valid index within bounds")
    func scrollToIndexSetsValidIndex() async {
        let store = TestStore(initialState: WaveformFeature.State(totalDuration: 120)) {
            WaveformFeature()
        }
        
        // Test middle index
        await store.send(.scrollToIndex(10)) {
            $0.scrollTargetIndex = 10
        }
        
        // Test first valid index
        await store.send(.scrollToIndex(0)) {
            $0.scrollTargetIndex = 0
        }
        
        // Test last valid index (imageCount - 1 = 19)
        await store.send(.scrollToIndex(19)) {
            $0.scrollTargetIndex = 19
        }
    }
    
    @MainActor
    @Test("scrollToIndex rejects negative index")
    func scrollToIndexRejectsNegativeIndex() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollTargetIndex: 10
        )) {
            WaveformFeature()
        }
        
        await store.send(.scrollToIndex(-1)) {
            $0.scrollTargetIndex = nil
        }
        
        // Set a valid index first, then test another invalid index
        await store.send(.scrollToIndex(5)) {
            $0.scrollTargetIndex = 5
        }
        
        await store.send(.scrollToIndex(-10)) {
            $0.scrollTargetIndex = nil
        }
    }
    
    @MainActor
    @Test("scrollToIndex rejects index greater than or equal to imageCount")
    func scrollToIndexRejectsOutOfBoundsIndex() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollTargetIndex: 10
        )) {
            WaveformFeature()
        }
        // imageCount = 120 / 6 = 20, so valid indices are 0-19
        
        // Test index equal to imageCount
        await store.send(.scrollToIndex(20)) {
            $0.scrollTargetIndex = nil
        }
        
        // Set a valid index first, then test another invalid index
        await store.send(.scrollToIndex(5)) {
            $0.scrollTargetIndex = 5
        }
        
        // Test index greater than imageCount
        await store.send(.scrollToIndex(25)) {
            $0.scrollTargetIndex = nil
        }
    }
    
    @MainActor
    @Test("scrollToIndex accepts nil index")
    func scrollToIndexAcceptsNil() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollTargetIndex: 10
        )) {
            WaveformFeature()
        }
        
        await store.send(.scrollToIndex(nil)) {
            $0.scrollTargetIndex = nil
        }
    }
    
    @MainActor
    @Test("scrollToIndex handles boundary cases correctly")
    func scrollToIndexHandlesBoundaries() async {
        let store = TestStore(initialState: WaveformFeature.State(totalDuration: 60)) {
            WaveformFeature()
        }
        // imageCount = 60 / 6 = 10, so valid indices are 0-9
        
        // Test index 0 (first valid)
        await store.send(.scrollToIndex(0)) {
            $0.scrollTargetIndex = 0
        }
        
        // Test index = imageCount - 1 (last valid)
        await store.send(.scrollToIndex(9)) {
            $0.scrollTargetIndex = 9
        }
        
        // Test index = imageCount (invalid) - start with a valid index first
        await store.send(.scrollToIndex(5)) {
            $0.scrollTargetIndex = 5
        }
        
        await store.send(.scrollToIndex(10)) {
            $0.scrollTargetIndex = nil
        }
    }
    
    @MainActor
    @Test("scrollToIndex validation works with different durations")
    func scrollToIndexValidationWithDifferentDurations() async {
        // Test with short duration (minimum imageCount = 10)
        let store1 = TestStore(initialState: WaveformFeature.State(totalDuration: 30)) {
            WaveformFeature()
        }
        // imageCount = 10 (minimum), valid indices are 0-9
        
        await store1.send(.scrollToIndex(5)) {
            $0.scrollTargetIndex = 5
        }
        
        await store1.send(.scrollToIndex(9)) {
            $0.scrollTargetIndex = 9
        }
        
        // Test invalid index - should clear the valid index
        await store1.send(.scrollToIndex(10)) {
            $0.scrollTargetIndex = nil
        }
        
        // Test with long duration
        let store2 = TestStore(initialState: WaveformFeature.State(
            totalDuration: 300,
            scrollTargetIndex: 25
        )) {
            WaveformFeature()
        }
        // imageCount = 50, valid indices are 0-49
        
        // Change to a different valid index
        await store2.send(.scrollToIndex(49)) {
            $0.scrollTargetIndex = 49
        }
        
        // Test invalid index - should clear the valid index
        await store2.send(.scrollToIndex(50)) {
            $0.scrollTargetIndex = nil
        }
    }
}

