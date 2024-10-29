//
//  Video.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import AVKit
import SwiftUI

struct VideoRenderView: UIViewRepresentable {
    @Environment(\.playerModel) private var playerModel
    
    func makeUIView(context: Context) -> some UIView {
        let videoView = UIVideoView()
        videoView.player = playerModel.player
        playerModel.createPIPController(videoView.playerLayer)
        return videoView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

private class UIVideoView: UIView {
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
