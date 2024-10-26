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
        TrackBar(value: $progress, state: $trackingState)
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
            .onReceive(playerModel.$currentTime, perform: { newValue in
                guard let duration = playerModel.duration, let currentTime = playerModel.currentTime, case .playing = playerModel.state else { return }
                progress = currentTime.seconds / duration.seconds
            })
            .task {
                guard let duration = playerModel.duration, let currentTime = playerModel.currentTime else { return }
                progress = currentTime.seconds / duration.seconds
            }
    }
}
