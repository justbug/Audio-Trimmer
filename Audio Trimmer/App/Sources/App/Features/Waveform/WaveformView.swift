import SwiftUI
import ComposableArchitecture

struct WaveformView: View {
    @Bindable var store: StoreOf<WaveformFeature>
    private let itemSize: CGFloat = 60
    private let itemsCount: Int = 10
    private let itemsPadding: CGFloat = 16
    private var borderWidth: CGFloat {
        itemSize
    }
    
    private var waveformItemsWidth: CGFloat {
        CGFloat(itemsCount) * itemSize
    }
    
    init(store: StoreOf<WaveformFeature>) {
        self.store = store
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !store.text.isEmpty {
                Text(store.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    waveformScrollView()
                    
                    TimelineBorderView()
                        .frame(width: itemSize, height: itemSize)
                        .offset(x: itemsPadding, y: 0)
                }
            }
            .frame(height: itemSize)
        }
    }
    
    private func waveformScrollView() -> some View {
        return HStack(spacing: 0) {
            ForEach(0..<itemsCount, id: \.self) { index in
                waveformImageView(itemSize: itemSize)
                    .id(index)
            }
        }
        .padding(.horizontal, itemsPadding)
        .frame(height: itemSize)
        .offset(x: store.scrollOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !store.isDragging {
                        store.send(.dragStarted)
                    }
                    store.send(.dragChanged(translation: value.translation.width, maxOffset: waveformItemsWidth - borderWidth))
                }
                .onEnded { _ in
                    store.send(.dragEnded)
                }
        )
        .onAppear {
            store.send(.syncDragStartOffset)
        }
        .onChange(of: store.scrollOffset) { _, _ in
            store.send(.syncDragStartOffset)
        }
    }
    
    private func waveformImageView(itemSize: CGFloat) -> some View {
        Image(systemName: "waveform")
            .resizable()
            .scaledToFit()
            .frame(width: itemSize, height: itemSize)
            .foregroundStyle(.secondary)
    }
    
    private struct TimelineBorderView: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.blue, lineWidth: 4)
                .background(.clear)
        }
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var scrollStore = Store(
            initialState: WaveformFeature.State(
                totalDuration: 60,
                clipStart: 6,
                clipDuration: 12
            )
        ) {
            WaveformFeature()
        }
        
        var body: some View {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Short clip (6s / 40)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    WaveformView(
                        store: Store(
                            initialState: WaveformFeature.State(
                                totalDuration: 40,
                                clipStart: 0,
                                clipDuration: 6
                            )
                        ) {
                            WaveformFeature()
                        }
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Clip at 6s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    WaveformView(store: scrollStore)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medium clip (12s / 60s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    WaveformView(
                        store: Store(
                            initialState: WaveformFeature.State(
                                totalDuration: 60,
                                clipStart: 0,
                                clipDuration: 12
                            )
                        ) {
                            WaveformFeature()
                        }
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Long clip (30s / 120s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    WaveformView(
                        store: Store(
                            initialState: WaveformFeature.State(
                                totalDuration: 120,
                                clipStart: 0,
                                clipDuration: 30
                            )
                        ) {
                            WaveformFeature()
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    return PreviewContainer()
}

