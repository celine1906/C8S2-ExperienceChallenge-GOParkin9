//
//  ARCameraView.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 09/05/25.
//

import SwiftUI
import SwiftData
import CoreLocation

struct ARCameraView: View {
    @Environment(\.modelContext) var context
    @StateObject private var viewModel: ARViewModel
    @StateObject var navigationManager = NavigationManager()
    @Query(filter: #Predicate<ParkingRecord> { $0.isHistory == false }) var parkingRecords: [ParkingRecord]
    
    @State var showNotification = false
    
    init() {
        _viewModel = StateObject(wrappedValue: ARViewModel())
    }

    
    @State var isVisible = false

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading AR View...")

            case .loaded(let arView):
//                ARLoadingOverlayView(isVisible: $isVisible)
                ARViewContainer(arView: arView)
                    .edgesIgnoringSafeArea(.all)
                TopNotificationView(message: "You’re here! Your parking spot is nearby.", isShowing: $showNotification)
                        .zIndex(10)
                ARModalView().environment(\.modelContext, context)
                    .edgesIgnoringSafeArea(.all)
                if isVisible {
                    ARLoadingOverlayView(isVisible: $isVisible)
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(2)
                }
            case .error:
                VStack {
                    Text("Failed to load AR content.")
                        .foregroundColor(.red)
                    Button("Retry") {
                        viewModel.loadARView()
                    }
                }
            }
            
            
        }
        .onAppear {
            viewModel.modelContext = context
            viewModel.setShowNotificationBinding($showNotification)
            viewModel.loadARView()

            
            isVisible = true
            Task {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                await MainActor.run {
                    withAnimation {
                        isVisible = false
                    }
                }

            }

            // Tunda pemanggilan updateArrow sampai ARView selesai dimuat
            Task {
                // Tunggu hingga ARView selesai dimuat
                while case .loading = viewModel.state {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
                
                do {
                   // Ambil data tujuan dan bearing
                   if let (distanceInMeter, bearing) = try await viewModel.fetchDestinationAndBearing(),
                      let currentPosition = await viewModel.arView?.cameraTransform.translation {
                       
                       // 1. Tampilkan pinpoint di posisi tujuan
                       await viewModel.showPinpoint(bearing: bearing, distance: distanceInMeter, userPosition: currentPosition)
                       viewModel.hasShownPinpoint = true

                       // 2. Update panah dengan bearing yang sama dari pinpoint
                       await viewModel.updateArrow(bearing: bearing, at: currentPosition)
                   }

               } catch {
                   print("❌ Gagal memuat pinpoint dan update arrow: \(error)")
               }
                
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

