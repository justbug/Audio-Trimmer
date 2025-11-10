import ComposableArchitecture
import Foundation

@Reducer
struct AudioTrimmerFeature {
    @ObservableState
    struct State: Equatable {
        var configuration: TrackConfiguration
        var playbackState: PlaybackState
        var timeline: TimelineSnapshot
        var waveform: WaveformFeature.State

        init(
            configuration: TrackConfiguration? = nil,
            playbackState: PlaybackState = .idle,
            timeline: TimelineSnapshot = .zero
        ) {
            let config = configuration ?? State.placeholderConfiguration
            self.configuration = config
            self.playbackState = playbackState
            self.timeline = timeline
            self.waveform = WaveformFeature.State(
                totalDuration: config.totalDuration,
                clipStart: config.clipStart,
                clipDuration: config.clipDuration
            )
        }
        
        static let placeholderConfiguration = TrackConfiguration(
            totalDuration: 0,
            clipStart: 0,
            clipDuration: 0,
            keyTimePercentages: []
        )
    }

    enum Action: Equatable {
        case playTapped
        case pauseTapped
        case resetTapped
        case tick
        case loadConfiguration
        case configurationLoaded(TrackConfiguration)
        case loadConfigurationFailed(String)
        case waveform(WaveformFeature.Action)
    }

    struct PlaybackState: Equatable {
        enum Status: Equatable {
            case idle
            case playing
            case paused
            case finished
        }

        var status: Status
        var currentPosition: TimeInterval
        var remainingDuration: TimeInterval

        static let idle = PlaybackState(status: .idle, currentPosition: 0, remainingDuration: 0)
        
        static func idle(configuration: TrackConfiguration) -> Self {
            .init(status: .idle, currentPosition: configuration.clipStart, remainingDuration: configuration.clipDuration)
        }

        static func playing(configuration: TrackConfiguration) -> Self {
            .init(status: .playing, currentPosition: configuration.clipStart, remainingDuration: configuration.clipDuration)
        }
    }

    struct TimelineSnapshot: Equatable {
        let clipRangeSeconds: ClosedRange<TimeInterval>
        let clipRangePercent: ClosedRange<Double>
        let markerPositionsPercent: [Double]
        let currentProgressPercent: Double
        let clipProgressPercent: Double
        
        init(
            clipRangeSeconds: ClosedRange<TimeInterval>,
            clipRangePercent: ClosedRange<Double>,
            markerPositionsPercent: [Double],
            currentProgressPercent: Double,
            clipProgressPercent: Double
        ) {
            self.clipRangeSeconds = clipRangeSeconds
            self.clipRangePercent = clipRangePercent
            self.markerPositionsPercent = markerPositionsPercent
            self.currentProgressPercent = currentProgressPercent
            self.clipProgressPercent = clipProgressPercent
        }
        
        init(configuration: TrackConfiguration, playbackProgressPercent: Double, clipProgressPercent: Double) {
            self.init(
                clipRangeSeconds: configuration.clipRangeSeconds,
                clipRangePercent: configuration.normalizedClipRangePercent,
                markerPositionsPercent: configuration.normalizedKeyTimesPercent,
                currentProgressPercent: playbackProgressPercent,
                clipProgressPercent: clipProgressPercent
            )
        }
        
        static let zero: TimelineSnapshot = {
            TimelineSnapshot(
                clipRangeSeconds: 0...0,
                clipRangePercent: 0...0,
                markerPositionsPercent: [],
                currentProgressPercent: 0,
                clipProgressPercent: 0
            )
        }()
    }

    enum TimerID: Hashable {
        case playback
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.configurationLoader) var configurationLoader
    static let minimumClipDuration: TimeInterval = 1

    var body: some ReducerOf<Self> {
        Scope(state: \.waveform, action: \.waveform) {
            WaveformFeature()
        }
        Reduce { (state, action) -> Effect<Action> in
            switch action {
            case .waveform:
                return .none
            case .playTapped:
                guard state.playbackState.status != PlaybackState.Status.playing else {
                    return .none
                }
                if state.playbackState.status == PlaybackState.Status.finished {
                    state.playbackState = .playing(configuration: state.configuration)
                } else {
                    // For idle or paused, start playing from current position
                    state.playbackState.status = .playing
                }
                updateDerivedState(&state)
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: TimerID.playback, cancelInFlight: true)
            case .tick:
                guard state.playbackState.status == PlaybackState.Status.playing else {
                    return .none
                }

                let remainingDuration = max(state.playbackState.remainingDuration - 1, 0)
                let nextPosition = min(state.playbackState.currentPosition + 1, state.configuration.clipEnd)

                state.playbackState.currentPosition = nextPosition
                state.playbackState.remainingDuration = remainingDuration

                if nextPosition >= state.configuration.clipEnd {
                    state.playbackState.status = PlaybackState.Status.finished
                    updateDerivedState(&state)
                    return .cancel(id: TimerID.playback)
                }

                updateDerivedState(&state)
                return .none

            case .pauseTapped:
                guard state.playbackState.status == PlaybackState.Status.playing else {
                    return .none
                }
                state.playbackState.status = PlaybackState.Status.paused
                updateDerivedState(&state)
                return .cancel(id: TimerID.playback)
            
            case .resetTapped:
                state.playbackState = .idle(configuration: state.configuration)
                updateDerivedState(&state)
                return .cancel(id: TimerID.playback)

            case .loadConfiguration:
                let loader = self.configurationLoader
                return .run { send in
                    do {
                        let configuration = try await loader.load()
                        await send(.configurationLoaded(configuration))
                    } catch {
                        await send(.loadConfigurationFailed(error.localizedDescription))
                    }
                }
            case .configurationLoaded(let configuration):
                state.configuration = configuration
                state.playbackState = .idle(configuration: configuration)
                // Update waveform state with new configuration
                state.waveform = WaveformFeature.State(
                    totalDuration: configuration.totalDuration,
                    clipStart: configuration.clipStart,
                    clipDuration: configuration.clipDuration
                )
                updateDerivedState(&state)
                return .send(.waveform(.updateScrollOffsetFromClipStart))
            case .loadConfigurationFailed(let error):
                print("Error loading configuration: \(error)")
                return .none
            }
        }
    }

    /// Rebuilds the timeline snapshot whenever configuration or playback changes.
    private func updateDerivedState(
        _ state: inout State
    ) {
        let configuration = state.configuration
        let playbackProgressPercent: Double = {
            guard configuration.totalDuration > 0 else {
                return 0
            }
            return Double(state.playbackState.currentPosition / configuration.totalDuration).clamped()
        }()
        let clipProgressPercent: Double = {
            guard configuration.totalDuration > 0 else {
                return 0
            }
            let elapsed = state.playbackState.currentPosition - configuration.clipStart
            return Double(elapsed / configuration.clipDuration).clamped()
        }()
        state.timeline = .init(
            configuration: state.configuration,
            playbackProgressPercent: playbackProgressPercent,
            clipProgressPercent: clipProgressPercent
        )
    }
}
