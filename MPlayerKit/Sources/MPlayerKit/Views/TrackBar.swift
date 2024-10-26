//
//  TrackBar.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/25/24.
//
import SwiftUI

enum TrackState: Equatable {
    case idle
    case tracking(value: Double)
    case ended(value: Double)
}

struct TrackBar: View {
    @Binding var value: Double
    @Binding var state: TrackState
    let maxHeight: CGFloat = 40
    let barHeight: CGFloat = 10
#if os(tvOS)
    @FocusState private var isFocused: Bool
#endif
    
    var body: some View {
#if os(iOS)
        GeometryReader { geometry in
            track(geometry: geometry)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newVolume = value.location.x / geometry.size.width
                        self.state = .tracking(value: min(max(0, Double(newVolume)), 1))
                    }
                    .onEnded({  value in
                        self.state = .ended(value: trackingValue)
                    })
            )
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight)
#elseif os(tvOS)
        Button(action: {
            switch state {
                case .tracking(let value):
                    state = .ended(value: value)
                default:
                    state = .ended(value: trackingValue)
                    
            }
        }, label: {
            GeometryReader { geometry in
                track(geometry: geometry)
            }
            .remoteTouch(RemoteTouch(onChanged: { pt in
                guard isFocused else { return }
                state = .tracking(value: min(max((trackingValue + pt.x / 30), 0.0), 1.0))
            }, onEnded: {
                switch state {
                    case .tracking(let value):
                        state = .ended(value: value)
                    default:
                        state = .ended(value: trackingValue)
                        
                }
            }))
        })
        .focused($isFocused)
        .frame(maxWidth: .infinity, maxHeight: maxHeight)
        .buttonStyle(.none)
#endif
    }
    
    func track(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundStyle(Color.white.opacity(0.01))
                
            ZStack(alignment: .leading) {
                trackBar
                progressBar(geometry: geometry)
            }
#if os(iOS)
            .frame(height: barHeight)
#elseif os(tvOS)
            .frame(height: isFocused ? 1.5 * barHeight : barHeight)
#endif
        }
    }
    
    var trackBar: some View {
        Rectangle()
            .foregroundStyle(.secondary)
            .cornerRadius(barHeight / 2.0)
            .shadow(radius: 1)
        
    }
    
    func progressBar(geometry: GeometryProxy) -> some View {
        Rectangle()
        #if os(iOS)
            .foregroundStyle(Color.accentColor)
        #elseif os(tvOS)
            .foregroundStyle(isFocused ? Color.accentColor : .primary)
        #endif
            .cornerRadius(barHeight / 2.0)
            .shadow(radius: 1)
            .frame(width: CGFloat(trackingValue) * geometry.size.width)
    }
    
    var trackingValue: Double {
        switch state {
            case .ended(value: let value): return value
            case .tracking(value: let value): return value
            case .idle: return value
        }
    }
}
