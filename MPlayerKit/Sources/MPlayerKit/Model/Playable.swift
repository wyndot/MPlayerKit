//
//  Playable.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//
import Foundation

public enum MediaType: Sendable {
    case video, audio, liveVideo, liveAudio
}

public protocol Playable: Hashable, Sendable {
    var title: String { get }               // The title of the media asset
    var synopsis: String? { get }           // The synopsis of the media asset
    var poster: Artwork? { get }            // The poster artwork, can be portait or landscape
    var asset: URL { get }                  // The main media asset with full size
    var previewAsset: URL? { get }          // The preview media asset with smaller size, used for the scrubbing preview thumbnail
    var mediaType: MediaType { get }        // The media type
}
