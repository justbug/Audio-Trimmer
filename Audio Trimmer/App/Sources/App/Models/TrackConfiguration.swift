import Foundation

struct TrackConfiguration: Equatable {
    /// The total duration of the track in seconds. 
    let totalDuration: TimeInterval
    /// The start time of the clip in seconds.
    let clipStart: TimeInterval
    /// The duration of the clip in seconds.
    let clipDuration: TimeInterval
    /// The key time percentages of the clip.
    let keyTimePercentages: [Double]
}

extension TrackConfiguration {
    var clipEnd: TimeInterval {
        clipStart + clipDuration
    }

    var clipRangeSeconds: ClosedRange<TimeInterval> {
        let end = min(clipEnd, totalDuration)
        return clipStart...max(clipStart, end)
    }

    var normalizedClipRangePercent: ClosedRange<Double> {
        guard totalDuration > 0 else {
            return 0...0
        }

        let total = totalDuration
        let start = (clipRangeSeconds.lowerBound / total).clamped()
        let end = (clipRangeSeconds.upperBound / total).clamped()

        return start...end
    }

    var normalizedKeyTimesPercent: [Double] {
        keyTimePercentages.map { ($0 / 100).clamped() }
    }
}
