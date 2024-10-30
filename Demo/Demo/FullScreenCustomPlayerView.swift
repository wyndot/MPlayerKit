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
                    switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        default:
                            Color.gray
                    }
                }
                .frame(width: 200, height: 300)
            })
        }
        .padding()
        .customPlayerFullScreenPresenter(customControls: { _ in
            CustomControlsView()        // You can provide your own controls view here 
        }, prepare: { playerLayer in
            logger.debug("prepareCustomPlayerView: \(String(describing: playerLayer))")
        }, onTimeChange: { time in
            logger.debug("onTimeChange: \(String(describing: time))")
        }, onStateChange: { state in
            logger.debug("onStateChange: \(String(describing: state))")
        })
    }
}
