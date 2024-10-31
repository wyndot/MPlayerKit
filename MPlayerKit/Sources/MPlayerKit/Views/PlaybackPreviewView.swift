//
//  PlaybackPreviewView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/26/24.
//
import SwiftUI
import AVFoundation

public struct PlaybackPreviewView: View {
    @Environment(\.playerPreviewModel) private var playerPreviewModel
    @Binding var trackingState: TrackState
    public var body: some View {
        GeometryReader { geometry in
            let previewSize = previewSize(geometry: geometry)
            let geometrySize = geometry.size
            ZStack {
                switch trackingState {
                    case .tracking(value: let value):
                        let offset = offset(geometrySize: geometrySize, previewSize: previewSize, progress: value)
                        PreviewRenderView()
                            .frame(maxWidth: previewSize.width, maxHeight: previewSize.height)
                            .offset(x: offset.x, y: offset.y)
                    default:
                        EmptyView()
                }
            }
        }
        .onChange(of: trackingState, perform: { newValue in
            guard case .tracking(value: let value) = newValue,  case .paused(reason: .userInitiated) = playerPreviewModel.state, let duration = playerPreviewModel.duration else { return }
            let time = CMTime(seconds: duration.seconds * value, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            playerPreviewModel.seek(time)
        })
    }
      
    public func previewSize(geometry: GeometryProxy) -> CGSize {
        .init(width: playerPreviewModel.aspectRatio * geometry.size.height, height: geometry.size.height)
    }
    
    public func offset(geometrySize: CGSize, previewSize: CGSize, progress: Double) -> CGPoint {
        let position = geometrySize.width * progress - previewSize.width / 2.0
        let upperBound = geometrySize.width - previewSize.width
        let x = min(max(position, 0.0), upperBound)
        return CGPoint(x: x, y: 0.0)
    }
}
