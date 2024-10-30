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

@MainActor
public struct CustomControlsView: View {
#if os(tvOS)
    enum ControlsFocusState: Hashable {
        case close
        case play
        case track
        case skipForward
        case skipBackward
        case options
        case pip
    }
    @Namespace private var controlsNamespace
    @FocusState private var focusState: ControlsFocusState?
#endif
    @Environment(\.playerModel) private var playerModel
    @State private var safeAreaInsets: UIEdgeInsets = .zero
    @State private var presentation: PlayerPresentation = .none
    @State private var playerState: PlayerState = .paused(reason: .userInitiated)
    @State private var trackingState: TrackState = .idle
    @State private var subtitles: [AVMediaSelectionOption]? = nil
    @State private var audios: [AVMediaSelectionOption]? = nil
    @State private var subtitle: AVMediaSelectionOption? = nil
    @State private var audio: AVMediaSelectionOption? = nil
    @State private var rate: Float = 1.0
    @State private var isPiPActive: Bool = false
    @State private var isPiPPossible: Bool = false
    
    public init() { }
    
    public var body: some View {
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
    
    /**
     * The content of the custom controls
     */
    private var content: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                let halfHeight = geometry.size.height / 2.0
                let top = halfHeight - safeAreaInsets.top - 10
                let bottom = halfHeight - safeAreaInsets.bottom - 10
                let leading = CGFloat(safeAreaInsets.left) + 10
                let trailing = CGFloat(safeAreaInsets.right) + 10
                Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                topbar
                    .padding(.leading, leading)
                    .padding(.trailing, trailing)
                    .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                        d[.top] + top
                    })
                
                middlebar
                    .padding(.leading, leading)
                    .padding(.trailing, trailing)
                    .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                        d[VerticalAlignment.center]
                    })
                
                VStack(alignment: .center, spacing: 4) {
                    playbackInfoBar
                    bottombar
                }
                .padding(.leading, leading)
                .padding(.trailing, trailing)
                .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                    d[.bottom] - bottom
                })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            SafeAreaInsetsView { insets in
                self.safeAreaInsets = insets
            }
        )
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
        .onReceive(playerModel.$availableSubtitles.receive(on: DispatchQueue.main), perform: { newValue in
            subtitles = newValue?.options
        })
        .onReceive(playerModel.$availableAudios.receive(on: DispatchQueue.main), perform: { newValue in
            audios = newValue?.options
        })
        .onReceive(playerModel.$subtitle.receive(on: DispatchQueue.main), perform: { newValue in
            subtitle = newValue
        })
        .onReceive(playerModel.$audio.receive(on: DispatchQueue.main), perform: { newValue in
            audio = newValue
        })
        .onReceive(playerModel.$isPiPActive.receive(on: DispatchQueue.main), perform: { newValue in
            isPiPActive = newValue
        })
        .onReceive(playerModel.$isPiPPossible.receive(on: DispatchQueue.main), perform: { newValue in
            isPiPPossible = newValue
        })
    }
    
    /**
     * The top bar. It includes the close button if this is presented on fullscreen, volume slider,
     * and the casting buttons which includes the PiP button and AirPlay button
     */
    private var topbar: some View {
        HStack(alignment: .center, spacing: topBarSpacing) {
            if case .fullscreen(_) = presentation {
                closeButton
            }
            Spacer()
            #if os(iOS)
            VolumeSlider()
            Spacer()
            #endif
            if isPiPPossible {
                pipButton
            }
            airplayButton
        }
        .frame(maxWidth: .infinity)
#if os(tvOS)
        .focusSection()
#endif
    }
    
    /**
     * The middle bar. It contains the skip backward button, play or pause button and skip forward button
     */
    private var middlebar: some View {
        HStack(alignment: .center, spacing: middleBarSpacing) {
            skipBackwardButton
            playPauseButton
            skipForwardButton
        }
        .frame(maxWidth: .infinity)
#if os(tvOS)
        .focusSection()
#endif
    }
    
    /**
     * The bottom bar. It contains the playback time track bar
     */
    private var bottombar: some View {
        HStack(alignment: .center, spacing: 0) {
            PlaybackTimeBar(trackingState: $trackingState)
        }
        .frame(maxWidth: .infinity)
#if os(tvOS)
        .focusSection()
#endif
    }
    
    /**
     * The playback info bar showing above the time track bar. It includes the playback title, subtitle and preview.
     */
    private var playbackInfoBar: some View {
        ZStack(alignment: .bottom) {
            playbackInfoTitles
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
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                    }
                    .buttonStyle(.xsmallIcon)
#if os(tvOS)
                    .focused($focusState, equals: .options)
#endif
                }
            }
        }
    }
    
    /**
     * The playback title and subtitle showing above the time track bar
     */
    private var playbackInfoTitles: some View {
        VStack(alignment: .leading) {
            Text(playerModel.currentItem?.subtitle ?? "")
                .font(.subheadline)
            Text(playerModel.currentItem?.title ?? "")
                .font(.title)
        }
        .foregroundStyle(Color.accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /**
     * The play rate menu item
     */
    @available(iOS 14.0, macOS 13.0, tvOS 17.0, *)
    private var playRatesMenu: some View {
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
    
    /**
     * The subtitle menu item
     */
    @available(iOS 14.0, macOS 13.0, tvOS 17.0, *)
    private func subtitlesMenu(options: [AVMediaSelectionOption]) -> some View {
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
    
    /**
     * The audio menu item
     */
    @available(iOS 14.0, macOS 13.0, tvOS 17.0, *)
    private func audioMenu(options: [AVMediaSelectionOption]) -> some View {
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
    
    /**
     * The close button to dismiss the fullscreen presentation
     */
    private var closeButton: some View {
        Button(action: {
            playerModel.presentation = .none
        }, label: {
            Image(systemName: "xmark")
                .resizable()
        })
        .buttonStyle(.xsmallIcon)
#if os(tvOS)
        .focused($focusState, equals: .close)
#endif
    }
    
    /**
     * The playback skip backward button
     */
    private var skipBackwardButton: some View {
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
    
    /**
     * The playback skip forward button
     */
    private var skipForwardButton: some View {
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
    /**
     * The playback play or pause button
     */
    private var playPauseButton: some View {
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
    
    /**
     * The PiP toggle button
     */
    private var pipButton: some View {
        Button(action: {
            playerModel.togglePiP()
        }, label: {
            Image(systemName: isPiPActive ? "pip.exit" : "pip.enter")
                .resizable()
                .aspectRatio(contentMode: .fit)
        })
        .buttonStyle(.pip)
        .frame(width: pipButtonSize, height: pipButtonSize + 5)
        .disabled(!isPiPPossible)
#if os(tvOS)
        .focused($focusState, equals: .pip)
#endif
    }
    
    /**
     * The AirPlay button
     */
    private var airplayButton: some View {
        AirPlayPickerView()
            .frame(width: airplayButtonSize, height: airplayButtonSize)
    }
    /**
     * The formatter for the playback rate in the rate menu item
     */
    private var rateFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }
    
    /**
     * The spacing between the buttons in the top bar
     */
    var topBarSpacing: CGFloat {
#if os(tvOS)
        40
#else
        10
#endif
    }
    
    /**
     * The spacing between the buttons in the middle bar
     */
    var middleBarSpacing: CGFloat {
        #if os(tvOS)
        120
        #else
        60
        #endif
    }
    
    /**
     * The PiP button size
     */
    var pipButtonSize: CGFloat {
#if os(tvOS)
        82
#else
        45
#endif
    }
    
    /**
     * The AirPlay button size
     */
    var airplayButtonSize: CGFloat {
#if os(tvOS)
        50
#else
        20
#endif
    }
}

#Preview {
    CustomControlsView()
        .edgesIgnoringSafeArea(.all)
}
