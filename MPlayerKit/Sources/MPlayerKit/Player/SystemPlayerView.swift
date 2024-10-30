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

@MainActor
public struct SystemPlayerView: UIViewControllerRepresentable {
    @Environment(\.playerModel) private var playerModel
    var prepare: ((_ controller: AVPlayerViewController) -> Void)?
    var onTimeChange: ((_ time: CMTime) -> Void)?
    var onStateChange: ((_ state: PlayerState) -> Void)?

    public init(prepare: ((_: AVPlayerViewController) -> Void)? = nil,
                onTimeChange: ((_: CMTime) -> Void)? = nil,
                onStateChange: ((_: PlayerState) -> Void)? = nil) {
        self.prepare = prepare
        self.onTimeChange = onTimeChange
        self.onStateChange = onStateChange
    }
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
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
    
    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        logger.log("updateUIViewController")
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    @MainActor
    public class Coordinator: NSObject, @preconcurrency AVPlayerViewControllerDelegate {
        let parent: SystemPlayerView
        var cancellables: Set<AnyCancellable> = []
        
        init(parent: SystemPlayerView) {
            self.parent = parent
            super.init()
            parent.playerModel.$currentTime.sink(receiveValue: { time in
                guard let time else { return }
                parent.onTimeChange?(time)
            }).store(in: &cancellables)
            parent.playerModel.$state.sink(receiveValue: { state in
                parent.onStateChange?(state)
            }).store(in: &cancellables)
        }
        #if os(iOS)
        public func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            logger.log("player will begin full screen presentation")
        }
        
        public func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            logger.log("player will end full screen presentation")
            parent.playerModel.presentation = .inline
        }
        #endif
    }
}
