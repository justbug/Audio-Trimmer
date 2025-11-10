import ComposableArchitecture
import Foundation

@Reducer
struct TrackSettingsFeature {
    @ObservableState
    struct State: Equatable {
        // Raw form fields (Strings for SwiftUI bindings)
        var totalDurationText: String = ""
        var keyTimesText: String = ""
        var clipStartText: String = ""
        var clipPercentText: String = ""
        
        // Field-level error messages
        var totalDurationError: String?
        var keyTimesError: String?
        var clipStartError: String?
        var clipPercentError: String?
        
        // Computed: confirm button enabled
        var isConfirmEnabled: Bool {
            !totalDurationText.isEmpty &&
            !keyTimesText.isEmpty &&
            !clipStartText.isEmpty &&
            !clipPercentText.isEmpty &&
            totalDurationError == nil &&
            keyTimesError == nil &&
            clipStartError == nil &&
            clipPercentError == nil
        }
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case confirmTapped
        case delegate(Delegate)
    }
    
    enum Delegate: Equatable {
        case confirmed(TrackConfiguration)
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                // Clear errors when user edits fields
                state.totalDurationError = nil
                state.keyTimesError = nil
                state.clipStartError = nil
                state.clipPercentError = nil
                return .none
                
            case .confirmTapped:
                // Validate and map to TrackConfiguration
                let parsed = parseAndValidate(state: &state)
                switch parsed {
                case .success(let config):
                    return .send(.delegate(.confirmed(config)))
                case .failure:
                    return .none
                }
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Validation & Mapping
private extension TrackSettingsFeature {
    struct Parsed {
        let totalDuration: TimeInterval
        let clipStart: TimeInterval
        let clipPercent: Double
        let clipDuration: TimeInterval
        let keyTimes: [Double]
    }
    
    func parseAndValidate(state: inout State) -> Result<TrackConfiguration, Void> {
        // Parse numbers
        guard let totalDuration = TimeInterval(state.totalDurationText.trimmingCharacters(in: .whitespaces)),
              totalDuration > 0
        else {
            state.totalDurationError = "Track length must be greater than 0."
            return .failure(())
        }
        
        guard let clipStart = TimeInterval(state.clipStartText.trimmingCharacters(in: .whitespaces)),
              clipStart >= 0
        else {
            state.clipStartError = "Clip start must be ≥ 0."
            return .failure(())
        }
        
        guard let clipPercent = Double(state.clipPercentText.trimmingCharacters(in: .whitespaces)),
              clipPercent > 0, clipPercent <= 100
        else {
            state.clipPercentError = "Clip percent must be in (0, 100]."
            return .failure(())
        }
        
        // Compute clip duration
        let clipDuration = totalDuration * (clipPercent / 100.0)
        if clipDuration <= 0 {
            state.clipPercentError = "Clip percent too small; duration must be > 0."
            return .failure(())
        }
        
        // Key times parsing and normalization
        let separators = CharacterSet(charactersIn: ", ")
        let tokens = state.keyTimesText
            .split(whereSeparator: { separators.contains($0.unicodeScalars.first!) })
            .map { String($0) }
        
        var rawKeyTimes: [Double] = []
        for token in tokens {
            guard let value = Double(token) else {
                state.keyTimesError = "Key times must be numbers separated by commas or spaces."
                return .failure(())
            }
            rawKeyTimes.append(value)
        }
        
        // Normalize: clamp->round(2)->sort->unique
        let normalized = Array(
            Set(
                rawKeyTimes.map { min(max($0, 0), 100) }
                    .map { Double((($0 * 100).rounded()) / 100) }
            )
        ).sorted()
        
        if normalized.isEmpty {
            state.keyTimesError = "At least one key time is required."
            return .failure(())
        }
        
        // Validate clip window
        if clipStart + clipDuration > totalDuration {
            state.clipPercentError = "Clip end exceeds track length. Adjust clip start or percent."
            return .failure(())
        }
        
        let configuration = TrackConfiguration(
            totalDuration: totalDuration,
            clipStart: clipStart,
            clipDuration: clipDuration,
            keyTimePercentages: normalized
        )
        return .success(configuration)
    }
}


