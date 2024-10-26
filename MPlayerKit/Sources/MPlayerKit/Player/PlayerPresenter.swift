//
//  PlayerPresenter.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//
import SwiftUI
import Combine

public struct PlayerFullScreenPresenter: ViewModifier {
    @Environment(\.playerModel) private var playerModel
    @State private var isPresented: Bool = false
    @State private var autoplay: Bool = false
    let controlsStyle: PlayerControlsStyle
    
    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented, onDismiss: {
                playerModel.presentation = .none
            }) {
                ZStack {
                    Color.black.ignoresSafeArea(.all)
                    PlayerView(controlsStyle: controlsStyle)
                        .ignoresSafeArea(.all)
                        .onAppear {
                            if autoplay {
                                playerModel.play()
                            }
                        }
                        .onDisappear {
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
    public func playerFullScreenPresenter(controlsStyle: PlayerControlsStyle = .system) -> some View {
        modifier(PlayerFullScreenPresenter(controlsStyle: controlsStyle))
    }
}
