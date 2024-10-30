//
//  CustomPlayerView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI
import AVKit
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "SystemPlayerView")

public struct CustomPlayerView<C>: View where C: View {
#if os(tvOS)
    enum PlayerFocusState {
        case player
        case controls
    }
    @FocusState private var focusState: PlayerFocusState?
    @Namespace private var focusNamespace
#endif
    
    @Environment(\.playerModel) private var playerModel
    @ViewBuilder var controls: (_ playerModel: PlayerModel) -> C
    @State private var isShowingControls: Bool = false
    @State private var accumulateTimer: AccumulateTimer = .init()
    var prepare: ((_ playerLayer: AVPlayerLayer) -> Void)?
    var onTimeChange: ((CMTime) -> Void)?
    
    public init(@ViewBuilder controls: @escaping (_ playerModel: PlayerModel) -> C,
                prepare: ((_ playerLayer: AVPlayerLayer) -> Void)? = nil,
                onTimeChange: ((CMTime) -> Void)? = nil) {
        self.controls = controls
        self.prepare = prepare
        self.onTimeChange = onTimeChange
    }
    
    public var body: some View {
        content
            .onReceive(playerModel.$currentTime, perform: { newValue in
                guard let newValue else { return }
                onTimeChange?(newValue)
            })
            .onChange(of: isShowingControls, perform: { newValue in
                if newValue { scheduleDismissControls() }
            })
    }
    
#if os(iOS)
    private var content: some View {
        ZStack {
            VideoRenderView(prepare: { prepare?($0) })
                .zIndex(0)
                .gesture(
                    TapGesture(count: 1)
                        .onEnded({ withAnimation { isShowingControls.toggle() }})
                )
            if isShowingControls {
                controls(playerModel)
                    .zIndex(1)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 10), value: isShowingControls)
                    .contentShape(Rectangle())
                    .interacting(onInteract: { scheduleDismissControls() })
            }
        }
    }
#elseif os(tvOS)
    private var content: some View {
        ZStack {
            Button(action: {
                withAnimation{ isShowingControls.toggle() }
                focusState = .controls
            }, label: {
                VideoRenderView()
            })
            .zIndex(0)
            .buttonStyle(.none)
            .focused($focusState, equals: .player)
            
            if isShowingControls {
                controls(playerModel)
                    .zIndex(1)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 10), value: isShowingControls)
                    .focused($focusState, equals: .controls)
                    .interacting(onInteract: { scheduleDismissControls() })
            }
        }
        .focusScope(focusNamespace)
    }
#endif
    
    private func scheduleDismissControls() {
        Task {
            await accumulateTimer.schedule(action: "dismissal", timeInterval: 10, perform: {
                Task { @MainActor in
                    withAnimation { isShowingControls = false }
                }
            })
        }
    }
}
