//
//  CustomPlayerView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI

struct CustomPlayerView<C>: View where C: View {
    @Environment(\.playerModel) private var playerModel
    @ViewBuilder var controls: (_ playerModel: PlayerModel) -> C
    
    var body: some View {
        ZStack {
            VideoRenderView(player: playerModel.player)
            if playerModel.presentation != .none {
                controls(playerModel)                
            }
        }
    }
}
