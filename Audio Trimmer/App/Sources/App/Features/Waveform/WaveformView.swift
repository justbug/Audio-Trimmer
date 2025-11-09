import SwiftUI
import ComposableArchitecture

struct WaveformView: View {
    @Bindable var store: StoreOf<WaveformFeature>
    private let itemSize: CGFloat = 60
    private let contentInsetDivider: CGFloat = 3
    
    init(store: StoreOf<WaveformFeature>) {
        self.store = store
    }
    
    private var imageCount: Int {
        store.imageCount
    }
    
    private var borderWidth: CGFloat {
        2 * itemSize
    }
        
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let borderX = width / contentInsetDivider
            ZStack(alignment: .leading) {
                waveformScrollView(width: width)
                
                TimelineBorderView()
                    .frame(width: borderWidth, height: itemSize)
                    .offset(x: borderX)
            }
            .frame(width: width, height: itemSize)
        }
        .frame(height: itemSize)
    }
    
    private func waveformScrollView(width: CGFloat) -> some View {
        let contentWidth = CGFloat(imageCount) * itemSize
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<imageCount, id: \.self) { index in
                        waveformImageView(itemSize: itemSize)
                            .id(index)
                    }
                }
                .frame(width: contentWidth)
            }
            .frame(width: width, height: itemSize)
            .contentMargins(.horizontal, width / contentInsetDivider, for: .scrollContent)
            .onChange(of: store.scrollTargetIndex) { _, newIndex in
                if let targetIndex = newIndex, targetIndex >= 0 && targetIndex < imageCount {
                    withAnimation {
                        proxy.scrollTo(targetIndex, anchor: .leading)
                    }
                }
            }
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
            Text("Clip at 6s (should scroll 1 item)")
                .font(.caption)
                .foregroundStyle(.secondary)
            WaveformView(
                store: Store(
                    initialState: WaveformFeature.State(
                        totalDuration: 60,
                        clipStart: 6,
                        clipDuration: 12
                    )
                ) {
                    WaveformFeature()
                }
            )
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

