//
//  GOParkin9App.swift
//  GOParkin9
//
//  Created by Rico Tandrio on 20/03/25.
//

import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

@main
struct GOParkin9App: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var isSplashActive = true
    @AppStorage("openWelcomeView") var openWelcomeView: Bool = true
    @AppStorage("navigateToAR") var navigateToAR: Bool = false
    
    init() {
        UserDefaults.standard.set(false, forKey: "navigateToAR")
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ParkingRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isSplashActive {
                    SplashScreenView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    isSplashActive = false
                                }
                            }
                        }
                } else if navigateToAR {
                    NavigationStack {
                        ARCameraView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        navigateToAR = false
                                    } label: {
                                        HStack {
                                            Image(systemName: "chevron.backward")
                                            Text("Home")
                                        }
                                    }

                                }
                            }
                    }

                } else {
                    ContentView()
                        .fullScreenCover(isPresented: $openWelcomeView) {
                            WelcomeScreenView()
                        }
                }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}

