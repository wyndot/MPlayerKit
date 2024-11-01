//
//  InlineCustomPlayerView.swift
//  Demo
//
//  Created by Michael Zhang on 10/30/24.
//
import SwiftUI
import MPlayerKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "InlineCustomPlayerView")

struct InlineCustomPlayerView: View {
    @Environment(\.playerModel) private var playerModel
    @Environment(\.playerPreviewModel) private var playerPreviewModel
    
    @State private var isFavorite: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            CustomPlayerView(controls: { _ in
                CustomControlsView()             // You can provide your own controls view here
            }, presentation: .inline(autoplay: true), prepare: { playerLayer in
                logger.info("prepareCustomPlayerView: \(String(describing: playerLayer))")
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
