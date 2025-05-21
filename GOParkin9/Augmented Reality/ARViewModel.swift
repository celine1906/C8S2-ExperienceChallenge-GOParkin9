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
import UIKit

enum ARState {
    case loading
    case loaded(ARView)
    case error
}

class ARViewModel: NSObject, ObservableObject, ARSessionDelegate {
    
    var modelContext: ModelContext?

    private var _showNotification: Binding<Bool> = .constant(false)

    init(context: ModelContext? = nil) {
        self.modelContext = context
        super.init()
    }

    func setShowNotificationBinding(_ binding: Binding<Bool>) {
        _showNotification = binding
    }

    var showNotification: Bool {
        get { _showNotification.wrappedValue }
        set { _showNotification.wrappedValue = newValue }
    }

    @Published var state: ARState = .loading
    @Published var modelName: String = "arrow"
    
    private var lastUserPosition: SIMD3<Float>?
    private let thresholdDistance: Float = 2.0
    var hasShownPinpoint = false
    var hasShownNearNotification = false


    var arrowEntity: Entity?
    var arrowAnchor: AnchorEntity?
    
    var pinpointEntity: Entity?
    var pinpointAnchor: AnchorEntity?

    var arView: ARView?
    
    let navigationManager = NavigationManager()
    
    private var isUpdatingArrow = false
    
    func fetchDestinationAndBearing() async throws -> (Double, Double)? {
        guard let context = modelContext else {
            print("❌ Tidak ada modelContext!")
            return nil
        }

        let descriptor = FetchDescriptor<ParkingRecord>(
            predicate: #Predicate { $0.isHistory == false }
        )

        let records = try await MainActor.run {
            try context.fetch(descriptor)
        }

        guard let record = records.first else {
            print("⚠️ Tidak ada parking record aktif!")
            return nil
        }

        let destination = CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
        let distance = navigationManager.distance(to: destination)
        let bearing = navigationManager.angle(to: destination)

        return (distance, bearing)
    }
    
    func processUpdate(currentPosition: SIMD3<Float>, distance: Float) async {

        do {
            if let (distanceInMeter, bearing) = try await fetchDestinationAndBearing() {

                if distanceInMeter < 7  && !hasShownNearNotification {
                    hasShownNearNotification = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    // Show notification
                    await MainActor.run {
                        showNotification = true
                    }

                    // Tahan notif selama 3 detik
                    try? await Task.sleep(nanoseconds: 5_000_000_000)

                    await MainActor.run {
                        showNotification = false
                    }
                }

                if distance >= thresholdDistance && !isUpdatingArrow {
                    isUpdatingArrow = true
                    lastUserPosition = currentPosition

                    print("📌 Last position updated: \(String(describing: lastUserPosition))")

                    await updateArrow(bearing: bearing, at: currentPosition)

                    isUpdatingArrow = false
                }
            }
        } catch {
            print("❌ Error fetch parkingRecords: \(error)")
        }
    }
    
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Salin nilai transform ke variabel lokal → HINDARI bawa frame ke dalam Task
        let cameraTransform = frame.camera.transform
        let currentPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        // Hitung jarak
        let distance: Float
        if let last = lastUserPosition {
            distance = simd_distance(
                SIMD2<Float>(currentPosition.x, currentPosition.z),
                SIMD2<Float>(last.x, last.z)
            )
        } else {
            lastUserPosition = currentPosition
            return
        }

        print("LAST POSITION: \(String(describing: lastUserPosition)), CURRENT POSITION: \(currentPosition), DISTANCE: \(distance)")

        // Jalankan task async dengan data yang aman (bukan frame langsung)
        Task {
            await self.processUpdate(currentPosition: currentPosition, distance: distance)
        }
    }


    // Load ARView and prepare the AR session
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
    
 
//     Update arrow direction and display in AR view
        func updateArrow(bearing: Double, at position: SIMD3<Float>) async {
            guard let arView = arView,
                  let arrowEntity = arrowEntity,
                  let cameraTransform = await arView.session.currentFrame?.camera.transform,
                  let pinpointAnchor = pinpointAnchor else { return }

            await MainActor.run {
                // Hapus anchor sebelumnya
                if let existingAnchor = arrowAnchor {
                    arView.scene.removeAnchor(existingAnchor)
                }
                
                // Buat clone dari entity
                let arrowClone = arrowEntity.clone(recursive: true)
                
                // Hitung posisi di depan kamera (misalnya 1 meter)
                let forward = SIMD3<Float>(-cameraTransform.columns.2.x,
                                           -cameraTransform.columns.2.y,
                                           -cameraTransform.columns.2.z)
                let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                                  cameraTransform.columns.3.y,
                                                  cameraTransform.columns.3.z)
//                let arrowPosition = cameraPosition + normalize(forward) * 1.0
                
                // Posisi target (pinpoint) dan posisi user (current camera position)
                let targetPosition = pinpointAnchor.position(relativeTo: nil)
                let userToTarget = normalize(targetPosition - position)

                // Hitung rotasi dari vektor userToTarget
                let angle = atan2(userToTarget.x, userToTarget.z) // arah horizontal (XZ)
                let correctedAngle = angle - .pi / 2
                let rotation = simd_quatf(angle: correctedAngle, axis: [0, 1, 0])

                // Posisi panah 1 meter di depan kamera
                let arrowPosition = cameraPosition + normalize(forward) * 1.0
                let anchor = AnchorEntity(world: arrowPosition)

                arrowClone.transform.rotation = rotation
                anchor.addChild(arrowClone)
                arView.scene.anchors.append(anchor)
            
                
                // Simpan referensi anchor terakhir
                arrowAnchor = anchor
                print("🎯 Arrow added at world position: \(anchor.transform.translation)")
                print("🛠 Added arrow to scene at anchor position: \(anchor.transform.matrix.columns.3)")
            }
        }
    
    func showPinpoint(bearing: Double, distance: Double, userPosition: SIMD3<Float>) async {
        guard let arView = arView else { return }

        await MainActor.run {
            // Hapus anchor sebelumnya
            if let existingAnchor = pinpointAnchor {
                arView.scene.removeAnchor(existingAnchor)
            }

            // Load pinpoint model (pastikan model ada di project)
            guard let pinpoint = try? Entity.loadModel(named: "pointer") else { return }

            // Hitung rotasi berdasarkan bearing
            let yawInRadians = Float(bearing * .pi / 180)
            let rotation = simd_quatf(angle: yawInRadians, axis: [0, 1, 0])
            
            // Hitung posisi offset dengan arah bearing
            let direction = simd_float3(-sin(yawInRadians), 0, -cos(yawInRadians)) // arah bearing ke depan
            let offset = direction * Float(distance)

            let pinpointPosition = userPosition + offset
            
            let anchor = AnchorEntity(world: pinpointPosition)

            // Set rotasi pinpoint supaya menghadap user / arah yang diinginkan (optional)
            pinpoint.transform.rotation = rotation
            pinpoint.transform.scale = SIMD3<Float>(repeating: 0.003)
            
            anchor.addChild(pinpoint)
            arView.scene.anchors.append(anchor)

            // Simpan referensi
            self.pinpointEntity = pinpoint
            self.pinpointAnchor = anchor

            print("📍 Pinpoint added at: \(pinpointPosition), bearing: \(bearing)°")
        }
    }
}
