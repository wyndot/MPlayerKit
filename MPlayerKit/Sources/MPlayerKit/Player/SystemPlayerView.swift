//
//  SystemPlayerView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//
import SwiftUI
import AVKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "SystemPlayerView")

@MainActor
struct SystemPlayerView: UIViewControllerRepresentable {
    @Environment(\.playerModel) private var playerModel
    
    init() { }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = playerModel.player
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
        Coordinator(parent: self)
    }
    
    @MainActor
    class Coordinator: NSObject, @preconcurrency AVPlayerViewControllerDelegate {
        let parent: SystemPlayerView
        
        init(parent: SystemPlayerView) {
            self.parent = parent
        }
        #if os(iOS)
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            logger.log("player will begin full screen presentation")
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            logger.log("player will end full screen presentation")
            parent.playerModel.presentation = .inline
        }
        #endif
    }
}
