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
        #expect(state.scrollOffset == 0)
        #expect(state.isDragging == false)
    }
    
    @MainActor
    @Test("state initializes with custom values")
    func stateInitializesWithCustomValues() {
        let state = WaveformFeature.State(
            totalDuration: 120,
            clipStart: 10,
            clipDuration: 30,
            scrollOffset: -50
        )
        #expect(state.totalDuration == 120)
        #expect(state.clipStart == 10)
        #expect(state.clipDuration == 30)
        #expect(state.scrollOffset == -50)
    }
    
    @MainActor
    @Test("state equality works correctly")
    func stateEqualityWorks() {
        let state1 = WaveformFeature.State(
            totalDuration: 60,
            clipStart: 0,
            clipDuration: 12,
            scrollOffset: -20
        )
        let state2 = WaveformFeature.State(
            totalDuration: 60,
            clipStart: 0,
            clipDuration: 12,
            scrollOffset: -20
        )
        let state3 = WaveformFeature.State(
            totalDuration: 60,
            clipStart: 0,
            clipDuration: 12,
            scrollOffset: -30
        )
        #expect(state1 == state2)
        #expect(state1 != state3)
    }
    
    @MainActor
    @Test("viewConfiguration has correct default values")
    func viewConfigurationHasCorrectDefaults() {
        let state = WaveformFeature.State()
        #expect(state.viewConfiguration.itemSize == 60)
        #expect(state.viewConfiguration.itemsCount == 10)
        #expect(state.viewConfiguration.borderWidth == 60)
        #expect(state.viewConfiguration.waveformItemsWidth == 600)
        #expect(state.viewConfiguration.maxOffset == 540)
    }
    
    @MainActor
    @Test("dragStarted sets isDragging and saves dragStartOffset")
    func dragStartedSetsDragging() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollOffset: -100
        )) {
            WaveformFeature()
        }
        
        await store.send(.dragStarted) {
            $0.isDragging = true
            $0.dragStartOffset = -100
        }
    }
    
    @MainActor
    @Test("dragChanged updates scrollOffset within bounds")
    func dragChangedUpdatesScrollOffset() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollOffset: -100,
            dragStartOffset: -100,
            isDragging: true
        )) {
            WaveformFeature()
        }
        
        // Test positive translation (right swipe)
        await store.send(.dragChanged(translation: 50)) {
            $0.scrollOffset = -50  // dragStartOffset(-100) + translation(50) = -50
        }
        
        // Test negative translation (left swipe) - uses original dragStartOffset
        await store.send(.dragChanged(translation: -30)) {
            $0.scrollOffset = -130  // dragStartOffset(-100) + translation(-30) = -130
        }
        
        // Test clamping to maxOffset
        await store.send(.dragChanged(translation: 600)) {
            $0.scrollOffset = 0
        }
        
        // Test clamping to minOffset
        await store.send(.dragChanged(translation: -1000)) {
            $0.scrollOffset = -540
        }
    }
    
    @MainActor
    @Test("dragEnded clears isDragging and updates dragStartOffset")
    func dragEndedClearsDragging() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollOffset: -150,
            dragStartOffset: -100,
            isDragging: true
        )) {
            WaveformFeature()
        }
        
        await store.send(.dragEnded) {
            $0.isDragging = false
            $0.dragStartOffset = -150
        }
    }
    
    @MainActor
    @Test("updateScrollOffsetFromClipStart calculates correct offset")
    func updateScrollOffsetFromClipStartCalculatesOffset() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            clipStart: 30,
            clipDuration: 20,
            scrollOffset: 0,
            isDragging: false
        )) {
            WaveformFeature()
        }
        
        await store.send(.updateScrollOffsetFromClipStart) {
            // clipStart = 30, totalDuration = 120, clipDuration = 20
            // maxClipStart = max(0, 120 - 20) = 100
            // percent = 30/100 = 0.3
            // maxOffset = waveformItemsWidth - borderWidth = (10 * 60) - 60 = 540
            // clampedOffset = 0.3 * 540 = 162
            // scrollOffset = -162
            $0.scrollOffset = -162
            $0.dragStartOffset = -162
        }
    }
    
    @MainActor
    @Test("updateScrollOffsetFromClipStart does nothing when dragging")
    func updateScrollOffsetFromClipStartIgnoresWhenDragging() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            clipStart: 30,
            clipDuration: 20,
            scrollOffset: -100,
            isDragging: true
        )) {
            WaveformFeature()
        }
        
        await store.send(.updateScrollOffsetFromClipStart)
    }
    
    @MainActor
    @Test("updateScrollOffsetFromClipStart resets to zero for invalid state")
    func updateScrollOffsetFromClipStartResetsForInvalidState() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 0,
            clipStart: 0,
            clipDuration: 0,
            scrollOffset: -100,
            isDragging: false
        )) {
            WaveformFeature()
        }
        
        await store.send(.updateScrollOffsetFromClipStart) {
            $0.scrollOffset = 0
            $0.dragStartOffset = 0
        }
    }
    
    @MainActor
    @Test("syncDragStartOffset updates dragStartOffset when not dragging")
    func syncDragStartOffsetUpdatesWhenNotDragging() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollOffset: -200,
            dragStartOffset: -100,
            isDragging: false
        )) {
            WaveformFeature()
        }
        
        await store.send(.syncDragStartOffset) {
            $0.dragStartOffset = -200
        }
    }
    
    @MainActor
    @Test("syncDragStartOffset does nothing when dragging")
    func syncDragStartOffsetIgnoresWhenDragging() async {
        let store = TestStore(initialState: WaveformFeature.State(
            totalDuration: 120,
            scrollOffset: -200,
            dragStartOffset: -100,
            isDragging: true
        )) {
            WaveformFeature()
        }
        
        await store.send(.syncDragStartOffset)
    }
}

