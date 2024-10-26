//
//  ContentView.swift
//  Demo
//
//  Created by Michael Zhang on 10/23/24.
//

import SwiftUI
import MPlayerKit

struct VOD: Playable {
    var title: String
    var synopsis: String?
    var poster: MPlayerKit.Artwork?
    var asset: URL
    var previewAsset: URL?
    var mediaType: MPlayerKit.MediaType
}

private let vod: VOD = .init(title: "Sintel",
                             synopsis: "Sintel is an open movie from the Blender Foundation licensed under the Creative Commons Attribution 3.0 license.",
                             poster: .init(url: URL(string: "https://media-io.s3.us-west-1.amazonaws.com/Poster.jpg")!),
                             asset: URL(string: "https://media-io.s3.us-west-1.amazonaws.com/sintel/playlist.m3u8")!,
                             previewAsset: URL(string: "https://media-io.s3.us-west-1.amazonaws.com/sintel-thumbnail/sintel-thumbnail.mp4")!,
                             mediaType: .video)

struct ContentView: View {
    @Environment(\.playerModel) private var playerModel
    @Environment(\.playerPreviewModel) private var playerPreviewModel
    
    var body: some View {
        VStack {
//            PlayerView(controlsStyle: .custom)
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
        .playerFullScreenPresenter(controlsStyle: .custom)
    }
}

#Preview {
    ContentView()
}
