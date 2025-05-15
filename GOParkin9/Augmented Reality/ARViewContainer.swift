//
//  ARViewContainer.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 13/05/25.
//

import SwiftUI
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    let arView: ARView

    func makeUIView(context: Context) -> ARView {
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Optional: update if needed
    }
}
