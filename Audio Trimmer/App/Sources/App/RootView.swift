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
        var path = StackState<Path.State>()
    }
    
    enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case trackSettings(TrackSettingsFeature.Action)
    }
    
    @Reducer
    struct Path {
        enum State: Equatable {
            case audioTrimmer(AudioTrimmerFeature.State)
        }
        enum Action: Equatable {
            case audioTrimmer(AudioTrimmerFeature.Action)
        }
        var body: some ReducerOf<Self> {
            Scope(state: \.audioTrimmer, action: \.audioTrimmer) {
                AudioTrimmerFeature()
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.trackSettings, action: \.trackSettings) {
            TrackSettingsFeature()
        }
        Reduce { state, action in
            switch action {
            case .path:
                return .none
            case .trackSettings(.delegate(.confirmed(let configuration))):
                state.path.append(.audioTrimmer(.init(configuration: configuration)))
                if let id = state.path.ids.last {
                    return .send(.path(.element(id: id, action: .audioTrimmer(.onAppear))))
                }
                return .none
            case .trackSettings:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
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
        NavigationStackStore(
            store.scope(state: \.path, action: \.path)
        ) {
            TrackSettingsView(
                store: store.scope(state: \.trackSettings, action: \.trackSettings)
            )
        } destination: { state in
            switch state {
            case .audioTrimmer:
                CaseLet(
                    /AppRootFeature.Path.State.audioTrimmer,
                    action: AppRootFeature.Path.Action.audioTrimmer,
                    then: { store in
                        AudioTrimmerView(store: store)
                    }
                )
            }
        }
    }
}

#Preview {
    RootView()
}
