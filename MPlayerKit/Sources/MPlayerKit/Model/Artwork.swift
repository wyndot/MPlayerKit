//
//  File.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//

import Foundation

public struct Artwork: Hashable, Sendable, ArtworkCacheable {
    public enum Orientation {
        case landscape
        case portrait
    }
    public let portraitUrl: URL
    public let landscapeUrl: URL
    
    public init(portraitUrl: URL, landscapeUrl: URL) {
        self.portraitUrl = portraitUrl
        self.landscapeUrl = landscapeUrl
    }
    
    public init(url: URL) {
        self.portraitUrl = url
        self.landscapeUrl = url
    }
    
    public func artwork(for orientation: Orientation) async throws -> Data {
        switch orientation {
            case .portrait: try await artwork(for: self.portraitUrl)
            case .landscape: try await artwork(for: self.landscapeUrl)
        }
    }
}
