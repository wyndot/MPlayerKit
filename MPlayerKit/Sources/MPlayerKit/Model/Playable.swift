//
//  Playable.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//
import Foundation
import AVFoundation
import MediaPlayer

public enum MediaType: Sendable {
    case video, audio, liveVideo, liveAudio
    
    var isVideo: Bool {
        switch self {
            case .video, .liveVideo: true
            default: false
        }
    }
    
    var isLive: Bool {
        switch self {
            case .liveAudio, .liveVideo: true
            default: false
        }
    }
}

public protocol Playable: Hashable, Sendable {
    var title: String { get }               // The title of the media asset
    var synopsis: String? { get }           // The synopsis of the media asset
    var poster: Artwork? { get }            // The poster artwork, can be portait or landscape
    var asset: URL { get }                  // The main media asset with full size
    var previewAsset: URL? { get }          // The preview media asset with smaller size, used for the scrubbing preview thumbnail
    var mediaType: MediaType { get }        // The media type
    var releaseYear: Int? { get }           // The release year of the content
    var contentRating: String? { get }      // The content rating
    var genres: [String]? { get }           // The genres of content
    
    func extraExternalMetadata() -> [AVMetadataItem] // return empty array if there is no extra metadata need to be added
}

extension Playable {
    public var isLive: Bool { mediaType.isLive }
    public var isVideo: Bool { mediaType.isVideo }
}
