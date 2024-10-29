//
//  CustomPlayerView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "SystemPlayerView")

struct CustomPlayerView<C>: View where C: View {
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
    
    var body: some View {
        content
            .onChange(of: isShowingControls, perform: { newValue in
                if newValue { scheduleDismissControls() }
            })
    }
    
#if os(iOS)
    private var content: some View {
        ZStack {
            VideoRenderView()
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
                VideoRenderView(player: playerModel.player)
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
