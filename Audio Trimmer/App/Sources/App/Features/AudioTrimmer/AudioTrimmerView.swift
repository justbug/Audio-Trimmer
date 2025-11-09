import SwiftUI
import ComposableArchitecture

struct AudioTrimmerView: View {
    @Bindable var store: StoreOf<AudioTrimmerFeature>
    
    init(store: StoreOf<AudioTrimmerFeature>) {
        self.store = store
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                timelineSection
                waveformSection
                clipDetailsSection
                markersSection
                controlsSection
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .task {
            await store.send(.loadConfiguration).finish()
        }
    }
}

// MARK: - Subviews
private extension AudioTrimmerView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Audio Trim")
                .font(.title)
                .bold()
            DetailRow(
                label: "Track length",
                value: store.configuration.totalDuration.formattedTime()
            )
        }
    }
    
    var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Clip Playback")
                    .font(.headline)
                
                HStack(spacing: 0) {
                    Text(timelineSubtitlePrefix)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(progressPercentText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .animation(.easeInOut(duration: 0.3), value: store.timeline.currentProgressPercent)
            }
            
            TimelineTrackView(
                clipRange: store.timeline.clipRangePercent,
                markers: store.timeline.markerPositionsPercent,
                progress: store.timeline.clipProgressPercent,
            )
            .frame(height: 44)
        }
    }
    
    var clipDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clip Details")
                .font(.headline)
            DetailRow(
                label: "Clip window",
                value: "\(store.timeline.clipRangeSeconds.lowerBound.formattedTime()) – \(store.timeline.clipRangeSeconds.upperBound.formattedTime())"
            )
            DetailRow(
                label: "Clip duration",
                value: store.configuration.clipDuration.formattedSeconds()
            )
            DetailRow(
                label: "Clip position",
                value: "\(store.timeline.clipRangePercent.lowerBound.formattedPercentWithDecimal()) – \(store.timeline.clipRangePercent.upperBound.formattedPercentWithDecimal()) of track"
            )
        }
    }
    
    var markersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Times")
                .font(.headline)
            
            if store.configuration.keyTimePercentages.isEmpty {
                Text("No key Times configured.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(store.configuration.keyTimePercentages.enumerated()), id: \.offset) { index, percentage in
                        DetailRow(
                            label: "Marker \(index + 1)",
                            value: "\(String(format: "%.0f%%", percentage)) · \(((percentage / 100).clamped() * store.configuration.totalDuration).formattedTime())"
                        )
                    }
                }
            }
        }
    }
    
    var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playback Controls")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button {
                    playButtonAction()
                } label: {
                    Label(playButtonLabel, systemImage: playButtonIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    store.send(.resetTapped)
                } label: {
                    Label("Reset", systemImage: "gobackward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    var waveformSection: some View {
        WaveformView(
            totalDuration: store.configuration.totalDuration,
            clipDuration: store.configuration.clipDuration
        )
    }
}

// MARK: - Helpers
private extension AudioTrimmerView {
    var playButtonLabel: String {
        store.playbackState.status == .playing ? "Pause" : "Play"
    }
    
    var playButtonIcon: String {
        store.playbackState.status == .playing ? "pause.fill" : "play.fill"
    }
    
    var timelineSubtitlePrefix: String {
        let currentPosition = store.playbackState.currentPosition.formattedTime()
        let clipEnd = store.configuration.clipEnd.formattedTime()
        return "\(currentPosition) → \(clipEnd) · "
    }
    
    var progressPercentText: String {
        store.timeline.currentProgressPercent.formattedPercentWithDecimal()
    }
    
    func playButtonAction() {
        if store.playbackState.status == .playing {
            store.send(.pauseTapped)
        } else {
            store.send(.playTapped)
        }
    }
    
    var clipCoveragePercent: String {
        guard store.configuration.totalDuration > 0 else {
            return "0%"
        }
        
        let coverage = (store.configuration.clipDuration / store.configuration.totalDuration).clamped()
        return coverage.formattedPercent()
    }
}

// MARK: - Supporting Views

private struct WaveformView: View {
    let totalDuration: TimeInterval
    let clipDuration: TimeInterval
    private let itemSize: CGFloat = 55
    private let contentInsetDivider: CGFloat = 3
    
    private var imageCount: Int {
        max(1, Int(ceil(totalDuration / 6)))
    }
    
    private var borderWidth: CGFloat {
        CGFloat(max(1, Int(ceil(clipDuration / 6)))) * itemSize
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                waveformScrollView(width: width)
                
                TimelineBorderView()
                    .frame(width: borderWidth, height: itemSize)
            }
            .frame(width: width, height: itemSize)
        }
        .frame(height: itemSize)
    }
    
    private func waveformScrollView(width: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<imageCount, id: \.self) { _ in
                    waveformImageView(itemSize: itemSize)
                }
            }
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

private struct TimelineTrackView: View {
    let clipRange: ClosedRange<Double>
    let markers: [Double]
    let progress: Double
    let capsuleHeight: CGFloat = 12
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clipStart = width * clipRange.lowerBound
            let clipEnd = width * clipRange.upperBound
            let clipWidth = max(clipEnd - clipStart, 0)
            let progressX = clipWidth * progress
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: capsuleHeight)
                
                Capsule()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: clipWidth, height: capsuleHeight)
                    .offset(x: clipStart)
                
                Capsule()
                    .fill(Color.yellow)
                    .frame(width: progressX, height: capsuleHeight)
                    .offset(x: clipStart, y: 0)
                    .animation(.easeInOut(duration: 0.2), value: progressX)
                
                ForEach(Array(markers.enumerated()), id: \.offset) { _, marker in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 20, height: 20)
                        .offset(x: width * marker, y: 0)
                }
            }
        }
    }
}

#Preview {
    AudioTrimmerView(
        store: Store(
            initialState: AudioTrimmerFeature.State(
                configuration: TrackConfiguration(
                    totalDuration: 120,
                    clipStart: 6,
                    clipDuration: 6,
                    keyTimePercentages: [25, 75]
                ),
                playbackState: .idle(configuration: TrackConfiguration(
                    totalDuration: 120,
                    clipStart: 6,
                    clipDuration: 6,
                    keyTimePercentages: [25, 75]
                )),
                timeline: AudioTrimmerFeature.TimelineSnapshot(
                    clipRangeSeconds: 5...15,
                    clipRangePercent: 0.04...0.12,
                    markerPositionsPercent: [0.25, 0.75],
                    currentProgressPercent: 0,
                    clipProgressPercent: 0
                )
            )
        ) {
            AudioTrimmerFeature()
        }
    )
}
