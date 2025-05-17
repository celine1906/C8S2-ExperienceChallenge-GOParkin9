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
    let description:String
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                Text(message)
                    .font(.headline)
            }
                
            Text(description)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
