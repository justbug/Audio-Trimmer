import ComposableArchitecture
import Foundation

struct ConfigurationLoader: Sendable {
    var load: @Sendable () async throws -> TrackConfiguration
}

extension ConfigurationLoader: DependencyKey {
    static let liveValue = ConfigurationLoader {
        // Default implementation throws an error - should be overridden in production
        TrackConfiguration(
            totalDuration: 60,
            clipStart: 0,
            clipDuration: 6,
            keyTimePercentages: [25, 75]
        )
    }
    
    static let testValue = ConfigurationLoader {
        TrackConfiguration(
            totalDuration: 120,
            clipStart: 5,
            clipDuration: 10,
            keyTimePercentages: [25, 75]
        )
    }
}

extension DependencyValues {
    var configurationLoader: ConfigurationLoader {
        get { self[ConfigurationLoader.self] }
        set { self[ConfigurationLoader.self] = newValue }
    }
}

enum ConfigurationLoadError: Error, LocalizedError {
    case notImplemented
    case loadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "ConfigurationLoader not implemented"
        case .loadFailed(let message):
            return message
        }
    }
}

