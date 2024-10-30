//
//  PlaybackTimeBar.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/25/24.
//
import SwiftUI
import AVFoundation

struct PlaybackTimeBar: View {
    @Environment(\.playerModel) private var playerModel
    @Binding var trackingState: TrackState
    @State private var progress: Double = 0
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            TrackBar(value: $progress, state: $trackingState)
            HStack {
                leadingTimescale
                Spacer()
                trailingTimescale
            }
        }
        .foregroundStyle(Color.accentColor)
        .onChange(of: trackingState, perform: { newValue in
            if case .ended(let progress) = newValue {
                guard let duration = playerModel.duration, let currentTime = playerModel.currentTime else { return }
                let newTimeInSeconds = duration.seconds * Double(progress)
                guard newTimeInSeconds > 10 else { return }
                let newTime = CMTime(seconds: newTimeInSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                guard abs(newTimeInSeconds - currentTime.seconds) > 10 else { return }
                playerModel.seek(newTime)
            }
        })
        .onReceive(playerModel.$currentTime.receive(on: DispatchQueue.main), perform: { newValue in
            guard let duration = playerModel.duration, let currentTime = playerModel.currentTime, case .playing = playerModel.state else { return }
            progress = currentTime.seconds / duration.seconds
        })
        .task {
            guard let duration = playerModel.duration, let currentTime = playerModel.currentTime else { return }
            progress = currentTime.seconds / duration.seconds
        }
    }
    
    var leadingTimescale: some View {
        Text(verbatim: "\(formatSecondsToHHMMSS(seconds))")
            .font(.caption)
    }
    
    var trailingTimescale: some View {
        Text(verbatim: "- \(formatSecondsToHHMMSS(leftSeconds))")
            .font(.caption)
    }
    
    private var seconds: Double {
        guard let duration = playerModel.duration else { return 0 }
        return switch trackingState {
            case .idle:
                progress * duration.seconds
            case .tracking(let value):
                value * duration.seconds
            case .ended(let value):
                value * duration.seconds
        }
    }
    
    private var leftSeconds: Double {
        guard let duration = playerModel.duration else { return 0 }
        return duration.seconds - seconds
    }
    
    private func formatSecondsToHHMMSS(_ seconds: Double) -> String {
#if os(iOS)
        guard seconds.isNormal else { return "00:00" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(seconds)) ?? "00:00"
#elseif os(tvOS)
        guard seconds.isNormal else { return "00:00:00" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(seconds)) ?? "00:00:00"
#endif
    }
}
