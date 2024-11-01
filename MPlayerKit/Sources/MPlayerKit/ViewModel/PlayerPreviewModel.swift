//
//  PlayerPreviewModel.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/26/24.
//

@preconcurrency import AVKit
import Combine
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "PlayerPreviewModel")

@MainActor
public class PlayerPreviewModel {
    @Published private(set) var state: PlayerState = .paused(reason: .userInitiated)
    @Published private(set) var currentItem: (any Playable)?
    @Published private(set) var duration: CMTime?
    @Published private(set) var currentTime: CMTime?
    @Published private(set) var aspectRatio: CGFloat = 16.0 / 9.0
    private(set) var player: AVPlayer = AVPlayer()
    private(set) var playerTimeControlStatusObservationToken: NSKeyValueObservation?
    
    public init() {
        logger.info("\(Self.self) Initialized")
        startObservingPlayback()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.stopObservingPlayback()
        }
        logger.info("\(Self.self) Deinitialized")
    }
    
    /**
     * Load the Playable meida
     *
     * - Parameters:
     *  - item: The playable media item
     */
    public func load(_ item: any Playable) async {
        guard let previewItem = item.playerPreviewItem() else { return }
        currentItem = item
        player.replaceCurrentItem(with: previewItem)
        duration = try? await previewItem.asset.load(.duration)
        aspectRatio = await previewItem.loadAspectRatio()
        currentTime = player.currentTime()
    }
    public func seek(_ to: CMTime) { player.seek(to: to) }
}

// Observation
extension PlayerPreviewModel {
    /**
     * Start observing playback. This is including observing the player time control status, player did play to the end, audio session interruption, and the periodic time observation
     */
    private func startObservingPlayback() {
        logger.info("\(Self.self) Starting observation of player")
        startObservingPlayerTimeControlStatus()
    }
    /**
     * Stop observing playback
     */
    private func stopObservingPlayback() {
        playerTimeControlStatusObservationToken?.invalidate()
        logger.info("\(Self.self) Stopped observation of player")
    }
    
    /**
     * Start observing the player time control status
     */
    private func startObservingPlayerTimeControlStatus() {
        guard playerTimeControlStatusObservationToken == nil else { return }
        playerTimeControlStatusObservationToken = player.observe(\.timeControlStatus) { observed, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch observed.timeControlStatus {
                    case .paused:
                        state = .paused(reason: .userInitiated)
                    case .playing:
                        state = .playing
                    case .waitingToPlayAtSpecifiedRate:
                        switch observed.reasonForWaitingToPlay {
                            case .toMinimizeStalls:
                                state = .buffering(reason: .toMinimizeStalls)
                            case .evaluatingBufferingRate:
                                state = .buffering(reason: .evaluatingBufferRate)
                            case .noItemToPlay:
                                state = .buffering(reason: .noItemToPlay)
                            case .waitingForCoordinatedPlayback:
                                state = .buffering(reason: .waitingForCoorindatedPlayback)
                            default:
                                state = .buffering(reason: .unknown)
                        }
                    @unknown default: break
                }
            }
        }
    }
}
