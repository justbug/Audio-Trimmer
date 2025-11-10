import SwiftUI
import ComposableArchitecture

public struct AppRootView: View {
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
    AppRootView()
}

