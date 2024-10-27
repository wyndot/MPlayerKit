//
//  Icon.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/24/24.
//

import SwiftUI


struct InteactingViewModifier: ViewModifier {
    var onInteract: () -> Void?
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(TapGesture().onEnded({ onInteract() }))
#if os(iOS)
            .simultaneousGesture(DragGesture().onChanged( { _ in  onInteract() }))
#elseif os(tvOS)
            .remoteTouch(RemoteTouch(onChanged: { _ in
                onInteract()
            }, onEnded: { onInteract() }))
            .onMoveCommand(perform: { _ in onInteract() })
#endif
    }
}

extension View {
    func interacting(onInteract: @escaping () -> Void ) -> some View {
        modifier(InteactingViewModifier(onInteract: onInteract))
    }
}
