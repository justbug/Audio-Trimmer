//
//  RootView.swift
//  Audio Trimmer
//
//  Created by 陳琮諺 on 2025/11/5.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AppRootFeature {
    @ObservableState
    struct State: Equatable {
        var trackSettings = TrackSettingsFeature.State()
        var audioTrimmer: AudioTrimmerFeature.State?
    }
    
    enum Action: Equatable {
        case trackSettings(TrackSettingsFeature.Action)
        case audioTrimmer(AudioTrimmerFeature.Action)
        case resetToSettings
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.trackSettings, action: \.trackSettings) {
            TrackSettingsFeature()
        }
        Reduce { state, action in
            switch action {
            case .trackSettings(.delegate(.confirmed(let configuration))):
                state.audioTrimmer = AudioTrimmerFeature.State(configuration: configuration)
                return .none
            case .trackSettings:
                return .none
            case .audioTrimmer:
                return .none
            case .resetToSettings:
                state.audioTrimmer = nil
                return .none
            }
        }
        .ifLet(\.audioTrimmer, action: \.audioTrimmer) {
            AudioTrimmerFeature()
        }
    }
}

public struct RootView: View {
    let store: StoreOf<AppRootFeature>
    
    public init() {
        self.store = Store(
            initialState: AppRootFeature.State()
        ) {
            AppRootFeature()
        }
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { _ in
            if let trimmerStore = store.scope(state: \.audioTrimmer, action: \.audioTrimmer) {
                AudioTrimmerView(store: trimmerStore)
            } else {
                TrackSettingsView(
                    store: store.scope(state: \.trackSettings, action: \.trackSettings)
                )
            }
        }
    }
}

#Preview {
    RootView()
}
