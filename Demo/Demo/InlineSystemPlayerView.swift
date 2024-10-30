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
            }, onTimeChange: { time in
                logger.debug("onTimeChange: \(String(describing: time))")
            }, onStateChange: { state in
                logger.debug("onStateChange: \(String(describing: state))")
            })
                .ignoresSafeArea(.all)
                .task {
                    await playerModel.load(vod)
                    Task {
                        await playerPreviewModel.load(vod)
                    }
                }
                .onAppear {
                    logger.debug("onStateChange: Started")
                    playerModel.play()
                }
                .onDisappear {
                    logger.debug("onStateChange: Ended")
                    playerModel.pause()
                }
        }
    }
}
