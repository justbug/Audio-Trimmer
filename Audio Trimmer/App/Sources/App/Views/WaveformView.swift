import SwiftUI

struct WaveformView: View {
    let totalDuration: TimeInterval
    let clipStart: TimeInterval
    let clipDuration: TimeInterval
    private let itemSize: CGFloat = 60
    private let contentInsetDivider: CGFloat = 3
    
    private var imageCount: Int {
        let duration = max(totalDuration, 60)
        return Int(duration / 6)
    }
    
    private var borderWidth: CGFloat {
        2 * itemSize
    }
    
    private func requiredContentWidth(width: CGFloat) -> CGFloat {
        let calculatedWidth = width + (clipStart / 6) * itemSize + borderWidth
        let minimumWidth = CGFloat(imageCount) * itemSize
        return max(calculatedWidth, minimumWidth)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let borderX = width / contentInsetDivider + (clipStart / 6) * itemSize
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
        let contentWidth = requiredContentWidth(width: width)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<imageCount, id: \.self) { _ in
                    waveformImageView(itemSize: itemSize)
                }
            }
            .frame(width: contentWidth)
        }
        .frame(width: width, height: itemSize)
        .contentMargins(.horizontal, width / contentInsetDivider, for: .scrollContent)
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
                totalDuration: 40,
                clipStart: 0,
                clipDuration: 6
            )
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Medium clip (12s / 60s)")
                .font(.caption)
                .foregroundStyle(.secondary)
            WaveformView(
                totalDuration: 60,
                clipStart: 0,
                clipDuration: 12
            )
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Long clip (30s / 120s)")
                .font(.caption)
                .foregroundStyle(.secondary)
            WaveformView(
                totalDuration: 120,
                clipStart: 0,
                clipDuration: 30
            )
        }
    }
    .padding()
}

