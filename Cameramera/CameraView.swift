//
//  CameraView.swift
//  Cameramera
//
//  Created by Antoine Bollengier on 23.11.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    typealias UIViewControllerType = CameraViewController
}
