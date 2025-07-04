//
//  HomeView.swift
//  GOParkin9
//
//  Created by Rico Tandrio on 21/03/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showAlert = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    NavigationList()

                    DetailRecord()

                }
                .navigationTitle("Home")
                .padding()
            }
        }            
    }
}

#Preview {
    ContentView()
}
