//
//  File.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/30/24.
//

import SwiftUI

struct SafeAreaInsetsView: UIViewControllerRepresentable {
    var onInsetsChange: ((UIEdgeInsets) -> Void)
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            self.onInsetsChange(uiViewController.view.safeAreaInsets)
        }
    }
}
