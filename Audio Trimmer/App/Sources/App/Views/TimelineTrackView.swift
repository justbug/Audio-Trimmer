import SwiftUI

struct TimelineTrackView: View {
    let clipRange: ClosedRange<Double>
    let markers: [Double]
    let progress: Double
    let capsuleHeight: CGFloat = 12
    let onMarkerTapped: ((Double) -> Void)?
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clipStart = width * clipRange.lowerBound
            let clipEnd = width * clipRange.upperBound
            let clipWidth = max(clipEnd - clipStart, 0)
            
            // Ensure clip doesn't extend beyond view bounds
            let adjustedClipStart = max(0, min(clipStart, width - clipWidth))
            let constrainedClipWidth = min(clipWidth, width - adjustedClipStart)
            
            let progressX = constrainedClipWidth * progress
            // Limit progressX to not exceed the constrained clip width
            let constrainedProgressX = min(progressX, constrainedClipWidth)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: capsuleHeight)
                
                Capsule()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: constrainedClipWidth, height: capsuleHeight)
                    .offset(x: adjustedClipStart)
                
                Capsule()
                    .fill(Color.yellow)
                    .frame(width: constrainedProgressX, height: capsuleHeight)
                    .offset(x: adjustedClipStart, y: 0)
                    .animation(.easeInOut(duration: 0.2), value: constrainedProgressX)
                
                ForEach(Array(markers.enumerated()), id: \.offset) { _, marker in
                    Circle()
                        .fill(Color.accentColor.opacity(0.5))
                        .frame(width: 15, height: 15)
                        .offset(x: width * marker, y: 0)
                        .onTapGesture {
                            onMarkerTapped?(marker)
                        }
                }
            }
            .clipped()
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start of clip (0% progress)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TimelineTrackView(
                clipRange: 0.04...0.12,
                markers: [0.25, 0.75],
                progress: 0,
                onMarkerTapped: nil
            )
            .frame(height: 44)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Middle of clip (50% progress)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TimelineTrackView(
                clipRange: 0.04...0.12,
                markers: [0.25, 0.75],
                progress: 0.5,
                onMarkerTapped: nil
            )
            .frame(height: 44)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("End of clip (100% progress)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TimelineTrackView(
                clipRange: 0.04...0.12,
                markers: [0.25, 0.75],
                progress: 1.0,
                onMarkerTapped: nil
            )
            .frame(height: 44)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Wide clip range (20%-80%)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TimelineTrackView(
                clipRange: 0.2...0.8,
                markers: [0.3, 0.5, 0.7],
                progress: 0.3,
                onMarkerTapped: nil
            )
            .frame(height: 44)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("No markers")
                .font(.caption)
                .foregroundStyle(.secondary)
            TimelineTrackView(
                clipRange: 0.1...0.4,
                markers: [],
                progress: 0.6,
                onMarkerTapped: nil
            )
            .frame(height: 44)
        }
    }
    .padding()
}

