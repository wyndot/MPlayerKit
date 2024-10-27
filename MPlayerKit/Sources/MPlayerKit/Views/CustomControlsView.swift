//
//  CustomControlsView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI
import os
import AVFoundation

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "SystemPlayerView")

struct CustomControlsView: View {
    @Environment(\.playerModel) private var playerModel
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var presentation: PlayerPresentation = .none
    @State private var playerState: PlayerState = .paused(reason: .userInitiated)
    @State private var trackingState: TrackState = .idle
    @State private var subtitles: [AVMediaSelectionOption]? = nil
    @State private var audios: [AVMediaSelectionOption]? = nil
    @State private var subtitle: AVMediaSelectionOption? = nil
    @State private var audio: AVMediaSelectionOption? = nil
    @State private var rate: Float = 1.0
    
    var body: some View {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            content
                .onChange(of: playerModel.player.defaultRate, perform: { newRate in
                    rate = newRate
                })
        } else {
            content
                .onChange(of: playerModel.player.rate, perform: { newRate in
                    rate = newRate
                })
        }
    }
    
    var content: some View {
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
        .onReceive(playerModel.$subtitles, perform: { newValue in
            subtitles = newValue?.options
        })
        .onReceive(playerModel.$audios, perform: { newValue in
            audios = newValue?.options
        })
        .onReceive(playerModel.$subtitle, perform: { newValue in
            subtitle = newValue
        })
        .onReceive(playerModel.$audio, perform: { newValue in
            audio = newValue
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
        ZStack {
            PlaybackPreviewView(trackingState: $trackingState)
#if os(iOS)
                .frame(maxWidth: .infinity, maxHeight: 100)
#elseif os(tvOS)
                .frame(maxWidth: .infinity, maxHeight: 200)
#endif
            HStack {
                Spacer()
                Menu {
                    playRatesMenu
                    if let options = subtitles {
                        subtitlesMenu(options: options)
                    }
                    if let options = audios {
                        audioMenu(options: options)
                    }
                } label: {
                    Label("", systemImage: "ellipsis.circle")
                }
            }
            
        }
    }
    
    var playRatesMenu: some View {
        Menu(content: {
            ForEach([0.5, 1.0, 1.5, 2.0, 2.5], id: \.self) { rate in
                Button(action: {
                    var wasPlaying = false
                    if case .playing = playerModel.state {
                        wasPlaying = true
                        playerModel.player.pause()
                    }
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
                        playerModel.player.defaultRate = Float(rate)
                    } else {
                        playerModel.player.rate = Float(rate)
                    }
                    
                    if wasPlaying {
                        playerModel.player.play()
                    }
                }, label: {
                    Label{
                        Text("\(rate as NSNumber, formatter: rateFormatter)").font(.subheadline)
                    } icon: {
                        if Float(rate) == self.rate {
                            Image(systemName: "checkmark")
                                .imageScale(.small)
                                .padding(.trailing, 10)
                        }
                    }
                })
            }
        }, label: {
            Label("Rate", systemImage: "play.circle.fill")
        })
    }
    
    func subtitlesMenu(options: [AVMediaSelectionOption]) -> some View {
        Menu(content: {
            ForEach(options, id:\.self) { subtitle in
                Button(action: {
                    playerModel.selectSubtitles(subtitle)
                }, label: {
                    Label {
                        Text(subtitle.displayName).font(.subheadline)
                    } icon: {
                        if self.subtitle == subtitle {
                            Image(systemName: "checkmark")
                                .imageScale(.small)
                                .padding(.trailing, 10)
                        }
                    }
                })
            }
        }, label: {
            Label("Subtitle", systemImage: "tv.circle.fill")
        })
    }
    
    func audioMenu(options: [AVMediaSelectionOption]) -> some View {
        Menu(content: {
            ForEach(options, id:\.self) { audio in
                Button(action: {
                    playerModel.selectAudio(audio)
                }, label: {
                    Label {
                        Text(audio.displayName).font(.subheadline)
                    } icon: {
                        if self.audio == audio {
                            Image(systemName: "checkmark")
                                .imageScale(.small)
                                .padding(.trailing, 10)
                        }
                    }
                })
            }
        }, label: {
            Label("Audio", systemImage: "tv.circle.fill")
        })
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
            
    var rateFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }
}

#Preview {
    CustomControlsView()
        .edgesIgnoringSafeArea(.all)
}
