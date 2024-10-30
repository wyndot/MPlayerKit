//
//  InlineSystemPlayerView.swift
//  Demo
//
//  Created by Michael Zhang on 10/30/24.
//

import SwiftUI
import MPlayerKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "InlineSystemPlayerView")

struct InlineSystemPlayerView: View {
    @Environment(\.playerModel) private var playerModel
    @Environment(\.playerPreviewModel) private var playerPreviewModel
    
    @State private var isFavorite: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            SystemPlayerView(prepare: { avPlayerController in
                logger.debug("prepareCustomPlayerView: \(String(describing: avPlayerController))")
            },
                       onTimeChange: { time in
                logger.debug("onTimeChange: \(String(describing: time))")
            })
                .ignoresSafeArea(.all)
                .task {
                    await playerModel.load(vod)
                    Task {
                        await playerPreviewModel.load(vod)
                    }
                }
                .onAppear {
                    playerModel.play()
                }
                .onDisappear {
                    playerModel.pause()
                }
        }
    }
}
