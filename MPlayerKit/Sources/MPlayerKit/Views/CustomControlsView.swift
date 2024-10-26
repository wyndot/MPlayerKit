//
//  CustomControlsView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "SystemPlayerView")

struct CustomControlsView: View {
    @Environment(\.playerModel) private var playerModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var presentation: PlayerPresentation = .none
    @State private var playerState: PlayerState = .paused(reason: .userInitiated)
    @State private var trackingState: TrackState = .idle
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
            VStack {
                topbar
                Spacer()
                middlebar
                Spacer()
                VStack(alignment: .center, spacing: 0) {
                    playbackInfoBar
                    bottombar
                }
            }
            .padding(.top, safeAreaInsets.top)
            .padding(.bottom, safeAreaInsets.bottom)
            .padding(.horizontal, 40)
        }
        .onReceive(playerModel.$presentation, perform: { newValue in
            presentation = newValue
        })
        .onReceive(playerModel.$state, perform: { newValue in
            playerState = newValue
        })
    }
    
    var topbar: some View {
        HStack(alignment: .center, spacing: 0) {
            if case .fullscreen(_) = presentation {
                closeButton
            }
            Spacer()
            #if os(iOS)
            VolumeSlider()
            #endif
        }
        .frame(maxWidth: .infinity)
#if os(tvOS)
        .focusSection()
#endif
    }
    
    var middlebar: some View {
        HStack(alignment: .center, spacing: 20) {
            skipBackwardButton
            playPauseButton
            skipForwardButton
        }
        .frame(maxWidth: .infinity)
#if os(tvOS)
        .focusSection()
#endif
    }
    
    var bottombar: some View {
        HStack(alignment: .center, spacing: 0) {
            PlaybackTimeBar(trackingState: $trackingState)
        }
        .frame(maxWidth: .infinity)
#if os(tvOS)
        .focusSection()
#endif
    }
    
    var playbackInfoBar: some View {
        PlaybackPreviewView(trackingState: $trackingState)
#if os(iOS)
            .frame(maxWidth: .infinity, maxHeight: 100)
#elseif os(tvOS)
            .frame(maxWidth: .infinity, maxHeight: 200)
#endif
    }
    
    var closeButton: some View {
        Button(action: {
            playerModel.presentation = .none
        }, label: {
            Image(systemName: "xmark")
                .resizable()
        })
        .buttonStyle(.smallIcon)
    }
    
    var skipBackwardButton: some View {
        Button(action: {
            playerModel.skip(-10)
        }, label: {
            Image(systemName: "10.arrow.trianglehead.counterclockwise")
                .resizable()
        })
        .buttonStyle(.mediumIcon)
    }
    
    var skipForwardButton: some View {
        Button(action: {
            playerModel.skip(10)
        }, label: {
            Image(systemName: "10.arrow.trianglehead.clockwise")
                .resizable()
        })
        .buttonStyle(.mediumIcon)
    }
    
    var playPauseButton: some View {
        Button(action: {
            if case .playing = playerState {
                playerModel.pause()
            } else {
                playerModel.play()
            }
        }, label: {
            if case .playing = playerState{
                Image(systemName: "pause.circle")
                    .resizable()
            } else {
                Image(systemName: "play.circle")
                    .resizable()
            }
        })
        .buttonStyle(.largeIcon)
    }
}

#Preview {
    CustomControlsView()
        .edgesIgnoringSafeArea(.all)
}
