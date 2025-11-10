import SwiftUI
import ComposableArchitecture

struct WaveformView: View {
    @Bindable var store: StoreOf<WaveformFeature>
    private let itemSize: CGFloat = 60
    private let itemsCount: Int = 10
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
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                let width = geometry.size.width
                waveformScrollView(width)
                
                TimelineBorderView()
                    .frame(width: itemSize, height: itemSize)
                    .offset(x: width / 2 - borderWidth / 2, y: 0)
            }
        }
        .frame(height: itemSize)
    }
    
    private func waveformScrollView(_ width: CGFloat) -> some View {
        return HStack(spacing: 0) {
            ForEach(0..<itemsCount, id: \.self) { index in
                waveformImageView(itemSize: itemSize)
                    .id(index)
            }
        }
        .padding(.horizontal, width / 2 - borderWidth / 2)
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
