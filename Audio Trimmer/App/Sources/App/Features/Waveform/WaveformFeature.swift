import ComposableArchitecture
import Foundation

@Reducer
struct WaveformFeature {
    @ObservableState
    struct State: Equatable {
        var totalDuration: TimeInterval
        var clipStart: TimeInterval
        var clipDuration: TimeInterval
        var scrollOffset: CGFloat = 0
        var dragStartOffset: CGFloat = 0
        var isDragging: Bool = false
        var text: String {
            "Scroll Offset: \(scrollOffset)\nDrag Start Offset: \(dragStartOffset)\nIs Dragging: \(isDragging)"
        }
                
        init(
            totalDuration: TimeInterval = 0,
            clipStart: TimeInterval = 0,
            clipDuration: TimeInterval = 0,
            scrollOffset: CGFloat = 0,
            dragStartOffset: CGFloat = 0,
            isDragging: Bool = false
        ) {
            self.totalDuration = totalDuration
            self.clipStart = clipStart
            self.clipDuration = clipDuration
            self.scrollOffset = scrollOffset
            self.dragStartOffset = dragStartOffset
            self.isDragging = isDragging
        }
    }
    
    enum Action: Equatable {
        case dragStarted
        case dragChanged(translation: CGFloat, maxOffset: CGFloat)
        case dragEnded
        case syncDragStartOffset
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .dragStarted:
                state.isDragging = true
                state.dragStartOffset = state.scrollOffset
                return .none
                
            case .dragChanged(let translation, let maxOffset):
                // Reversed: left swipe moves content left, right swipe moves content right
                let newOffset = state.dragStartOffset + translation
                // Clamp offset to valid range [minOffset, 0] where minOffset is negative
                let minOffset = -maxOffset
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
            }
        }
    }
}

