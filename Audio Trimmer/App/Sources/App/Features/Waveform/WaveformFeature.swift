import ComposableArchitecture
import Foundation

@Reducer
struct WaveformFeature {
    @ObservableState
    struct State: Equatable {
        var totalDuration: TimeInterval
        var clipStart: TimeInterval
        var clipDuration: TimeInterval
        var scrollTargetIndex: Int?
        
        var imageCount: Int {
            let duration = max(totalDuration, 60)
            return Int(duration / 6)
        }
        
        init(
            totalDuration: TimeInterval = 0,
            clipStart: TimeInterval = 0,
            clipDuration: TimeInterval = 0,
            scrollTargetIndex: Int? = nil
        ) {
            self.totalDuration = totalDuration
            self.clipStart = clipStart
            self.clipDuration = clipDuration
            self.scrollTargetIndex = scrollTargetIndex
        }
    }
    
    enum Action: Equatable {
        case scrollToIndex(Int?)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .scrollToIndex(let index):
                // Validate index is within bounds
                if let targetIndex = index, targetIndex >= 0 && targetIndex < state.imageCount {
                    state.scrollTargetIndex = targetIndex
                } else {
                    state.scrollTargetIndex = nil
                }
                return .none
            }
        }
    }
}

