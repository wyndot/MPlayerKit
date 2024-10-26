//
//  VolumeSlider.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/25/24.
//
import SwiftUI

struct VolumeSlider: View {
    @Environment(\.playerModel) private var playerModel
    @State private var isMuted: Bool = false
    @State private var volume: Double = 0.0
    @State private var isShowingVolumeBar: Bool = false
    @State private var trackState: TrackState = .idle
    @State private var accumulateTimer: AccumulateTimer = .init()
    let alignment: HorizontalAlignment = .leading
    let spacing: CGFloat = 8
    
    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            if alignment == .leading {
                volumeButton
                if isShowingVolumeBar {
                    TrackBar(value: $volume, state: $trackState)
                        .animation(.easeInOut, value: isShowingVolumeBar)
                        .transition(.opacity)
                }
                Spacer()
            } else {
                Spacer()
                if isShowingVolumeBar {
                    TrackBar(value: $volume, state: $trackState)
                        .animation(.easeInOut, value: isShowingVolumeBar)
                        .transition(.opacity)
                }
                volumeButton
            }
        }
        .onChange(of: trackState, perform: { newValue in
            switch newValue {
                case .ended(value: let value):
                    volume = Double(value)
                    playerModel.player.volume = Float(value)
                case .tracking(value: let value):
                    volume = Double(value)
                    playerModel.player.volume = Float(value)
                default: break
            }
            scheduleDismissal()
        })
        .task {
            volume = Double(playerModel.player.volume)
        }
    }
    
    var volumeButton: some View {
        Button(action: {
            switch (isMuted, isShowingVolumeBar) {
                case (true, false):
                    isMuted.toggle()
                    playerModel.player.isMuted = isMuted
                    isShowingVolumeBar = true
                case (false, false):
                    isShowingVolumeBar = true
                case (false, true):
                    isMuted.toggle()
                    playerModel.player.isMuted = isMuted
                    isShowingVolumeBar = false
                default:
                    break
            }
            
            if isShowingVolumeBar {
                scheduleDismissal()
            }
        }, label: {
            image
        })
        .buttonStyle(.smallIcon)
    }
    
    var image: some View {
        if isMuted {
            return Image(systemName: "speaker.slash.fill").resizable()
        }
        switch volume {
            case 0.0..<0.33: return Image(systemName: "speaker.wave.1.fill").resizable()
            case 0.33..<0.66: return Image(systemName: "speaker.wave.2.fill").resizable()
            case 0.66...1.0: return Image(systemName: "speaker.wave.3.fill").resizable()
            default: return Image(systemName: "speaker.fill").resizable()
        }
    }
    
    func scheduleDismissal() {
        Task {
            await accumulateTimer.schedule(action: "dimiss", timeInterval: 5.0, perform: {
                Task { @MainActor in
                    self.isShowingVolumeBar = false
                }
            })
        }
    }
}
