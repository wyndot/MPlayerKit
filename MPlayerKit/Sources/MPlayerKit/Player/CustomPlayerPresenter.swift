//
//  File.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/30/24.
//
import SwiftUI
import Combine
import AVKit
import os 

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "CustomPlayerFullScreenPresenter")

public struct CustomPlayerFullScreenPresenter<C>: ViewModifier where C: View {
    @Environment(\.playerModel) private var playerModel
    @State private var isPresented: Bool = false
    @State private var autoplay: Bool = false
    @ViewBuilder var controls: (_ playerModel: PlayerModel) -> C
    var prepare: ((_ playerLayer: AVPlayerLayer) -> Void)?
    var onTimeChange: ((CMTime) -> Void)?
    var onStateChange: ((_ state: PlayerState) -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented, onDismiss: {
                playerModel.presentation = .none
            }) {
                ZStack {
                    Color.black.ignoresSafeArea(.all)
                    
                    CustomPlayerView(controls: controls,
                                     prepare: prepare,
                                     onTimeChange: onTimeChange,
                                     onStateChange: onStateChange)
                        .ignoresSafeArea(.all)
                        .onAppear {
                            logger.debug("onStateChange: Stated")
                            if autoplay { playerModel.play() }
                        }
                        .onDisappear {
                            logger.debug("onStateChange: Ended")
                            playerModel.pause()
                        }
                }
            }
            .onReceive(playerModel.$presentation, perform: { newPresentation in
                if case .fullscreen(let autoplay) = newPresentation {
                    isPresented = true
                    self.autoplay = autoplay
                } else {
                    isPresented = false
                    self.autoplay = false
                }
            })
    }
}

extension View {
    public func customPlayerFullScreenPresenter<C>(controls: @escaping (_ playerModel: PlayerModel) -> C,
                                                   prepare: ((_ playerLayer: AVPlayerLayer) -> Void)? = nil,
                                                   onTimeChange: ((_ time: CMTime) -> Void)? = nil,
                                                   onStateChange: ((_ state: PlayerState) -> Void)? = nil) -> some View where C: View {
        modifier(CustomPlayerFullScreenPresenter(controls: controls,
                                                 prepare: prepare,
                                                 onTimeChange: onTimeChange,
                                                 onStateChange: onStateChange))
    }
}
