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
            SystemPlayerView(presentation: .inline(autoplay: true), prepare: { avPlayerController in
                logger.info("prepareCustomPlayerView: \(String(describing: avPlayerController))")
            }, onTimeChange: { time in
                logger.info("onTimeChange: \(String(describing: time))")
            }, onStateChange: { state in
                logger.info("onStateChange: \(String(describing: state))")
            })
                .ignoresSafeArea(.all)
                .task {
                    await playerModel.load(vod)
                    Task {
                        await playerPreviewModel.load(vod)
                    }
                }
        }
    }
}
