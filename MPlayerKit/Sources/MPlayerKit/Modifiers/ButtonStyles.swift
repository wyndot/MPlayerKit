//
//  ButtonStyles.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI

enum IconButtonSize {
    case small
    case medium
    case large
    
    func points() -> CGFloat {
        #if os(iOS)
        switch self {
            case .small:
                return 50
            case .medium:
                return 70
            case .large:
                return 80
        }
        #else
        switch self {
            case .small:
                return 80
            case .medium:
                return 100
            case .large:
                return 120
        }
        #endif
    }
}

struct IconButtonStyle: ButtonStyle {
#if os(tvOS)
    @Environment(\.isFocused) private var isFocused
#endif
    let size: IconButtonSize
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .padding()
        #if os(iOS)
            .foregroundColor(configuration.isPressed ? .accentColor.opacity(0.8) : .accentColor)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
        #elseif os(tvOS)
            .foregroundColor(isFocused ? .accentColor : .primary)
            .scaleEffect(configuration.isPressed ? 0.9 :  isFocused ? 1.1 : 1)
        #endif
            .frame(width: size.points(), height: size.points())
    }

}

extension ButtonStyle where Self == IconButtonStyle {
    static var largeIcon: IconButtonStyle { .init(size: .large) }
    static var mediumIcon: IconButtonStyle { .init(size: .medium) }
    static var smallIcon: IconButtonStyle { .init(size: .small) }
}

struct NoneButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == NoneButtonStyle {
    static var none: NoneButtonStyle { .init() }
}
