//
//  AirPlayPickerView.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/28/24.
//
import SwiftUI
import AVKit

public struct AirPlayPickerView: UIViewRepresentable {
    public func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.activeTintColor = UIColor(named: "AccentColor")
        routePickerView.prioritizesVideoDevices = true
        return routePickerView
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) { }
}
