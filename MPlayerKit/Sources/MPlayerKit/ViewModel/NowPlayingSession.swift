//
//  NowPlayingSession.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/28/24.
//

import Foundation
import Combine
import MediaPlayer

#if os(iOS)
@MainActor
class NowPlayingSession: NSObject, ObservableObject {
    var nowPlayingSession: MPNowPlayingSession?
    let remoteCommand = PassthroughSubject<UIEvent.EventSubtype, Never>()
    
    override init() { }
    
    deinit {
        Task {
            await UIApplication.shared.endReceivingRemoteControlEvents()
        }
    }
    
    func active(player: AVPlayer) {
        guard !(nowPlayingSession?.players.contains(player) ?? false) else { return }
        nowPlayingSession = MPNowPlayingSession(players: [player])
        nowPlayingSession?.becomeActiveIfPossible()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func publish(metadata: [String: Any]?, isPlaying: Bool = false) {
        guard let nowPlayingSession, let metadata else { return }
        
        let nowPlayingCenter = nowPlayingSession.nowPlayingInfoCenter
        var copy = nowPlayingCenter.nowPlayingInfo ?? [:]
        copy.merge(metadata, uniquingKeysWith: { _, value in value })
        nowPlayingCenter.nowPlayingInfo = copy
        nowPlayingCenter.playbackState = isPlaying ? .playing : .paused
    }
}
#endif
