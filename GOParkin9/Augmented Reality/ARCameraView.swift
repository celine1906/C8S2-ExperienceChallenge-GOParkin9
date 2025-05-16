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
    
    init() {
        _viewModel = StateObject(wrappedValue: ARViewModel())
    }
    
//    @StateObject private var viewModelModal = ARModalViewModel()

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading AR View...")

            case .loaded(let arView):
                ARViewContainer(arView: arView)
                    .edgesIgnoringSafeArea(.all)
                ARModalView().environment(\.modelContext, context)
                    .edgesIgnoringSafeArea(.all)
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
            viewModel.loadARView()

            // Tunda pemanggilan updateArrow sampai ARView selesai dimuat
            Task {
                // Tunggu hingga ARView selesai dimuat
                while case .loading = viewModel.state {
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 detik
                }
                
                if let record = parkingRecords.first {
                    let destination = CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
                    let bearing = navigationManager.angle(to: destination)
                    await viewModel.updateArrow(bearing: bearing, at: SIMD3<Float>(0, 0, 0))
                }
                
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

