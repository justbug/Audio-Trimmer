//
//  RootView.swift
//  Audio Trimmer
//
//  Created by 陳琮諺 on 2025/11/5.
//

import SwiftUI
import ComposableArchitecture

public struct RootView: View {
    let store: StoreOf<AudioTrimmerFeature>

    public init() {
        self.store = Store(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        }
    }

    init(store: StoreOf<AudioTrimmerFeature>) {
        self.store = store
    }
    
    public var body: some View {
        AudioTrimmerView(store: store)
    }
}

#Preview {
    RootView(
        store: Store(
            initialState: AudioTrimmerFeature.State()
        ) {
            AudioTrimmerFeature()
        }
    )
}
