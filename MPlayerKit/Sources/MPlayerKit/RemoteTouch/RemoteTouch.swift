//
//  RemoteTouch.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/25/24.
//
import SwiftUI
import GameController
import os

#if os(tvOS)
public struct RemoteTouchModifier: ViewModifier {
    @Environment(\.isFocused) private var isFocused
    @StateObject private var session = RemoteTouchSession()
    @State var remoteTouch: RemoteTouch
    init(_ remoteTouch: RemoteTouch) {
        self.remoteTouch = remoteTouch
    }
    
    public func body(content: Content) -> some View {
        content
            .onReceive(session.$delta.dropFirst().throttle(for: 0.02, scheduler: RunLoop.main, latest: true)) { value in
                remoteTouch.onChanged?(value)
            }
            .onChange(of: isFocused) { isFocused in
                if isFocused {
                    session.attach()
                } else {
                    session.detach()
                    remoteTouch.onEnded?()
                }
            }
    }
}

public struct RemoteTouch {
    var onChanged: ((CGPoint) -> Void)?
    var onEnded: (() -> Void)?
}

extension View {
    func remoteTouch(_ touch: RemoteTouch) -> some View {
        modifier(RemoteTouchModifier(touch))
    }
}

@MainActor
fileprivate class RemoteTouchSession: ObservableObject {
    @Published var delta: CGPoint = .zero
    var isInteracting = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(connected(notification:)), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnected(notification:)), name: .GCControllerDidDisconnect, object: nil)
    }
    
    func attach() {
        GCController.startWirelessControllerDiscovery()
        for controller in GCController.controllers() {
            attach(controller)
        }
    }
    
    func detach() {
        for controller in GCController.controllers() {
            detach(controller)
        }
    }
    
    @objc func connected(notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        attach(controller)
    }
    
    @objc func disconnected(notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        detach(controller)
    }
    
    private func attach(_ controller: GCController) {
        if let microGamepad = controller.microGamepad {
            microGamepad.dpad.valueChangedHandler = { [weak self] dpad, xValue, yValue in
                guard let self else { return }
                self.isInteracting = true
                defer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.isInteracting = false
                    }
                }
                guard xValue != 0, yValue != 0 else { return }
                delta = CGPoint(x: CGFloat(xValue), y: CGFloat(yValue))
            }
        }
    }
    
    private func detach(_ controller: GCController) {
        if let microGamepad = controller.microGamepad {
            microGamepad.dpad.valueChangedHandler = nil
        }
    }
}
#endif