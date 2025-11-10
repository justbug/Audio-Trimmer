import Foundation

extension TimeInterval {
    func formattedTime() -> String {
        guard isFinite else {
            return "--:--"
        }
        let intSeconds = max(Int(rounded()), 0)
        let minutes = intSeconds / 60
        let remainder = intSeconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    func formattedSeconds() -> String {
        String(format: "%.1fs", self)
    }
}

