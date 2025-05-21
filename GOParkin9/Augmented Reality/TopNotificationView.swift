//
//  TopNotificationView.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 18/05/25.
//

import SwiftUI
import AudioToolbox

struct TopNotificationView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            if isShowing {
                Text(message)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.secondary3)
                    .clipShape(RoundedCorner(radius: 10, corners: .allCorners))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: isShowing)
                    .onChange(of: isShowing) { newValue in
                        if newValue {
                            playTingSound()
                        }
                    }
            }
            Spacer()
        }
        .padding()
    }
    
    func playTingSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1057)) // suara "ting"
    }
}
