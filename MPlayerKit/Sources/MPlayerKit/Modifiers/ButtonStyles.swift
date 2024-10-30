//
//  ButtonStyles.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI

enum IconButtonSize {
    case xsmall
    case small
    case medium
    case large
    
    func points() -> CGFloat {
        #if os(iOS)
        switch self {
            case .xsmall:
                30
            case .small:
                40
            case .medium:
                50
            case .large:
                60
        }
        #else
        switch self {
            case .xsmall:
                60
            case .small:
                80
            case .medium:
                90
            case .large:
                160
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
            .padding(5)
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
    static var xsmallIcon: IconButtonStyle { .init(size: .xsmall) }
}

struct NoneButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == NoneButtonStyle {
    static var none: NoneButtonStyle { .init() }
}

struct SquareButtonStyle: ButtonStyle {
#if os(tvOS)
    @Environment(\.isFocused) private var isFocused
#endif
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
#if os(tvOS)
            isFocused ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4)
#endif
            configuration.label
                .padding(padding)
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
        }
        .cornerRadius(12)
#if os(tvOS)
        .scaleEffect(isFocused ? 1.3 : 1.0)
#endif
        
    }
    
    var padding: CGFloat {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 20
        } else {
            return 10
        }
#elseif os(tvOS)
        20
#endif
    }
}

extension ButtonStyle where Self == SquareButtonStyle {
    static var square: SquareButtonStyle {
        SquareButtonStyle()
    }
}


struct RoundButtonStyle: ButtonStyle {
#if os(tvOS)
    @Environment(\.isFocused) private var isFocused
#endif
    let padding: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
#if os(tvOS)
            Circle().fill(isFocused ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4))
#endif
            configuration.label
                .padding(padding)
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
        }
#if os(tvOS)
        .scaleEffect(isFocused ? 1.3 : 1.0)
#endif
    }
}

extension ButtonStyle where Self == RoundButtonStyle {
    static func round(padding: CGFloat) -> RoundButtonStyle {
        RoundButtonStyle(padding: padding)
    }
}


struct PiPButtonStyle: ButtonStyle {
#if os(tvOS)
    @Environment(\.isFocused) private var isFocused
#endif
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
#if os(tvOS)
            isFocused ? Color.white : Color(red: 0.4, green: 0.4, blue: 0.4)
#endif
            configuration.label
                .padding(padding)
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
            #if os(tvOS)
                .foregroundStyle(isFocused ? Color.black : Color("AccentColor"))
            #else
                .foregroundStyle(Color("AccentColor"))
            #endif
        }
        .cornerRadius(12)
#if os(tvOS)
        .scaleEffect(isFocused ? 1.3 : 1.0)
#endif
        
    }
    
    var padding: CGFloat {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 20
        } else {
            return 10
        }
#elseif os(tvOS)
        20
#endif
    }
}

extension ButtonStyle where Self == PiPButtonStyle {
    static var pip: PiPButtonStyle {
        PiPButtonStyle()
    }
}
