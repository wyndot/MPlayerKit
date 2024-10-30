//
//  FullScreenSystemPlayerView.swift
//  Demo
//
//  Created by Michael Zhang on 10/30/24.
//

import SwiftUI
import AVKit
import MPlayerKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "FullScreenSystemPlayerView")

struct FullScreenSystemPlayerView: View {
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
        .systemPlayerFullScreenPresenter(prepare: { avPlayerViewController in
            logger.debug("prepareCustomPlayerView: \(String(describing: avPlayerViewController))")
#if os(tvOS)
            setupAVPlayerViewController(avPlayerViewController)
#endif
        }, onTimeChange: { time in
            logger.debug("onTimeChange: \(String(describing: time))")
        }, onStateChange: { state in
            logger.debug("onStateChange: \(String(describing: state))")
        })
    }
    
#if os(tvOS)
    private func setupAVPlayerViewController(_ avPlayerViewController: AVPlayerViewController) {
        let heartImage = UIImage(systemName: "heart")
        let hearFillImage = UIImage(systemName: "heart.fill")
        
        let favoriteAction = UIAction(title: "Favorites", image: isFavorite ? hearFillImage : heartImage) { action in
            isFavorite.toggle()
            action.image = isFavorite ? hearFillImage : heartImage
        }
        
        // Create ∞ and ⚙ images.
        let loopImage = UIImage(systemName: "infinity")
        let gearImage = UIImage(systemName: "gearshape")


        // Create an action to enable looping playback.
        let loopAction = UIAction(title: "Loop", image: loopImage, state: .off) { action in
            action.state = (action.state == .off) ? .on : .off
        }

        // Create the main menu.
        let menu = UIMenu(title: "Preferences", image: gearImage, children: [loopAction])
        
        avPlayerViewController.transportBarCustomMenuItems = [favoriteAction, menu]
    }
#endif
}
