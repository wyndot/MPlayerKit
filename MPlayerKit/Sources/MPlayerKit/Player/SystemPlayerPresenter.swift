//
//  PlayerPresenter.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//
import SwiftUI
import Combine
import AVKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "SystemPlayerFullScreenPresenter")

public struct SystemPlayerFullScreenPresenter: ViewModifier {
    @Environment(\.playerModel) private var playerModel
    @State private var isPresented: Bool = false
    @State private var autoplay: Bool = false
    var prepare: ((_ controller: AVPlayerViewController) -> Void)?
    var onTimeChange: ((CMTime) -> Void)?
    var onStateChange: ((_ state: PlayerState) -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented, onDismiss: {
                playerModel.presentation = .none
            }) {
                ZStack {
                    Color.black.ignoresSafeArea(.all)
                    
                    SystemPlayerView(prepare: prepare,
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
    public func systemPlayerFullScreenPresenter(prepare: ((_ playerController: AVPlayerViewController) -> Void)? = nil,
                                             onTimeChange: ((_ time: CMTime) -> Void)? = nil,
                                                onStateChange: ((_ state: PlayerState) -> Void)? = nil) -> some View {
        modifier(SystemPlayerFullScreenPresenter(prepare: prepare,
                                                 onTimeChange: onTimeChange,
                                                 onStateChange: onStateChange))
    }
}
