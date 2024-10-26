//
//  VolumeSlider.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/25/24.
//
import SwiftUI

struct VolumeSlider: View {
    @Environment(\.playerModel) private var playerModel
    @State private var volume: Double = 0.0
    @State private var trackState: TrackState = .idle

    var body: some View {
        TrackBar(value: $volume, state: $trackState)
        .onChange(of: trackState, perform: { newValue in
            switch newValue {
                case .ended(value: let value):
                    playerModel.player.volume = Float(value)
                case .tracking(value: let value):
                    playerModel.player.volume = Float(value)
                default: break
            }
        })
        .task {
            volume = Double(playerModel.player.volume)
        }
    }
}
