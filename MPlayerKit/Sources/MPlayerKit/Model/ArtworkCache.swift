//
//  File.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//

import Foundation

public protocol ArtworkCacheable {
    func artwork(for url: URL) async throws -> Data
}

extension ArtworkCacheable {
    public func artwork(for url: URL) async throws -> Data {
        return try await ArtworkCache.shared.artwork(for: url)
    }
}

internal actor ArtworkCache {
    static var shared = ArtworkCache()
    private var cache = NSCache<NSString, NSData>()
    init() {
        cache.countLimit = 500
        cache.totalCostLimit = 500 * 1024 * 1024
    }
    
    func artwork(for url: URL) async throws -> Data {
        if let data = cache.object(forKey: NSString(string: url.absoluteString)) {
            return data as Data
        }
        let data = try await fetch(url)
        cache.setObject(data as NSData, forKey: NSString(string: url.absoluteString), cost: data.count)
        return data
    }
    
    private func fetch(_ url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
