//
//  FullScreenCustomPlayerView.swift
//  Demo
//
//  Created by Michael Zhang on 10/30/24.
//

import SwiftUI
import MPlayerKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "FullScreenCustomPlayerView")

struct FullScreenCustomPlayerView: View {
    @Environment(\.playerModel) private var playerModel
    @Environment(\.playerPreviewModel) private var playerPreviewModel
    
    @State private var isFavorite: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {
                Task {
                    await playerModel.load(vod)
                    playerModel.presentation = .fullscreen(autoplay: true)
                    Task {
                        await playerPreviewModel.load(vod)
                    }
                }
            }, label: {
                AsyncImage(url: vod.poster?.landscapeUrl) { phase in
                    phase.image?.resizable().aspectRatio(contentMode: .fit)
                }
                .frame(width: 200, height: 300)
            })
        }
        .customPlayerFullScreenPresenter(controls: { _ in
            CustomControlsView()        // You can provide your own controls view here 
        }, prepare: { playerLayer in
            logger.info("prepareCustomPlayerView: \(String(describing: playerLayer))")
        }, onTimeChange: { time in
            logger.info("onTimeChange: \(String(describing: time))")
        }, onStateChange: { state in
            logger.info("onStateChange: \(String(describing: state))")
        })
    }
}
