//
//  AVPlayerItem+Ext.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//
@preconcurrency import AVFoundation

public enum AVPlayerItemError: Error {
    case missingVideoTrack
}

extension AVPlayerItem {
    func loadSize() async throws -> CGSize {
        guard let assetTrack = self.tracks.first(where: { $0.assetTrack?.mediaType == .video})?.assetTrack else { throw AVPlayerItemError.missingVideoTrack }
        let transform = try await assetTrack.load(.preferredTransform)
        return  try await assetTrack.load(.naturalSize).applying(transform)
    }
    
    func loadAspectRatio() async -> CGFloat {
        guard let size = try? await loadSize() else { return 16.0 / 9.0 }
        let ratio = size.width.isNaN || size.height.isNaN ? 0 : size.width / size.height
        return ratio.isNormal ? ratio : 16.0 / 9.0
    }
    
    func availableLanguageSelectionGroup() async throws -> [AVMediaSelectionGroup] {
        let characteristics = try await asset.load(.availableMediaCharacteristicsWithMediaSelectionOptions).filter({ $0 == .audible || $0 == .legible })
        var selectionGroups: [AVMediaSelectionGroup] = []
        for characteristic in characteristics {
            guard let selectionGroup = try await asset.loadMediaSelectionGroup(for: characteristic) else { continue }
            selectionGroups.append(selectionGroup)
        }
        return selectionGroups
    }
    
    func availableSutitleSelectionGroup() async throws -> AVMediaSelectionGroup? {
        try await asset.loadMediaSelectionGroup(for: .legible)
    }
    
    func availableAudioSelectionGroup() async throws -> AVMediaSelectionGroup? {
        try await asset.loadMediaSelectionGroup(for: .audible)
    }
    
    func currentLanguageOptions(in groups: [AVMediaSelectionGroup]) -> [AVMediaSelectionOption] {
        groups.compactMap({ group in currentMediaSelection.selectedMediaOption(in: group) })
    }
}
