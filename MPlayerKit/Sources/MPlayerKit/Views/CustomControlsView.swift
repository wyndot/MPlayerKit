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
#if os(tvOS)
    enum ControlsFocusState: Hashable {
        case close
        case play
        case track
        case skipForward
        case skipBackward
        case options
    }
    @Namespace private var controlsNamespace
    @FocusState private var focusState: ControlsFocusState?
#endif
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
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                topbar
                    .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                        d[.top] + geometry.size.height / 2.0 - safeAreaInsets.top
                    })
                
                middlebar
                    .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                        d[VerticalAlignment.center]
                    })
                
                VStack(alignment: .center, spacing: 0) {
                    playbackInfoBar
                    bottombar
                }
                .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                    d[.bottom] - geometry.size.height / 2.0 + safeAreaInsets.bottom
                })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
#if os(tvOS)
        .focusScope(controlsNamespace)
        .onAppear {
            focusState = .play
        }
#endif
        .onReceive(playerModel.$presentation.receive(on: DispatchQueue.main), perform: { newValue in
            presentation = newValue
        })
        .onReceive(playerModel.$state.receive(on: DispatchQueue.main), perform: { newValue in
            playerState = newValue
        })
        .onReceive(playerModel.$subtitles.receive(on: DispatchQueue.main), perform: { newValue in
            subtitles = newValue?.options
        })
        .onReceive(playerModel.$audios.receive(on: DispatchQueue.main), perform: { newValue in
            audios = newValue?.options
        })
        .onReceive(playerModel.$subtitle.receive(on: DispatchQueue.main), perform: { newValue in
            subtitle = newValue
        })
        .onReceive(playerModel.$audio.receive(on: DispatchQueue.main), perform: { newValue in
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
        ZStack(alignment: .bottom) {
            PlaybackPreviewView(trackingState: $trackingState)
#if os(iOS)
                .frame(maxWidth: .infinity, maxHeight: 100)
#elseif os(tvOS)
                .frame(maxWidth: .infinity, maxHeight: 200)
#endif
            if #available (iOS 14.0, macOS 13.0, tvOS 17.0, *) {
                HStack(alignment:.bottom) {
                    Spacer()
                    Menu {
                        if let options = audios {
                            audioMenu(options: options)
                        }
                        if let options = subtitles {
                            subtitlesMenu(options: options)
                        }
                        playRatesMenu
                    } label: {
                        Label("", systemImage: "ellipsis.circle")
                    }
#if os(tvOS)
                    .focused($focusState, equals: .options)
#endif
                }
            }
        }
    }
    
    @available(iOS 14.0, macOS 13.0, tvOS 17.0, *)
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
            Label("Rate", systemImage: "gauge.with.dots.needle.67percent")
        })
    }
    
    @available(iOS 14.0, macOS 13.0, tvOS 17.0, *)
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
            Label("Subtitle", systemImage: "captions.bubble")
        })
    }
    
    @available(iOS 14.0, macOS 13.0, tvOS 17.0, *)
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
            Label("Audio", systemImage: "waveform.circle")
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
#if os(tvOS)
        .focused($focusState, equals: .close)
#endif
    }
    
    var skipBackwardButton: some View {
        Button(action: {
            playerModel.skip(-10)
        }, label: {
            Image(systemName: "10.arrow.trianglehead.counterclockwise")
                .resizable()
        })
        .buttonStyle(.mediumIcon)
#if os(tvOS)
        .focused($focusState, equals: .skipBackward)
#endif
    }
    
    var skipForwardButton: some View {
        Button(action: {
            playerModel.skip(10)
        }, label: {
            Image(systemName: "10.arrow.trianglehead.clockwise")
                .resizable()
        })
        .buttonStyle(.mediumIcon)
#if os(tvOS)
        .focused($focusState, equals: .skipForward)
#endif
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
#if os(tvOS)
        .focused($focusState, equals: .play)
        .prefersDefaultFocus(in: controlsNamespace)
#endif
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
