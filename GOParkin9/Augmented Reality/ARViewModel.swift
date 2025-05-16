//
//  ARViewModel.swift
//  GOParkin9
//
//  Created by Regina Celine Adiwinata on 09/05/25.
//

import Foundation
import ARKit
import RealityKit
import Combine
import SwiftData
import CoreLocation
import SwiftUI

enum ARState {
    case loading
    case loaded(ARView)
    case error
}

class ARViewModel: NSObject, ObservableObject, ARSessionDelegate {
    
    var modelContext: ModelContext?

    init(context: ModelContext? = nil) {
        self.modelContext = context
    }
    
    
    @Published var state: ARState = .loading
    @Published var modelName: String = "arrow"
    
    private var lastUserPosition: SIMD3<Float>?
    private let thresholdDistance: Float = 2.0

    var arrowEntity: Entity?
    var arrowAnchor: AnchorEntity?
    var arView: ARView?
    
    let navigationManager = NavigationManager()
    
//    @Query(filter: #Predicate<ParkingRecord> { $0.isHistory == false }) var parkingRecords: [ParkingRecord]
    
    private var isUpdatingArrow = false
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let cameraTransform = frame.camera.transform
        let currentPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        print("POSITION: \(currentPosition)")

        // Jika belum ada posisi sebelumnya, simpan
        guard let last = lastUserPosition else {
            lastUserPosition = currentPosition
            return
        }
        
        let distance = simd_distance(
            SIMD2<Float>(currentPosition.x, currentPosition.z),
            SIMD2<Float>(last.x, last.z)
        )


//        let distance = simd_distance(currentPosition, last)
        
        print("POSITION: \(distance)")

        // Jika sudah menempuh lebih dari 2 meter
        if distance >= thresholdDistance && !isUpdatingArrow {
            isUpdatingArrow = true
            lastUserPosition = currentPosition
                
            print("Last position: \(String(describing: lastUserPosition))")
            
            Task {
                do {
                    guard let context = modelContext else {
                        print("❌ Tidak ada modelContext!")
                        isUpdatingArrow = false
                        return
                    }

                    let descriptor = FetchDescriptor<ParkingRecord>(
                        predicate: #Predicate { $0.isHistory == false }
                    )

                    let records = try await MainActor.run {
                        try context.fetch(descriptor)
                    }
                    guard let record = records.first else {
                        print("⚠️ Tidak ada parking record aktif!")
                        isUpdatingArrow = false
                        return
                    }

                    let destination = CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
                    let bearing = navigationManager.angle(to: destination)

                    print("⬇️ Updating arrow at \(currentPosition), bearing: \(bearing)")
                    await updateArrow(bearing: bearing, at: currentPosition)
                    print("⬇️ Updating arrow at \(currentPosition), bearing: \(bearing)")

                } catch {
                    print("❌ Error fetch parkingRecords: \(error)")
                }

                isUpdatingArrow = false
            }

        }
    }


    /// Load ARView and prepare the AR session
    func loadARView() {
        state = .loading

        Task { [weak self] in
            guard let self else { return }

            do {
                let arView = await ARView(frame: .zero)
                let config = ARWorldTrackingConfiguration()
                config.planeDetection = [.horizontal, .vertical]
                config.environmentTexturing = .automatic
                await arView.session.run(config)

                // Simpan arView
                self.arView = arView
                await self.arView?.session.delegate = self


                // Load arrow entity hanya sekali
                self.arrowEntity = try await Entity.init(named: modelName)
                print("✅ Arrow entity loaded successfully")

                await MainActor.run {
                    self.state = .loaded(arView)
                }

            } catch {
                await MainActor.run {
                    self.state = .error
                }
            }
        }
    }

    // Update arrow direction and display in AR view
        func updateArrow(bearing: Double, at position: SIMD3<Float>) async {
            guard let arView = arView,
                  let arrowEntity = arrowEntity else { return }

            await MainActor.run {
                // Hapus anchor sebelumnya
                if let existingAnchor = arrowAnchor {
                    arView.scene.removeAnchor(existingAnchor)
                }
                
                // Buat anchor baru
                let arrowClone = arrowEntity.clone(recursive: true)
                let anchor = AnchorEntity(world: SIMD3<Float>(position.x, position.y, position.z-1))
                
                // Arahkan panah berdasarkan bearing
                let yawInRadians = Float(bearing * .pi / 180)
                
                let forward = normalize(SIMD3<Float>(
                    -sin(yawInRadians),
                    0,
                    -cos(yawInRadians)
                ))
                
                let rotation = simd_quatf(angle: yawInRadians, axis: [0, 1, 0])
  
                arrowClone.transform.rotation = rotation
                arrowClone.transform.translation = SIMD3<Float>(0, 0, -1)

                
                // Tambahkan ke anchor dan scene
                anchor.addChild(arrowClone)
                arView.scene.anchors.append(anchor)
               

                
                // Simpan referensi anchor terakhir
                arrowAnchor = anchor
                print("🎯 Arrow added at world position: \(anchor.transform.translation)")
                print("🛠 Added arrow to scene at anchor position: \(anchor.transform.matrix.columns.3)")
            }
        }
    }
