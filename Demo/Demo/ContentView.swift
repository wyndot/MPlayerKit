//
//  ContentView.swift
//  Demo
//
//  Created by Michael Zhang on 10/23/24.
//

import SwiftUI
import MPlayerKit
import AVKit
import UIKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "ContentView")

struct VOD: Playable {
    var title: String
    var subtitle: String?
    var synopsis: String?
    var poster: MPlayerKit.Artwork?
    var asset: URL
    var previewAsset: URL?
    var mediaType: MPlayerKit.MediaType
    var releaseYear: Int?
    var genres: [String]?
    var contentRating: String?
    
    func extraExternalMetadata() -> [AVMetadataItem] { [] }
}

let vod: VOD = .init(title: "Sintel",
                     subtitle: "Open Movie from Blender Foundation",
                     synopsis: "Sintel is an open movie from the Blender Foundation licensed under the Creative Commons Attribution 3.0 license.",
                     poster: .init(url: URL(string: "https://media-io.s3.us-west-1.amazonaws.com/Poster.jpg")!),
                     asset: URL(string: "https://media-io.s3.us-west-1.amazonaws.com/sintel/playlist.m3u8")!,
                     previewAsset: URL(string: "https://media-io.s3.us-west-1.amazonaws.com/sintel-thumbnail/sintel-thumbnail.mp4")!,
                     mediaType: .video)

struct ContentView: View {
    enum PlayerType: Hashable {
        case fullscreenCustom
        case fullscreenSystem
        case inlineCustom
        case inlineSystem
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                NavigationLink(value: PlayerType.fullscreenSystem, label: {
                    Text("Fullscreen System Player")
                        .frame(maxWidth: .infinity)
                })
               
                NavigationLink(value: PlayerType.fullscreenCustom, label: {
                    Text("Fullscreen Custom Player")
                        .frame(maxWidth: .infinity)
                })
                NavigationLink(value: PlayerType.inlineSystem, label: {
                    Text("Inline System Player")
                        .frame(maxWidth: .infinity)
                })
                NavigationLink(value: PlayerType.inlineCustom, label: {
                    Text("Inline Custom Player")
                        .frame(maxWidth: .infinity)
                })
            }
            .buttonStyle(.bordered)
            .navigationDestination(for: PlayerType.self, destination: { type in
                switch type {
                    case .fullscreenCustom:
                        FullScreenCustomPlayerView().navigationBarTitle("Fullscreen Custom Player")
                    case .fullscreenSystem:
                        FullScreenSystemPlayerView().navigationTitle("Fullscreen System Player")
                    case .inlineCustom:
                        InlineCustomPlayerView().navigationBarTitle("Inline Custom Player")
                    case .inlineSystem:
                        InlineSystemPlayerView().navigationBarTitle("Inline System Player")
                        
                }
            })
        }
    }
}

#Preview {
    ContentView()
}
