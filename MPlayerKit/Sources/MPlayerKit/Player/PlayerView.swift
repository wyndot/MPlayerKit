//
//  PlayerView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI

public enum PlayerControlsStyle {
    case system
    case custom
}

public struct PlayerView: View {
    let controlsStyle: PlayerControlsStyle
    
    public init(controlsStyle: PlayerControlsStyle = .system) {
        self.controlsStyle = controlsStyle
    }
    
    public var body: some View {
        if controlsStyle == .custom {
            CustomPlayerView(controls: { _ in
                CustomControlsView()
            })
        } else {
            SystemPlayerView()            
        }
    }
}
