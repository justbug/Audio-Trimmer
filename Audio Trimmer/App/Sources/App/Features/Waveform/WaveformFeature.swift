import ComposableArchitecture
import Foundation

@Reducer
struct WaveformFeature {
    @ObservableState
    struct State: Equatable {
        struct ViewConfiguration: Equatable {
            let itemSize: CGFloat = 60
            let itemsCount: Int = 10
            
            var borderWidth: CGFloat {
                itemSize
            }

            var waveformItemsWidth: CGFloat {
                CGFloat(itemsCount) * itemSize
            }
            
            var maxOffset: CGFloat {
                waveformItemsWidth - borderWidth
            }
        }

        var totalDuration: TimeInterval
        var clipStart: TimeInterval
        var clipDuration: TimeInterval
        var scrollOffset: CGFloat = 0
        var dragStartOffset: CGFloat = 0
        var isDragging: Bool = false
        var clipProgressPercent: Double = 0
        let viewConfiguration: ViewConfiguration

        init(
            totalDuration: TimeInterval = 0,
            clipStart: TimeInterval = 0,
            clipDuration: TimeInterval = 0,
            scrollOffset: CGFloat = 0,
            dragStartOffset: CGFloat = 0,
            isDragging: Bool = false,
            clipProgressPercent: Double = 0,
            viewConfiguration: ViewConfiguration = ViewConfiguration()
        ) {
            self.totalDuration = totalDuration
            self.clipStart = clipStart
            self.clipDuration = clipDuration
            self.scrollOffset = scrollOffset
            self.dragStartOffset = dragStartOffset
            self.isDragging = isDragging
            self.clipProgressPercent = clipProgressPercent
            self.viewConfiguration = viewConfiguration
        }
    }
    
    enum Action: Equatable {
        case dragStarted
        case dragChanged(translation: CGFloat)
        case dragEnded
        case syncDragStartOffset
        case updateScrollOffsetFromClipStart
    }
    
    var body: some ReducerOf<Self> {
        Reduce { (state, action) -> Effect<Action> in
            switch action {
            case .dragStarted:
                state.isDragging = true
                state.dragStartOffset = state.scrollOffset
                return .none
                
            case .dragChanged(let translation):
                // Reversed: left swipe moves content left, right swipe moves content right
                let newOffset = state.dragStartOffset + translation
                // Clamp offset to valid range [minOffset, 0] where minOffset is negative
                let minOffset = -state.viewConfiguration.maxOffset
                state.scrollOffset = max(minOffset, min(newOffset, 0))
                return .none
            case .dragEnded:
                state.isDragging = false
                state.dragStartOffset = state.scrollOffset
                return .none
                
            case .syncDragStartOffset:
                if !state.isDragging {
                    state.dragStartOffset = state.scrollOffset
                }
                return .none
                
            case .updateScrollOffsetFromClipStart:
                guard !state.isDragging else {
                    return .none
                }
                
                guard state.viewConfiguration.maxOffset > 0,
                      state.totalDuration > 0 else {
                    state.scrollOffset = 0
                    state.dragStartOffset = 0
                    return .none
                }
                
                // Calculate the valid clipStart range
                let maxClipStart = max(0, state.totalDuration - state.clipDuration)
                
                // If maxClipStart is 0, set scrollOffset to 0 (no scrolling needed)
                guard maxClipStart > 0 else {
                    state.scrollOffset = 0
                    state.dragStartOffset = 0
                    return .none
                }
                
                // Calculate percent based on clipStart position in the valid range
                // clipStart range: [0, maxClipStart] → percent range: [0, 1]
                let percent = (state.clipStart / maxClipStart).clamped()
                
                // Map percent to scrollOffset range: [0, maxOffset] → [-maxOffset, 0]
                let clampedOffset = CGFloat(percent) * state.viewConfiguration.maxOffset
                state.scrollOffset = -clampedOffset
                state.dragStartOffset = state.scrollOffset
                return .none
            }
        }
    }
}
