//
//  File.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/30/24.
//

import SwiftUI

public struct PreviewRenderView: UIViewRepresentable {
    @Environment(\.playerPreviewModel) private var playerPreviewModel

    public func makeUIView(context: Context) -> some UIView {
        let videoView = UIVideoView()
        videoView.player = playerPreviewModel.player
        return videoView
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) { }
}
