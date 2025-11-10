import SwiftUI
import ComposableArchitecture

struct WaveformView: View {
    @Bindable var store: StoreOf<WaveformFeature>
    
    init(store: StoreOf<WaveformFeature>) {
        self.store = store
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                let width = geometry.size.width
                waveformScrollView(width)
                
                TimelineBorderView(progressPercent: store.clipProgressPercent)
                    .frame(width: store.viewConfiguration.itemSize, height: store.viewConfiguration.itemSize)
                    .offset(x: width / 2 - store.viewConfiguration.borderWidth / 2, y: 0)
            }
        }
        .frame(height: store.viewConfiguration.itemSize)
    }
    
    private func waveformScrollView(_ width: CGFloat) -> some View {
        return HStack(spacing: 0) {
            ForEach(0..<store.viewConfiguration.itemsCount, id: \.self) { index in
                waveformImageView(itemSize: store.viewConfiguration.itemSize)
                    .id(index)
            }
        }
        .padding(.horizontal, width / 2 - store.viewConfiguration.borderWidth / 2)
        .frame(height: store.viewConfiguration.itemSize)
        .offset(x: store.scrollOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !store.isDragging {
                        store.send(.dragStarted)
                    }
                    store.send(.dragChanged(translation: value.translation.width))
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
        let progressPercent: Double
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.yellow.opacity(0.5))
                        .frame(width: geometry.size.width * progressPercent.clamped(0, 1))
                    
                    // Stroke border
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.blue, lineWidth: 4)
                }
            }
        }
    }
}
