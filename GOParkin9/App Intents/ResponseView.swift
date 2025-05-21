//
//  ResponseView.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 17/05/25.
//

import SwiftUI
import SwiftData

struct ResponseView: View {
    let icon:String
    let message:String
    let description:String?
    let color:Color
    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: icon)
                .font(.system(size: 100))
                .foregroundStyle(color)
            Text(message)
                .font(.headline)
                
            if let descriptionNotNil = description {
                Text(descriptionNotNil)
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
