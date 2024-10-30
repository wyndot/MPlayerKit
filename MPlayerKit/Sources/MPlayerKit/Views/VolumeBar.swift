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
                TrackBar(value: $volume, state: $trackState)
                    .frame(maxWidth: isShowingVolumeBar ? .infinity : 1)
                    .opacity(isShowingVolumeBar ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isShowingVolumeBar)
                    .transition(.opacity)
                Spacer()
            } else {
                Spacer()
                TrackBar(value: $volume, state: $trackState)
                    .frame(maxWidth: isShowingVolumeBar ? .infinity : 1)
                    .opacity(isShowingVolumeBar ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isShowingVolumeBar)
                    .transition(.opacity)
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
                    toggleVolumeBar(true)
                case (false, false):
                    toggleVolumeBar(true)
                case (false, true):
                    isMuted.toggle()
                    playerModel.player.isMuted = isMuted
                    toggleVolumeBar(false)
                default:
                    break
            }
            
            if isShowingVolumeBar {
                scheduleDismissal()
            }
        }, label: {
            image
        })
        .buttonStyle(.xsmallIcon)
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
        Task { @MainActor in
            await accumulateTimer.schedule(action: "dimiss", timeInterval: 5.0, perform: {
                DispatchQueue.main.async {
                    toggleVolumeBar(false)
                }
            })
        }
    }
    
    func toggleVolumeBar(_ visible: Bool) {
        self.isShowingVolumeBar = visible
    }
}
