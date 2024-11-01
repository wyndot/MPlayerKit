//
//  SystemPlayerView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//
import SwiftUI
import AVKit
import Combine
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "SystemPlayerView")

public struct SystemPlayerView: View {
    @Environment(\.playerModel) private var playerModel
    let presentation: PlayerPresentation
    var prepare: ((_ controller: AVPlayerViewController) -> Void)?
    var onTimeChange: ((_ time: CMTime) -> Void)?
    var onStateChange: ((_ state: PlayerState) -> Void)?
    
    public init(presentation: PlayerPresentation = .inline(autoplay: true),
                prepare: ((_: AVPlayerViewController) -> Void)? = nil,
                onTimeChange: ((_: CMTime) -> Void)? = nil,
                onStateChange: ((_: PlayerState) -> Void)? = nil) {
        self.prepare = prepare
        self.onTimeChange = onTimeChange
        self.onStateChange = onStateChange
        self.presentation = presentation
    }
    
    public var body: some View {
        SystemPlayerRepresentableView(prepare: prepare)
            .onReceive(playerModel.$currentTime, perform: { newValue in
                guard let newValue else { return }
                onTimeChange?(newValue)
            })
            .onReceive(playerModel.$state, perform: { newValue in
                onStateChange?(newValue)
            })
            .onAppear {
                logger.info("\(Self.self) onAppear")
                playerModel.presentation = presentation
                switch presentation {
                    case .fullscreen(autoplay: let autoplay) where autoplay,
                            .inline(autoplay: let autoplay) where autoplay :
                        playerModel.play()
                    default: break 
                }
            }
            .onDisappear {
                playerModel.pause()
                logger.info("\(Self.self) onDisappear")
            }
    }
}

@MainActor
private struct SystemPlayerRepresentableView: UIViewControllerRepresentable {
    @Environment(\.playerModel) private var playerModel
    var prepare: ((_ controller: AVPlayerViewController) -> Void)?
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = playerModel.player
        prepare?(playerViewController)
        #if os(iOS)
        playerViewController.entersFullScreenWhenPlaybackBegins = false
        #endif
        playerViewController.modalPresentationStyle = .fullScreen
        playerViewController.delegate = context.coordinator
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        logger.log("updateUIViewController")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(playerModel)
    }
    
    @MainActor
    class Coordinator: NSObject, @preconcurrency AVPlayerViewControllerDelegate {
        private var playerModel: PlayerModel
        init(_ playerModel: PlayerModel) {
            self.playerModel = playerModel
            super.init()
        }
        #if os(iOS)
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) { }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            playerModel.presentation = .none
        }
        #endif
    }
}
