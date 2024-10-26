//
//  Video.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import AVKit
import SwiftUI

struct VideoRenderView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> some UIView {
        let videoView = UIVideoView()
        videoView.player = player
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
