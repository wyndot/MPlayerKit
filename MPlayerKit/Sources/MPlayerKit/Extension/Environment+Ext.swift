//
//  File.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI
import AVKit
import UIKit

public struct PlayerModelKey: @preconcurrency EnvironmentKey {
    @MainActor public static let defaultValue: PlayerModel = PlayerModel()
}

public struct PlayerPreviewModelKey: @preconcurrency EnvironmentKey {
    @MainActor public static let defaultValue: PlayerPreviewModel = PlayerPreviewModel()
}

public extension EnvironmentValues {
    var playerModel: PlayerModel {
        get {
            return self[PlayerModelKey.self]
        }
        set {
            self[PlayerModelKey.self] = newValue
        }
    }
    var playerPreviewModel: PlayerPreviewModel {
        get {
            return self[PlayerPreviewModelKey.self]
        }
        set {
            self[PlayerPreviewModelKey.self] = newValue
        }
    }
}

public struct SafeAreaInsetsKey: @preconcurrency EnvironmentKey {
    @MainActor public static var defaultValue: UIEdgeInsets {
        UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero
    }
}

public extension EnvironmentValues {
    @MainActor var safeAreaInsets: UIEdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}
