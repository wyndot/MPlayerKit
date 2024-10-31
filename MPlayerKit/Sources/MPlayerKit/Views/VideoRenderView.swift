//
//  Video.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import AVKit
import SwiftUI

public struct VideoRenderView: UIViewRepresentable {
    @Environment(\.playerModel) private var playerModel
    var prepare: ((_ playerLayer: AVPlayerLayer) -> Void)?
    
    public func makeUIView(context: Context) -> some UIView {
        let videoView = UIVideoView()
        videoView.player = playerModel.player
        playerModel.createPIPController(videoView.playerLayer)
        prepare?(videoView.playerLayer)
        return videoView
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) { }
}

class UIVideoView: UIView {
    class override var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    override func layoutSubviews() {
        playerLayer.frame = bounds
    }
}
