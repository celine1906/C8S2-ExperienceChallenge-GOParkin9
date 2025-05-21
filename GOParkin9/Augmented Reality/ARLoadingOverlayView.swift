//
//  ARLoadingOverlayView.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 18/05/25.
//

import SwiftUI

struct ARLoadingOverlayView: View {
    @Binding var isVisible: Bool
    @State private var rotation: Double = 0

    var body: some View {
        if isVisible {
            ZStack {
                // Kamera tetap kelihatan di bawahnya (karena overlay)

                Color.black.opacity(0.4) // Transparan agar kamera tetap kelihatan

                VStack(spacing: 20) {
                
                    Image(systemName: "arkit")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                        .rotationEffect(Angle(degrees: rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                    
                    Text("Point your camera around")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    
                }
                .padding()
            }
            .ignoresSafeArea()
            .transition(.opacity)
        }
    }
}
