//
//  File.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//

import AVFoundation

extension Playable {
    func playerItem() -> AVPlayerItem {
        AVPlayerItem(url: asset)
    }
    func playerPreviewItem() -> AVPlayerItem? {
        guard let previewAsset else { return nil }
        return AVPlayerItem(url: previewAsset)
    }
}
